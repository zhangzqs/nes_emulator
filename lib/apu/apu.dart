import '../common.dart';
import '../constants.dart';
import 'filter.dart';

part 'dmc.dart';
part 'noise.dart';
part 'pulse.dart';
part 'triangle.dart';

const lengthTable = [
  10, 254, 20, 2, 40, 4, 80, 6, 160, 8, 60, 10, 14, 12, 26, 14, //
  12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30, //
];

final pulseTable = List.generate(31, (i) => 95.52 / (8128.0 / i + 100));

final tndTable = List.generate(203, (i) => 163.67 / (24329.0 / i + 100));

const frameCounterRate = Constant.cpuFrequency / 240.0;

typedef F64 = double;
typedef F32 = double;

class ApuImpl {
  F64 sampleRate = 0;
  Pulse pulse1 = Pulse();
  Pulse pulse2 = Pulse();
  Triangle triangle = Triangle();
  Noise noise = Noise();
  DMC dmc = DMC();
  int cycle = 0;
  U8 framePeriod = 0;
  U8 frameValue = 0;
  bool frameIRQ = false;
  FilterChain filterChain = FilterChain();

  late ApuImpl apu = this;

  VoidCallback onIrqInterrupted;

  void Function(F32) onSample;
  ApuImpl({required this.onIrqInterrupted, required this.onSample}) {
    apu.noise.shiftRegister = 1;
    apu.pulse1.channel = 1;
    apu.pulse2.channel = 2;
  }

  void step() {
    final cycle1 = apu.cycle;
    apu.cycle++;
    final cycle2 = apu.cycle;
    apu.stepTimer();
    final int f1 = cycle1 ~/ frameCounterRate;
    final int f2 = cycle2 ~/ frameCounterRate;
    if (f1 != f2) {
      apu.stepFrameCounter();
    }
    final int s1 = cycle1 ~/ apu.sampleRate;
    final int s2 = cycle2 ~/ apu.sampleRate;
    if (s1 != s2) {
      apu.sendSample();
    }
  }

  void sendSample() {
    final output = apu.filterChain.step(apu.output());
    onSample(output);
  }

  F32 output() {
    final p1 = apu.pulse1.output();
    final p2 = apu.pulse2.output();
    final t = apu.triangle.output();
    final n = apu.noise.output();
    final d = apu.dmc.output();
    final pulseOut = pulseTable[p1 + p2];
    final tndOut = tndTable[3 * t + 2 * n + d];
    return pulseOut + tndOut;
  }

// mode 0:    mode 1:       function
// ---------  -----------  -----------------------------
//  - - - f    - - - - -    IRQ (if bit 6 is clear)
//  - l - l    l - l - -    Length counter and sweep
//  e e e e    e e e e -    Envelope and linear counter
  void stepFrameCounter() {
    void a() {
      apu.frameValue = (apu.frameValue + 1) % 4;
      switch (apu.frameValue) {
        case 0:
        case 2:
          apu.stepEnvelope();
          break;
        case 1:
          apu.stepEnvelope();
          apu.stepSweep();
          apu.stepLength();
          break;
        case 3:
          apu.stepEnvelope();
          apu.stepSweep();
          apu.stepLength();
          apu.fireIRQ();
          break;
      }
    }

    void b() {
      apu.frameValue = (apu.frameValue + 1) % 5;
      switch (apu.frameValue) {
        case 0:
        case 2:
          apu.stepEnvelope();
          break;
        case 1:
        case 3:
          apu.stepEnvelope();
          apu.stepSweep();
          apu.stepLength();
          break;
      }
    }

    switch (apu.framePeriod) {
      case 4:
        a();
        break;
      case 5:
        b();
        break;
    }
  }

  void stepTimer() {
    if (apu.cycle % 2 == 0) {
      apu.pulse1.stepTimer();
      apu.pulse2.stepTimer();
      apu.noise.stepTimer();
      apu.dmc.stepTimer();
    }
    apu.triangle.stepTimer();
  }

  void stepEnvelope() {
    apu.pulse1.stepEnvelope();
    apu.pulse2.stepEnvelope();
    apu.triangle.stepCounter();
    apu.noise.stepEnvelope();
  }

  void stepSweep() {
    apu.pulse1.stepSweep();
    apu.pulse2.stepSweep();
  }

  void stepLength() {
    apu.pulse1.stepLength();
    apu.pulse2.stepLength();
    apu.triangle.stepLength();
    apu.noise.stepLength();
  }

  void fireIRQ() {
    if (apu.frameIRQ) {
      onIrqInterrupted();
    }
  }

  U8 readStatus() {
    U8 result = 0;
    if (apu.pulse1.lengthValue > 0) {
      result |= 1;
    }
    if (apu.pulse2.lengthValue > 0) {
      result |= 2;
    }
    if (apu.triangle.lengthValue > 0) {
      result |= 4;
    }
    if (apu.noise.lengthValue > 0) {
      result |= 8;
    }
    if (apu.dmc.currentLength > 0) {
      result |= 16;
    }
    return result;
  }

  void writeControl(U8 value) {
    apu.pulse1.enabled = value & 1 == 1;
    apu.pulse2.enabled = value & 2 == 2;
    apu.triangle.enabled = value & 4 == 4;
    apu.noise.enabled = value & 8 == 8;
    apu.dmc.enabled = value & 16 == 16;
    if (!apu.pulse1.enabled) {
      apu.pulse1.lengthValue = 0;
    }
    if (!apu.pulse2.enabled) {
      apu.pulse2.lengthValue = 0;
    }
    if (!apu.triangle.enabled) {
      apu.triangle.lengthValue = 0;
    }
    if (!apu.noise.enabled) {
      apu.noise.lengthValue = 0;
    }
    if (!apu.dmc.enabled) {
      apu.dmc.currentLength = 0;
    } else {
      if (apu.dmc.currentLength == 0) {
        apu.dmc.restart();
      }
    }
  }

  void writeFrameCounter(U8 value) {
    apu.framePeriod = 4 + (value >> 7) & 1;
    apu.frameIRQ = (value >> 6) & 1 == 0;
    // apu.frameValue = 0
    if (apu.framePeriod == 5) {
      apu.stepEnvelope();
      apu.stepSweep();
      apu.stepLength();
    }
  }
}
