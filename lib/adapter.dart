import 'apu/abstruct_apu.dart';
import 'bus_adapter.dart';
import 'cartridge/cartridge.dart';
import 'common.dart';
import 'controller/controller.dart';
import 'ppu/abstruct_ppu.dart';
import 'ram/ram.dart';
import 'util.dart';

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
    switch ((address - 0x2000) % 8) {
      case 2:
        return ppu.regStatus;
      case 4:
        return ppu.regOamData;
      case 7:
        return ppu.regData;
      default:
        throw UnsupportedError('PPU IO address 0x${address.toHex()} cannot be read');
    }
  }

  @override
  void write(U16 address, U8 value) {
    switch ((address - 0x2000) % 8) {
      case 0:
        ppu.regController = value;
        return;
      case 1:
        ppu.regMask = value;
        return;
      case 3:
        ppu.regOamAddress = value;
        return;
      case 4:
        ppu.regOamData = value;
        return;
      case 5:
        ppu.regScroll = value;
        return;
      case 6:
        ppu.regAddress = value;
        return;
      case 7:
        ppu.regData = value;
        return;
      default:
        throw UnsupportedError('PPU IO address 0x${address.toHex()} cannot be write');
    }
  }
}

class ApuBusAdapter implements BusAdapter {
  IApu apu;
  ApuBusAdapter(this.apu);

  @override
  bool accept(U16 address) => (0x4000 <= address && address < 0x4014) || address == 0x4015;

  @override
  U8 read(U16 address) {
    switch (address) {
      case 0x4015:
        return apu.readStatus();
      default:
        throw UnsupportedError("unhandled apu register read at address: ${address.toHex()}");
    }
  }

  @override
  void write(U16 address, U8 value) {
    switch (address) {
      case 0x4000:
        apu.writeControlToPulse1(value);
        break;
      case 0x4001:
        apu.writeSweepToPulse1(value);
        break;
      case 0x4002:
        apu.writeTimerLowToPulse1(value);
        break;
      case 0x4003:
        apu.writeTimerHighToPulse1(value);
        break;
      case 0x4004:
        apu.writeControlToPulse2(value);
        break;
      case 0x4005:
        apu.writeSweepToPulse2(value);
        break;
      case 0x4006:
        apu.writeTimerLowToPulse2(value);
        break;
      case 0x4007:
        apu.writeTimerHighToPulse2(value);
        break;
      case 0x4008:
        apu.writeControlToTriangle(value);
        break;
      case 0x4009:
        break;
      case 0x4010:
        apu.writeControlToDmc(value);
        break;
      case 0x4011:
        apu.writeValueToDmc(value);
        break;
      case 0x4012:
        apu.writeAddressToDmc(value);
        break;
      case 0x4013:
        apu.writeLengthToDmc(value);
        break;
      case 0x400A:
        apu.writeTimerLowToTriangle(value);
        break;
      case 0x400B:
        apu.writeTimerHighToTriangle(value);
        break;
      case 0x400C:
        apu.writeControlToNoise(value);
        break;
      case 0x400D:
        break;
      case 0x400E:
        apu.writePeriodToNoise(value);
        break;
      case 0x400F:
        apu.writeLengthToNoise(value);
        break;
      case 0x4015:
        apu.writeControl(value);
        break;
      case 0x4017:
        apu.writeFrameCounter(value);
        break;
      default:
        throw UnsupportedError('unhandled apu register write at address: ${address.toHex()}');
    }
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
    return 0;
  }

  @override
  void write(U16 address, U8 value) {}
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
