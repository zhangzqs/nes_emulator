part of 'apu.dart';

const dmcTable = [
  214, 190, 170, 160, 143, 127, 113, 107, 95, 80, 71, 64, 53, 42, 36, 27, //
];

class DMC {
  bool enabled = false;
  U8 value = 0;
  U16 sampleAddress = 0;
  U16 sampleLength = 0;
  U16 currentAddress = 0;
  U16 currentLength = 0;
  U8 shiftRegister = 0;
  U8 bitCount = 0;
  U8 tickPeriod = 0;
  U8 tickValue = 0;
  bool loop = false;
  bool irq = false;

  late DMC d = this;

  void writeControl(U8 value) {
    d.irq = value & 0x80 == 0x80;
    d.loop = value & 0x40 == 0x40;
    d.tickPeriod = dmcTable[value & 0x0F];
  }

  void writeValue(U8 value) {
    d.value = value & 0x7F;
  }

  void writeAddress(U16 value) {
    // Sample address = %11AAAAAA.AA000000
    d.sampleAddress = 0xC000 | (value << 6);
  }

  void writeLength(U8 value) {
    // Sample length = %0000LLLL.LLLL0001
    d.sampleLength = (value << 4) | 1;
  }

  void restart() {
    d.currentAddress = d.sampleAddress;
    d.currentLength = d.sampleLength;
  }

  void stepTimer() {
    if (!d.enabled) {
      return;
    }
    d.stepReader();
    if (d.tickValue == 0) {
      d.tickValue = d.tickPeriod;
      d.stepShifter();
    } else {
      d.tickValue--;
    }
  }

  stepReader() {
    if (d.currentLength > 0 && d.bitCount == 0) {
      // TODO d.cpu.stall += 4;
      // TODO d.shiftRegister = d.cpu.Read(d.currentAddress);
      d.bitCount = 8;
      d.currentAddress++;
      if (d.currentAddress == 0) {
        d.currentAddress = 0x8000;
      }
      d.currentLength--;
      if (d.currentLength == 0 && d.loop) {
        d.restart();
      }
    }
  }

  stepShifter() {
    if (d.bitCount == 0) {
      return;
    }
    if (d.shiftRegister & 1 == 1) {
      if (d.value <= 125) {
        d.value += 2;
      }
    } else {
      if (d.value >= 2) {
        d.value -= 2;
      }
    }
    d.shiftRegister >>= 1;
    d.bitCount--;
  }

  U8 output() {
    return d.value;
  }
}
