import 'package:nes_emulator/ram/ram.dart';

import '../bus_adapter.dart';
import '../cartridge/cartridge.dart';
import '../common.dart';

class PatternTablesAdapterForPpu implements BusAdapter {
  final ICartridge cartridge;
  PatternTablesAdapterForPpu(this.cartridge);

  @override
  bool accept(U16 address) => address >= 0x0000 && address < 0x2000;

  @override
  U8 read(U16 address) {
    final offset = cartridge.mapper.ppuMapRead(address);
    return cartridge.chrRom[offset];
  }

  @override
  void write(U16 address, U8 value) {
    final offset = cartridge.mapper.ppuMapRead(address);
    cartridge.chrRom[offset] = value;
  }
}

/// 该部分为显存Video RAM的适配器
class NameTablesAdapterForPpu implements BusAdapter {
  final Ram ram;
  NameTablesAdapterForPpu(this.ram);

  @override
  bool accept(U16 address) => address >= 0x2000 && address < 0x3F00;

  @override
  U8 read(U16 address) => ram.read((address - 0x2000) % 0x1000);

  @override
  void write(U16 address, U8 value) => ram.write((address - 0x2000) % 0x1000, value);
}

/// 调色板适配器
class PalettesAdapterForPpu implements BusAdapter {
  final Ram ram;
  PalettesAdapterForPpu(this.ram);

  @override
  bool accept(U16 address) => 0x3F00 <= address && address <= 0x4000;

  @override
  U8 read(U16 address) => ram.read((address - 0x3F00) % 0x20);

  @override
  void write(U16 address, U8 value) => ram.write((address - 0x3F00) % 0x20, value);
}

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
