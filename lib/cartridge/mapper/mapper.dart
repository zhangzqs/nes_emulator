import 'package:nes_emulator/common.dart';

import '../cartridge.dart';
import 'mapper0.dart';

abstract class Mapper {
  factory Mapper(Cartridge cartridge) {
    switch (cartridge.mapperId) {
      case 0:
        return Mapper0(cartridge);
      default:
        throw UnimplementedError('未实现Mapper${cartridge.mapperId}');
    }
  }

  U8 read(U16 address);
  void write(U16 address, U8 value);
}
