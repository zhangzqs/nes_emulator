import 'package:nes_emulator/common.dart';
import 'package:nes_emulator/util.dart';

enum ControlFlag {
  nameTable1, // 0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00
  nameTable2,
  videoRamAddressIncrement, // 0: add 1, going across; 1: add 32, going down
  spritePatternAddress, // 0: $0000; 1: $1000; ignored in 8x16 mode
  backgroundPatternAddress, // 0: $0000; 1: $1000
  spriteSize, // 0: 8x8 pixels; 1: 8x16 pixels
  masterSlaveSelect, // 0: read backdrop from EXT pins; 1: output color on EXT pins
  generateVBlankNmi, // 1bit, 0: 0ff, 1: on
}

class ControlRegister {
  FlagBits<ControlFlag> bits = FlagBits(0);
  ControlRegister();

  U16 get nameTableAddress {
    final nameTable = bits[ControlFlag.nameTable2].asInt() << 1 | bits[ControlFlag.nameTable1].asInt();
    return const [0x2000, 0x2400, 0x2800, 0x2c00][nameTable];
  }

  U8 get videoRamAddressIncrement => bits[ControlFlag.videoRamAddressIncrement] ? 32 : 1;

  U16 get spritePatternAddress => bits[ControlFlag.spritePatternAddress] ? 0x1000 : 0;

  U16 get backgroundPatternAddress => bits[ControlFlag.backgroundPatternAddress] ? 0x1000 : 0;

  U8 get spriteSize => bits[ControlFlag.spriteSize] ? 16 : 8;

  bool get masterSlaveSelect => bits[ControlFlag.masterSlaveSelect];

  bool get generateVBlankNmi => bits[ControlFlag.generateVBlankNmi];
}
