import 'bus_adapter.dart';
import 'cartridge/cartridge.dart';
import 'common.dart';
import 'dma/dma.dart';
import 'ppu/ppu.dart';
import 'ram/ram.dart';

class RamAdapter implements BusAdapter {
  final Ram ram;

  RamAdapter(this.ram);

  @override
  bool accept(U16 address) => (0 <= address && address < 0x2000);

  @override
  U8 read(U16 address) => ram.read(address % 0x800);

  @override
  void write(U16 address, U8 value) => ram.write(address % 0x800, value);
}

class PpuAdapter implements BusAdapter {
  final Ppu ppu;
  PpuAdapter(this.ppu);

  @override
  bool accept(U16 address) => ((0x2000 <= address && address < 0x4000));

  @override
  U8 read(U16 address) => ppu.readRegister(address % 0x08);

  @override
  void write(U16 address, U8 value) => ppu.writeRegister(address % 0x08, value);
}

class ApuBusAdapter implements BusAdapter {
  @override
  bool accept(U16 address) => (0x4000 <= address && address < 0x4014);

  @override
  U8 read(U16 address) => 0;

  @override
  void write(U16 address, U8 value) {}
}

class DmaControllerAdapter implements BusAdapter {
  final DmaController dmaController;
  final U8 targetPage;
  DmaControllerAdapter(this.dmaController, this.targetPage);

  @override
  bool accept(U16 address) => address == 0x4014;

  @override
  U8 read(U16 address) => throw UnsupportedError('DMA controller cannot be read');

  @override
  void write(U16 address, U8 value) => dmaController.transferPage(value, targetPage);
}

class SoundChannelAdapter implements BusAdapter {
  @override
  bool accept(U16 address) => address == 0x4015;

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

class JoyPadAdapter implements BusAdapter {
  @override
  bool accept(U16 address) => (0x4016 <= address && address < 0x4018);

  @override
  U8 read(U16 address) => 0;

  @override
  void write(U16 address, U8 value) {}
}

class UnusedAdapter implements BusAdapter {
  @override
  bool accept(U16 address) => 0x4018 <= address && address < 0x4020;

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

// Cartridge(ExpansionRom/SRam/Rom)
class CartridgeAdapter implements BusAdapter {
  final Cartridge cartridge;
  CartridgeAdapter(this.cartridge);

  @override
  bool accept(U16 address) => (0x4020 <= address && address <= 0xFFFF);

  @override
  U8 read(U16 address) => cartridge.read(address);

  @override
  void write(U16 address, U8 value) => cartridge.write(address, value);
}
