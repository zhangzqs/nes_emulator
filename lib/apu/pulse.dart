part of 'apu.dart';

const dutyTable = [
  [0, 1, 0, 0, 0, 0, 0, 0],
  [0, 1, 1, 0, 0, 0, 0, 0],
  [0, 1, 1, 1, 1, 0, 0, 0],
  [1, 0, 0, 1, 1, 1, 1, 1],
];

class Pulse {
  bool enabled = false;
  U8 channel = 0;
  bool lengthEnabled = false;
  U8 lengthValue = 0;
  U16 timerPeriod = 0;
  U16 timerValue = 0;
  U8 dutyMode = 0;
  U8 dutyValue = 0;
  bool sweepReload = false;
  bool sweepEnabled = false;
  bool sweepNegate = false;
  U8 sweepShift = 0;
  U8 sweepPeriod = 0;
  U8 sweepValue = 0;
  bool envelopeEnabled = false;
  bool envelopeLoop = false;
  bool envelopeStart = false;
  U8 envelopePeriod = 0;
  U8 envelopeValue = 0;
  U8 envelopeVolume = 0;
  U8 constantVolume = 0;

  late Pulse p = this;

  writeControl(value) {
    p.dutyMode = (value >> 6) & 3;
    p.lengthEnabled = (value >> 5) & 1 == 0;
    p.envelopeLoop = (value >> 5) & 1 == 1;
    p.envelopeEnabled = (value >> 4) & 1 == 0;
    p.envelopePeriod = value & 15;
    p.constantVolume = value & 15;
    p.envelopeStart = true;
  }

  writeSweep(value) {
    p.sweepEnabled = (value >> 7) & 1 == 1;
    p.sweepPeriod = (value >> 4) & 7 + 1;
    p.sweepNegate = (value >> 3) & 1 == 1;
    p.sweepShift = value & 7;
    p.sweepReload = true;
  }

  writeTimerLow(U8 value) {
    p.timerPeriod = (p.timerPeriod & 0xFF00) | (value);
  }

  writeTimerHigh(U8 value) {
    p.lengthValue = lengthTable[value >> 3];
    p.timerPeriod = (p.timerPeriod & 0x00FF) | ((value & 7) << 8);
    p.envelopeStart = true;
    p.dutyValue = 0;
  }

  stepTimer() {
    if (p.timerValue == 0) {
      p.timerValue = p.timerPeriod;
      p.dutyValue = (p.dutyValue + 1) % 8;
    } else {
      p.timerValue--;
    }
  }

  stepEnvelope() {
    if (p.envelopeStart) {
      p.envelopeVolume = 15;
      p.envelopeValue = p.envelopePeriod;
      p.envelopeStart = false;
    } else if (p.envelopeValue > 0) {
      p.envelopeValue--;
    } else {
      if (p.envelopeVolume > 0) {
        p.envelopeVolume--;
      } else if (p.envelopeLoop) {
        p.envelopeVolume = 15;
      }
      p.envelopeValue = p.envelopePeriod;
    }
  }

  stepSweep() {
    if (p.sweepReload) {
      if (p.sweepEnabled && p.sweepValue == 0) {
        p.sweep();
      }
      p.sweepValue = p.sweepPeriod;
      p.sweepReload = false;
    } else if (p.sweepValue > 0) {
      p.sweepValue--;
    } else {
      if (p.sweepEnabled) {
        p.sweep();
      }
      p.sweepValue = p.sweepPeriod;
    }
  }

  stepLength() {
    if (p.lengthEnabled && p.lengthValue > 0) {
      p.lengthValue--;
    }
  }

  sweep() {
    final delta = p.timerPeriod >> p.sweepShift;
    if (p.sweepNegate) {
      p.timerPeriod -= delta;
      if (p.channel == 1) {
        p.timerPeriod--;
      }
    } else {
      p.timerPeriod += delta;
    }
  }

  output() {
    if (!p.enabled) {
      return 0;
    }
    if (p.lengthValue == 0) {
      return 0;
    }
    if (dutyTable[p.dutyMode][p.dutyValue] == 0) {
      return 0;
    }
    if (p.timerPeriod < 8 || p.timerPeriod > 0x7FF) {
      return 0;
    }
    // if !p.sweepNegate && p.timerPeriod+(p.timerPeriod>>p.sweepShift) > 0x7FF {
    // 	return 0
    // }
    if (p.envelopeEnabled) {
      return p.envelopeVolume;
    } else {
      return p.constantVolume;
    }
  }
}
