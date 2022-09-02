import 'package:nes_emulator/apu/apu.dart';

import 'adapter.dart';
import 'apu/abstruct_apu.dart';
import 'bus.dart';
import 'bus_adapter.dart';
import 'cartridge/cartridge.dart';
import 'common.dart';
import 'controller/controller.dart';
import 'cpu/cpu.dart';
import 'dma/dma.dart';
import 'framebuffer.dart';
import 'ppu/abstruct_ppu.dart';
import 'ppu/adapter.dart';
import 'ppu/ppu.dart';
import 'ram/ram.dart';

/// 模拟NES主板
class Board {
  // Field
  final F64 sampleRate;
  final void Function(FrameBuffer)? videoOutput; // 视频输出
  final Function(F32)? audioOutput; // 音频输出

  // Simple Device
  final Bus cpuBus = Bus(); // CPU总线
  final Bus ppuBus = Bus(); // PPU总线
  final Ram ram = Ram(0x800); // nes的ram大小为0x800字节, 即 8*16^2B / (1024(B/KB)) = 2KB
  final Ram nameTablesRam = Ram(0x1000); // 显存VRAM NameTable & Attribute
  final Ram palettesRam = Ram(0x20); // Palette

  // Device with line
  late CPU cpu = CPU(bus: cpuBus); // cpu作为总线的master设备需要拿到总线对象
  late IPpu ppu = Ppu(
    bus: ppuBus, // ppu是ppu总线的master设备，需要拿到总线控制权
    onNmiInterrupted: () => cpu.sendInterruptSignal(CpuInterruptSignal.nmi), // 连接PPU的NMI中断信号发生线到CPU
  );
  late IApu apu = Apu(
    onIrqInterrupted: () => cpu.sendInterruptSignal(CpuInterruptSignal.irq), // 连接APU的IRQ中断信号发生线到CPU
    onSample: (sample) {
      if (audioOutput != null) audioOutput!(sample);
    },
    sampleRate: sampleRate,
  );

  Board({
    required ICartridge cartridge,
    IStandardController? controller1,
    IStandardController? controller2,
    this.sampleRate = 44100,
    this.videoOutput,
    this.audioOutput,
  }) {
    // 将各个从设备链接到PPU总线适配器上并分配内存映射地址
    [
      PatternTablesAdapterForPpu(cartridge.mapper),
      NameTablesAdapterForPpu(nameTablesRam, cartridge.mirroring),
      PalettesAdapterForPpu(palettesRam),
      MirrorAdapterForPpu(ppuBus),
    ].forEach(ppuBus.registerDevice);

    // 注册总线上的所有从设备，地址映射关系由各自适配器内部负责
    [
      RamAdapter(ram),
      PpuAdapter(ppu),
      ApuBusAdapter(apu),
      cpu.getDmaControllerAdapter(
        dmaController: DmaController(
          source: cpuBus,
          target: FunctionalWritable((U16 index, U8 value) => cpuBus.write(0x2004, value)), // DMA控制器临时持有总线控制权
        ),
        targetPage: 0,
      ),
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

  /// 主板上的时钟发生器，需要外部调用提供时钟信号
  bool clock([bool? outputVideo = true]) {
    int frame = ppu.totalFrames;

    // 运行一次cpu
    cpu.clock();
    // 执行三次ppu
    ppu.clock();
    ppu.clock();
    ppu.clock();
    // 执行一次apu
    apu.clock();

    if (ppu.totalFrames > frame) {
      // 有新视频信号产生
      if (videoOutput != null && outputVideo!) {
        videoOutput!(ppu.frameBuffer);
      }
      return true;
    }
    return false;
  }

  /// 获取一帧数据
  void nextFrame([bool? outputVideo = true]) {
    while (!clock(outputVideo)) {}
  }
}
