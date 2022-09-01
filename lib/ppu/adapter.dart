import 'package:nes_emulator/cartridge/mapper/mapper.dart';
import 'package:nes_emulator/ram/ram.dart';

import '../bus_adapter.dart';
import '../common.dart';

class PatternTablesAdapterForPpu implements BusAdapter {
  final Mapper mapper;
  PatternTablesAdapterForPpu(this.mapper);

  @override
  bool accept(U16 address) => address >= 0x0000 && address < 0x2000;

  @override
  U8 read(U16 address) => mapper.ppuMapRead(address);

  @override
  void write(U16 address, U8 value) => mapper.ppuMapWrite(address, value);
}

/// 该部分为显存Video RAM的适配器
class NameTablesAdapterForPpu implements BusAdapter {
  static const _mirrorLookUp = [
    [0, 0, 1, 1], //horizontal
    [0, 1, 0, 1], //vertical
    [0, 0, 0, 0], //singleScreen
    [1, 1, 1, 1], //fourScreen
  ];

  // 物理上存储2个NameTable
  // 逻辑上映射为了4个NameTable
  final Ram ram;
  final Mirroring mirroring;
  NameTablesAdapterForPpu(this.ram, this.mirroring);

  // U16 _mirrorAddress(U16 address) {
  //   final mode = mirroring.index;
  //   address = (address - 0x2000) % 0x1000;
  //   final table = address ~/ 0x0400;
  //   final offset = address % 0x0400;
  //   return 0x2000 + _mirrorLookUp[mode][table] * 0x0400 + offset;
  // }

  int _mirrorAddress(int address) {
    address = address % 0x1000;
    int chunk = address ~/ 0x400;

    switch (mirroring) {
      // [A][A] --> [0x2000][0x2400]
      // [B][B] --> [0x2800][0x2c00]
      case Mirroring.horizontal:
        return [1, 3].contains(chunk) ? address - 0x400 : address;

      // [A][B] --> [0x2000][0x2400]
      // [A][B] --> [0x2800][0x2c00]
      case Mirroring.vertical:
        return chunk > 1 ? address - 0x800 : address;

      // [A][B] --> [0x2000][0x2400]
      // [C][D] --> [0x2800][0x2c00]
      case Mirroring.fourScreen:
        return address;

      // [A][A] --> [0x2000][0x2400]
      // [A][A] --> [0x2800][0x2c00]
      case Mirroring.singleScreen:
        return address % 0x400;
    }
  }

  @override
  bool accept(U16 address) => address >= 0x2000 && address < 0x3F00;

  @override
  U8 read(U16 address) => ram.read(_mirrorAddress(address));

  @override
  void write(U16 address, U8 value) => ram.write(_mirrorAddress(address), value);
}

/// 调色板适配器
class PalettesAdapterForPpu implements BusAdapter {
  final Ram ram;
  PalettesAdapterForPpu(this.ram);

  /// 读取调色板
  /// address取值为0<=address<=31
  U8 _readPalette(U16 address) {
    // 调色板有32字节组成，有8个子调色板
    // 前4个调色板供背景使用，后四个调色板供精灵使用
    // 每个子调色板有4种颜色，每个颜色由一字节索引组成
    // 即4*8 = 32字节

    // 如果是精灵的调色板且命中0号颜色
    // 没搞懂
    // https://github.com/fogleman/nes/blob/master/nes/ppu.go#L195
    if (address >= 16 && address % 4 == 0) {
      address -= 16;
    }
    return ram.read(address);
  }

  /// 写入调色板
  void _writePalette(U16 address, U8 value) {
    if (address >= 16 && address % 4 == 0) {
      address -= 16;
    }
    return ram.write(address, value);
  }

  @override
  bool accept(U16 address) => 0x3F00 <= address && address < 0x4000;

  @override
  U8 read(U16 address) => _readPalette((address - 0x3F00) % 0x20);

  @override
  void write(U16 address, U8 value) => _writePalette((address - 0x3F00) % 0x20, value);
}

/// 最后的镜像适配器
class MirrorAdapterForPpu implements BusAdapter {
  final BusAdapter bus;
  MirrorAdapterForPpu(this.bus);

  @override
  bool accept(U16 address) => 0x4000 <= address && address <= 0xFFFF;

  @override
  U8 read(U16 address) => bus.read(address % 0x4000);

  @override
  void write(U16 address, U8 value) => bus.write(address % 0x4000, value);
}
