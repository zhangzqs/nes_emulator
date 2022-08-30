import 'package:nes_emulator/bus_adapter.dart';
import 'package:nes_emulator/dma/dma.dart';

import 'adapter.dart';
import 'bus.dart';
import 'cartridge/cartridge.dart';
import 'common.dart';
import 'cpu/cpu.dart';
import 'ppu/adapter.dart';
import 'ppu/ppu.dart';
import 'ram/ram.dart';

/// 模拟NES主板
class Board {
  final cpuBus = Bus();

  late Ppu ppu;
  late CPU cpu;

  /// nes的ram大小为0x800字节, 即 8*16^2B / (1024(B/KB)) = 2KB
  final Ram ram = Ram(0x800);

  Board(ICartridge cartridge) {
    // cpu作为总线的master设备需要拿到总线对象
    cpu = CPU(bus: cpuBus);

    ppu = Ppu(
      ppuBus: CartridgeAdapterForPpu(cartridge),
      mirroring: cartridge.mirroring,
      onNmiInterrupted: () => cpu.sendInterruptSignal(CpuInterruptSignal.nmi),
    );

    final dmaControllerAdapter = cpu.getDmaControllerAdapter(
      DmaController(
        source: cpuBus,
        target: FunctionalWritable((U16 index, U8 value) {
          // 写256次2004端口
          ppu.regOamData = value;
        }),
      ),
      0,
    );

    // 注册总线上的所有从设备，地址映射关系由各自适配器内部负责
    [
      RamAdapter(ram),
      PpuAdapter(ppu),
      ApuBusAdapter(),
      dmaControllerAdapter,
      SoundChannelAdapter(),
      JoyPadAdapter(),
      UnusedAdapter(),
      CartridgeAdapterForCpu(cartridge),
    ].forEach(cpuBus.registerDevice);

    reset();
  }

  /// 主板上的reset按键
  void reset() {
    ram.reset();
    cpu.reset();
    ppu.reset();
  }
}
