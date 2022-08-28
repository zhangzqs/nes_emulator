// NORM: https://wiki.nesdev.org/w/index.php?title=NROM
import 'cartridge.dart';
import 'mapper.dart';

class Mapper0 extends Mapper {
  Mapper0(Cardtridge card) : super(card);

  @override
  read(int address) {
    if (address < 0x2000) {
      return card.chrROM[address];
    }

    if (address >= 0x6000 && address < 0x8000) {
      if (card.battery) return card.sRAM[address - 0x6000];
      return 0;
    }

    if (address >= 0x8000 && address < 0xc000) {
      return card.prgROM[address - 0x8000];
    }

    if (address >= 0xc000) {
      if (card.prgBanks == 1) return card.prgROM[address - 0xc000];
      return card.prgROM[address - 0x8000];
    }

    return 0;
  }

  @override
  write(int address, int value) {
    if (address < 0x2000) {
      card.chrROM[address] = value;
    }

    if (address >= 0x6000 && address < 0x8000) {
      if (card.battery) card.sRAM[address - 0x6000] = value;
    }
    return;
  }
}
