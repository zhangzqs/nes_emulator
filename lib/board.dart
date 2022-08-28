import 'bus.dart';
import 'cpu/cpu.dart';
import 'ppu/adapter.dart';
import 'ppu/ppu.dart';
import 'ram/adapter.dart';
import 'ram/ram.dart';
import 'rom/adapter.dart';
import 'rom/cartridge.dart';

/// 模拟NES主板
class Board {
  final bus = Bus();
  late Ppu ppu;
  late CPU cpu;
  late Ram ram;

  Board(Cartridge cartridge) {
    // nes的ram大小为0x800字节, 即 8*16^2B / (1024(B/KB)) = 2KB
    ram = Ram(0x800);

    // cpu作为总线的主设备需要拿到总线对象
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

    // 注册总线上的所有从设备
    [
      PpuAdapter(ppu),
      // ApuBusAdapter(),
      RamAdapter(ram),
      RomAdapter(cartridge),
      SRamAdapter(cartridge),
      // JoyPadAdapter(),
    ].forEach(bus.registerDevice);

    reset();
  }

  /// 主板上的reset按键
  void reset() {
    cpu.reset();
    ppu.reset();
  }
}
