import 'package:nes_emulator/common.dart';

import 'mapper0.dart';

abstract class Mapper {
  U8 prgBanks, chrBanks;
  Mapper(this.prgBanks, this.chrBanks);

  /// 地址映射，cpu总线上的地址映射到 PRG ROM 的偏移量上
  int cpuMapRead(U16 address);
  int cpuMapWrite(U16 address);

  /// 地址映射，ppu总线上的地址映射到 PRG ROM 的偏移量上
  int ppuMapRead(U16 address);
  int ppuMapWrite(U16 address);
}

class MapperFactory {
  static Mapper getMapper(int mapperId, U8 prgBanks, U8 chrBanks) {
    switch (mapperId) {
      case 0:
        return Mapper0(prgBanks, chrBanks);
      default:
        throw UnimplementedError('未实现Mapper $mapperId');
    }
  }
}
