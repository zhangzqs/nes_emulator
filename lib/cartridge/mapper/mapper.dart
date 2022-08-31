import 'package:nes_emulator/cartridge/cartridge.dart';
import 'package:nes_emulator/common.dart';

import 'mapper2.dart';

abstract class Mapper {
  final ICartridge cartridge;
  Mapper(this.cartridge);

  U8 cpuMapRead(U16 address);
  void cpuMapWrite(U16 address, U8 value);

  U8 ppuMapRead(U16 address);
  void ppuMapWrite(U16 address, U8 value);
}

class MapperFactory {
  static Mapper getMapper(ICartridge cartridge) {
    switch (cartridge.mapperId) {
      case 0:
        return Mapper2(cartridge);
      case 2:
        return Mapper2(cartridge);
      default:
        throw UnimplementedError('未实现Mapper ${cartridge.mapperId}');
    }
  }
}
