import 'cartridge.dart';
import 'mapper0.dart';

abstract class Mapper {
  Mapper(this.card);

  Cartridge card;

  static create(Cartridge card, int mapperID) {
    switch (mapperID) {
      case 0:
        card.mapper = Mapper0(card);
    }
  }

  int read(int address);
  void write(int address, int value);
}
