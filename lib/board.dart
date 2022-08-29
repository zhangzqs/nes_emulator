import 'package:nes_emulator/bus_adapter.dart';
import 'package:nes_emulator/dma/dma.dart';

import 'adapter.dart';
import 'bus.dart';
import 'cartridge/cartridge.dart';
import 'common.dart';
import 'cpu/cpu.dart';
import 'ppu/ppu.dart';
import 'ram/ram.dart';

/// 模拟NES主板
class Board {
  final bus = Bus();
  late Ppu ppu;
  late CPU cpu;
  late Ram ram;

  Board(Cartridge cartridge) {
    // nes的ram大小为0x800字节, 即 8*16^2B / (1024(B/KB)) = 2KB
    ram = Ram(0x800);

    // cpu作为总线的master设备需要拿到总线对象
    cpu = CPU(bus);

    ppu = Ppu(
      bus: bus,
      cartridge: cartridge,
      onNmiInterrupted: () {
        cpu.interrupt = CpuInterrupt.nmi;
      },
      onCycleChanged: (int increased) {
        cpu.cycles += increased;
      },
    );

    final dma = DmaController(
      sourceBus: bus,
      targetBus: FunctionalBusAdapter(
        onWritten: (U16 address, U8 value) {
          ppu.oam[address] = value;
        },
      ),
    );

    // 注册总线上的所有从设备，地址映射关系由各自适配器内部负责
    [
      RamAdapter(ram),
      PpuAdapter(ppu),
      ApuBusAdapter(),
      DmaControllerAdapter(dma, 0),
      SoundChannelAdapter(),
      JoyPadAdapter(),
      UnusedAdapter(),
      CartridgeAdapter(cartridge),
    ].forEach(bus.registerDevice);

    reset();
  }

  /// 主板上的reset按键
  void reset() {
    ram.reset();
    cpu.reset();
    ppu.reset();
  }
}
