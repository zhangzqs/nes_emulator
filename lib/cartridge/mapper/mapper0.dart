// NORM: https://wiki.nesdev.org/w/index.php?title=NROM
import '../../common.dart';
import '../cartridge.dart';
import 'mapper.dart';

class Mapper0 implements Mapper {
  final Cartridge cartridge;
  Mapper0(this.cartridge);

  @override
  U8 read(U16 address) {
    if (address < 0x2000) {
      return cartridge.chrROM[address];
    }

    if (address >= 0x6000 && address < 0x8000) {
      return cartridge.battery ? cartridge.sRAM[address - 0x6000] : 0;
    }

    if (address >= 0x8000 && address < 0xc000) {
      return cartridge.prgROM[address - 0x8000];
    }

    if (address >= 0xc000) {
      if (cartridge.prgBanks == 1) return cartridge.prgROM[address - 0xc000];
      return cartridge.prgROM[address - 0x8000];
    }

    return 0;
  }

  @override
  void write(U16 address, U8 value) {
    if (address < 0x2000) cartridge.chrROM[address] = value;
    if (address >= 0x6000 && address < 0x8000 && cartridge.battery) cartridge.sRAM[address - 0x6000] = value;
  }
}
