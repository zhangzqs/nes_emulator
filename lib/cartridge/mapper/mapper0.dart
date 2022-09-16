// NORM: https://wiki.nesdev.org/w/index.php?title=NROM
import 'package:nes_emulator/util.dart';

import '../../common.dart';
import 'mapper.dart';

class Mapper0 extends Mapper {
  Mapper0(super.cartridge);

  @override
  U8 cpuMapRead(U16 address) {
    // if PRGROM is 16KB
    //     CPU Address Bus          PRG ROM
    //     0x8000 -> 0xBFFF: Map    0x0000 -> 0x3FFF
    //     0xC000 -> 0xFFFF: Mirror 0x0000 -> 0x3FFF
    // if PRGROM is 32KB
    //     CPU Address Bus          PRG ROM
    //     0x8000 -> 0xFFFF: Map    0x0000 -> 0x7FFF

    if (address >= 0x8000 && address < 0xc000) {
      return cartridge.prgRom[address - 0x8000];
    }

    final prgBanks = cartridge.prgBanks;
    if (address >= 0xc000) {
      if (prgBanks == 1) {
        return cartridge.prgRom[address - 0xc000];
      }
      return cartridge.prgRom[address - 0x8000];
    }
    throw UnsupportedError('Mapper0 cannot read by cpu on address 0x${address.toHex()}');
  }

  @override
  void cpuMapWrite(U16 address, U8 value) {
    if (address >= 0x8000 && address < 0xc000) {
      cartridge.prgRom[address - 0x8000] = value;
      return;
    }

    final prgBanks = cartridge.prgBanks;
    if (address >= 0xc000) {
      if (prgBanks == 1) {
        cartridge.prgRom[address - 0xc000] = value;
        return;
      }
      cartridge.prgRom[address - 0x8000] = value;
      return;
    }
  }

  @override
  U8 ppuMapRead(U16 address) {
    if (address >= 0x0000 && address < 0x2000) {
      return cartridge.chrRom[address];
    }
    return 0;
  }

  @override
  void ppuMapWrite(U16 address, U8 value) {
    if (address >= 0x0000 && address < 0x2000) {
      if (cartridge.chrBanks == 0) {
        // Treat as RAM
        cartridge.chrRom[address] = value;
      }
    }
  }
}
