part of 'apu.dart';

const triangleTable = [
  15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, //
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, //
];

class Triangle {
  bool enabled = false;
  bool lengthEnabled = false;
  U8 lengthValue = 0;
  U16 timerPeriod = 0;
  U16 timerValue = 0;
  U8 dutyValue = 0;
  U8 counterPeriod = 0;
  U8 counterValue = 0;
  bool counterReload = false;

  late Triangle t = this;

  void writeControl(value) {
    t.lengthEnabled = (value >> 7) & 1 == 0;
    t.counterPeriod = value & 0x7F;
  }

  void writeTimerLow(value) {
    t.timerPeriod = (t.timerPeriod & 0xFF00) | value;
  }

  void writeTimerHigh(value) {
    t.lengthValue = lengthTable[value >> 3];
    t.timerPeriod = (t.timerPeriod & 0x00FF) | ((value & 7) << 8);
    t.timerValue = t.timerPeriod;
    t.counterReload = true;
  }

  void stepTimer() {
    if (t.timerValue == 0) {
      t.timerValue = t.timerPeriod;
      if (t.lengthValue > 0 && t.counterValue > 0) {
        t.dutyValue = (t.dutyValue + 1) % 32;
      }
    } else {
      t.timerValue--;
    }
  }

  void stepLength() {
    if (t.lengthEnabled && t.lengthValue > 0) {
      t.lengthValue--;
    }
  }

  void stepCounter() {
    if (t.counterReload) {
      t.counterValue = t.counterPeriod;
    } else if (t.counterValue > 0) {
      t.counterValue--;
    }
    if (t.lengthEnabled) {
      t.counterReload = false;
    }
  }

  U8 output() {
    if (!t.enabled) {
      return 0;
    }
    if (t.timerPeriod < 3) {
      return 0;
    }
    if (t.lengthValue == 0) {
      return 0;
    }
    if (t.counterValue == 0) {
      return 0;
    }
    return triangleTable[t.dutyValue];
  }
}
