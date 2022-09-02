import '../common.dart';

abstract class IApu {
  // Pulse1 register
  void writeControlToPulse1(U8 value);
  void writeSweepToPulse1(U8 value);
  void writeTimerLowToPulse1(U8 value);
  void writeTimerHighToPulse1(U8 value);

  // Pulse2 register
  void writeControlToPulse2(U8 value);
  void writeSweepToPulse2(U8 value);
  void writeTimerLowToPulse2(U8 value);
  void writeTimerHighToPulse2(U8 value);

  // DMC register
  void writeControlToDmc(U8 value);
  void writeValueToDmc(U8 value);
  void writeAddressToDmc(U8 value);
  void writeLengthToDmc(U8 value);

  // Triangle register
  void writeControlToTriangle(U8 value);
  void writeTimerLowToTriangle(U8 value);
  void writeTimerHighToTriangle(U8 value);

  // Noise register
  void writeControlToNoise(U8 value);
  void writePeriodToNoise(U8 value);
  void writeLengthToNoise(U8 value);

  // Other register
  void writeControl(U8 value);
  void writeFrameCounter(U8 value);
  U8 readStatus();

  void clock();
}
