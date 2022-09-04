part of 'apu.dart';

const noiseTable = [
  4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068, //
];

class Noise {
  bool enabled = false;
  bool mode = false;
  U16 shiftRegister = 0;
  bool lengthEnabled = false;
  U8 lengthValue = 0;
  U16 timerPeriod = 0;
  U16 timerValue = 0;
  bool envelopeEnabled = false;
  bool envelopeLoop = false;
  bool envelopeStart = false;
  U8 envelopePeriod = 0;
  U8 envelopeValue = 0;
  U8 envelopeVolume = 0;
  U8 constantVolume = 0;
  late Noise n = this;

  void writeControl(value) {
    n.lengthEnabled = (value >> 5) & 1 == 0;
    n.envelopeLoop = (value >> 5) & 1 == 1;
    n.envelopeEnabled = (value >> 4) & 1 == 0;
    n.envelopePeriod = value & 15;
    n.constantVolume = value & 15;
    n.envelopeStart = true;
  }

  void writePeriod(value) {
    n.mode = value & 0x80 == 0x80;
    n.timerPeriod = noiseTable[value & 0x0F];
  }

  void writeLength(value) {
    n.lengthValue = lengthTable[value >> 3];
    n.envelopeStart = true;
  }

  void stepTimer() {
    if (n.timerValue == 0) {
      n.timerValue = n.timerPeriod;
      U8 shift = 0;
      if (n.mode) {
        shift = 6;
      } else {
        shift = 1;
      }
      final b1 = n.shiftRegister & 1;
      final b2 = (n.shiftRegister >> shift) & 1;
      n.shiftRegister >>= 1;
      n.shiftRegister |= ((b1 ^ b2) << 14);
    } else {
      n.timerValue--;
    }
  }

  void stepEnvelope() {
    if (n.envelopeStart) {
      n.envelopeVolume = 15;
      n.envelopeValue = n.envelopePeriod;
      n.envelopeStart = false;
    } else if (n.envelopeValue > 0) {
      n.envelopeValue--;
    } else {
      if (n.envelopeVolume > 0) {
        n.envelopeVolume--;
      } else if (n.envelopeLoop) {
        n.envelopeVolume = 15;
      }
      n.envelopeValue = n.envelopePeriod;
    }
  }

  void stepLength() {
    if (n.lengthEnabled && n.lengthValue > 0) {
      n.lengthValue--;
    }
  }

  U8 output() {
    if (!n.enabled) {
      return 0;
    }
    if (n.lengthValue == 0) {
      return 0;
    }
    if (n.shiftRegister & 1 == 1) {
      return 0;
    }
    if (n.envelopeEnabled) {
      return n.envelopeVolume;
    } else {
      return n.constantVolume;
    }
  }
}
