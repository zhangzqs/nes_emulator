import 'adapter.dart';
import 'bus.dart';
import 'bus_adapter.dart';
import 'cartridge/cartridge.dart';
import 'common.dart';
import 'controller/controller.dart';
import 'cpu/cpu.dart';
import 'dma/dma.dart';
import 'ppu/abstruct_ppu.dart';
import 'ppu/adapter.dart';
import 'ppu/ppu.dart';
import 'ram/ram.dart';

/// 模拟NES主板
class Board {
  final cpuBus = Bus();
  final ppuBus = Bus();

  late IPpu ppu;
  late CPU cpu;

  /// nes的ram大小为0x800字节, 即 8*16^2B / (1024(B/KB)) = 2KB
  final Ram ram = Ram(0x800);

  /// NameTables
  final Ram nameTablesRam = Ram(0x1000);

  /// Palette
  final Ram palettesRam = Ram(0x20);

  Board({
    required ICartridge cartridge,
    IStandardController? controller1,
    IStandardController? controller2,
  }) {
    [
      PatternTablesAdapterForPpu(cartridge.mapper),
      NameTablesAdapterForPpu(nameTablesRam, cartridge.mirroring),
      PalettesAdapterForPpu(palettesRam),
      MirrorAdapterForPpu(ppuBus),
    ].forEach(ppuBus.registerDevice);

    // cpu作为总线的master设备需要拿到总线对象
    cpu = CPU(bus: cpuBus);

    // ppu = MyPpu(
    //   bus: ppuBus,
    //   onNmiInterrupt: () => cpu.sendInterruptSignal(CpuInterruptSignal.nmi),
    //   mirroring: cartridge.mirroring,
    //   ppuVideoRAM: nameTablesRam,
    //   ppuPalettes: palettesRam,
    //   mapper: cartridge.mapper,
    // );
    ppu = Ppu(
      bus: ppuBus,
      onNmiInterrupted: () => cpu.sendInterruptSignal(CpuInterruptSignal.nmi),
    );

    final dmaControllerAdapter = cpu.getDmaControllerAdapter(
      dmaController: DmaController(
        source: cpuBus,
        target: FunctionalWritable((U16 index, U8 value) {
          // 写256次2004端口
          cpuBus.write(0x2004, value);
        }),
      ),
      targetPage: 0,
    );

    // 注册总线上的所有从设备，地址映射关系由各自适配器内部负责
    [
      RamAdapter(ram),
      PpuAdapter(ppu),
      ApuBusAdapter(),
      dmaControllerAdapter,
      SoundChannelAdapter(),
      StandardControllerAdapter(
        controller1: controller1,
        controller2: controller2,
      ),
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
