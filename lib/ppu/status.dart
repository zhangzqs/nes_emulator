import 'package:nes_emulator/util.dart';

enum StatusFlag {
  unused_1,
  unused_2,
  unused_3,
  unused_4,
  unused_5,
  spriteOverflow,
  spriteZeroHit,
  verticalBlankStarted,
}

class StatusRegister {
  FlagBits<StatusFlag> bits = FlagBits(0);
  StatusRegister();
}
