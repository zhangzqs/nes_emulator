import 'package:nes_emulator/controller/controller.dart';
import 'package:nes_emulator/ppu/abstruct_ppu.dart';
import 'package:nes_emulator/util.dart';

import 'bus_adapter.dart';
import 'cartridge/cartridge.dart';
import 'common.dart';
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
  final IPpu ppu;
  PpuAdapter(this.ppu);

  @override
  bool accept(U16 address) => ((0x2000 <= address && address < 0x4000));

  @override
  U8 read(U16 address) {
    switch (address) {
      case 0x2002:
        return ppu.regStatus;
      case 0x2004:
        return ppu.regOamData;
      case 0x2007:
        return ppu.regData;
      default:
        throw UnsupportedError('PPU IO address 0x${address.toHex()} cannot be read');
    }
  }

  @override
  void write(U16 address, U8 value) {
    switch (address) {
      case 0x2000:
        ppu.regController = value;
        return;
      case 0x2001:
        ppu.regMask = value;
        return;
      case 0x2003:
        ppu.regOamAddress = value;
        return;
      case 0x2004:
        ppu.regOamData = value;
        return;
      case 0x2005:
        ppu.regScroll = value;
        return;
      case 0x2006:
        ppu.regAddress = value;
        return;
      case 0x2007:
        ppu.regData = value;
        return;
      default:
        throw UnsupportedError('PPU IO address 0x${address.toHex()} cannot be write');
    }
  }
}

class ApuBusAdapter implements BusAdapter {
  @override
  bool accept(U16 address) => (0x4000 <= address && address < 0x4014);

  @override
  U8 read(U16 address) => 0;

  @override
  void write(U16 address, U8 value) {}
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

class StandardControllerAdapter implements BusAdapter {
  IStandardController? controller1, controller2;
  StandardControllerAdapter({
    required this.controller1,
    required this.controller2,
  });
  @override
  bool accept(U16 address) => (0x4016 <= address && address < 0x4018);

  @override
  U8 read(U16 address) {
    final controller = address == 0x4016 ? controller1 : controller2;
    return controller?.regKeyState ?? 0;
  }

  @override
  void write(U16 address, U8 value) {
    final controller = address == 0x4016 ? controller1 : controller2;
    controller?.regStrobe = value;
  }
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
class CartridgeAdapterForCpu implements BusAdapter {
  final ICartridge cartridge;
  CartridgeAdapterForCpu(this.cartridge);

  @override
  bool accept(U16 address) => (0x4020 <= address && address <= 0xFFFF);

  @override
  U8 read(U16 address) => cartridge.mapper.cpuMapRead(address);

  @override
  void write(U16 address, U8 value) => cartridge.mapper.cpuMapWrite(address, value);
}
