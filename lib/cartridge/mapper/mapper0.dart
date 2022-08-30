// NORM: https://wiki.nesdev.org/w/index.php?title=NROM
import 'package:nes_emulator/util.dart';

import '../../common.dart';
import 'mapper.dart';

class Mapper0 extends Mapper {
  Mapper0(super.prgBanks, super.chrBanks);

  @override
  int cpuMapRead(U16 address) {
    // if PRGROM is 16KB
    //     CPU Address Bus          PRG ROM
    //     0x8000 -> 0xBFFF: Map    0x0000 -> 0x3FFF
    //     0xC000 -> 0xFFFF: Mirror 0x0000 -> 0x3FFF
    // if PRGROM is 32KB
    //     CPU Address Bus          PRG ROM
    //     0x8000 -> 0xFFFF: Map    0x0000 -> 0x7FFF

    if (address >= 0x8000 && address < 0xc000) {
      return address - 0x8000;
    }

    if (address >= 0xc000) {
      if (prgBanks == 1) {
        return address - 0xc000;
      }
      return address - 0x8000;
    }
    throw UnsupportedError('Mapper0 cannot read by cpu on address 0x${address.toHex()}');
  }

  @override
  int cpuMapWrite(U16 address) {
    return cpuMapRead(address);
  }

  @override
  int ppuMapRead(U16 address) {
    if (address >= 0x0000 && address < 0x2000) {
      return address;
    }
    throw UnsupportedError('Mapper0 cannot read by ppu on address 0x${address.toHex()}');
  }

  @override
  int ppuMapWrite(U16 address) {
    if (address >= 0x0000 && address < 0x2000) {
      if (chrBanks == 0) {
        // Treat as RAM
        return address;
      }
    }
    throw UnsupportedError('Mapper0 cannot write by ppu on address 0x${address.toHex()}');
  }
}
