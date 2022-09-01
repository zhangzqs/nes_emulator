import 'package:nes_emulator/common.dart';

import 'mapper.dart';

class Mapper2 extends Mapper {
  late int prgBanks;
  late int prgBank1;
  late int prgBank2;
  Mapper2(super.cartridge) {
    prgBanks = cartridge.prgBanks;
    prgBank1 = 0;
    prgBank2 = prgBanks - 1;
  }

  U8 read(U16 address) {
    if (address < 0x2000) return cartridge.chrRom[address];
    if (address >= 0xC000) return cartridge.prgRom[prgBank2 * 0x4000 + address - 0xC000];
    if (address >= 0x8000) return cartridge.prgRom[prgBank1 * 0x4000 + address - 0x8000];
    if (address >= 0x6000) {
      if (cartridge.hasBatteryBacked) {
        return cartridge.sRam[address - 0x6000];
      }
    }
    return 0;
  }

  void write(U16 address, U8 value) {
    if (address < 0x2000) {
      cartridge.chrRom[address] = value;
    }
    if (address >= 0x8000) {
      prgBank1 = value % prgBanks;
    }
    if (address >= 0x6000) {
      if (cartridge.hasBatteryBacked) {
        cartridge.sRam[address - 0x6000] = value;
      }
    }
  }

  @override
  U8 cpuMapRead(U16 address) => read(address);

  @override
  void cpuMapWrite(U16 address, U8 value) => write(address, value);

  @override
  U8 ppuMapRead(U16 address) => read(address);

  @override
  void ppuMapWrite(U16 address, U8 value) => write(address, value);
}
