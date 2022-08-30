import 'package:nes_emulator/ram/ram.dart';

import '../bus_adapter.dart';
import '../cartridge/cartridge.dart';
import '../common.dart';

class PpuBusVideoRamAdapter implements BusAdapter {
  final Ram ram;
  PpuBusVideoRamAdapter(this.ram);

  @override
  bool accept(U16 address) {
    // TODO: implement accept
    throw UnimplementedError();
  }

  @override
  U8 read(U16 address) {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  void write(U16 address, U8 value) {
    // TODO: implement write
  }
}

class CartridgeAdapterForPpu implements BusAdapter {
  final ICartridge cartridge;
  CartridgeAdapterForPpu(this.cartridge);

  @override
  bool accept(U16 address) {
    return true;
  }

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
