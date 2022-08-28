import 'cartridge.dart';
import 'mapper0.dart';

abstract class Mapper {
  Mapper(this.card);

  Cardtridge card;

  static create(Cardtridge card, int mapperID) {
    switch (mapperID) {
      case 0:
        card.mapper = Mapper0(card);
    }
  }

  int read(int address) {
    // TODO: implements
    return 0;
  }

  void write(int address, int value) {}
}
