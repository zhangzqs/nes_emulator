import 'dart:typed_data';

import 'package:nes/cpu/cpu.dart';
import 'package:nes/ppu/ppu.dart';
import 'package:nes/ram/adapter.dart';
import 'package:nes/ram/ram.dart';
import 'package:nes/rom/cartridge.dart';

import 'apu/adapter.dart';
import 'bus.dart';
import 'joypad/adapter.dart';
import 'ppu/adapter.dart';
import 'rom/rom.dart';

class Global {
  final bus = Bus();

  final joyPad = JoyPadAdapter();

  late CPU cpu;
  late RomAdapter rom;
  late Cartridge card;

  void init(Uint8List gameBytes) {
    // 构造ram
    // nes的ram大小为0x800字节, 即 8*16^2B / (1024(B/KB)) = 2KB
    final ram = RamAdapter(Ram(0x800));

    // 构造卡带
    final card = Cartridge(gameBytes);

    // 构造总线适配器
    final rom = RomAdapter(card);

    // cpu作为总线的主设备需要拿到总线对象
    cpu = CPU(bus);

    // 连接ppu的中断线
    final ppu = PpuAdapter(Ppu(
      bus: bus,
      card: card,
      mirroring: card.mirroring,
      onNmiInterrupted: () {
        cpu.interrupt = CpuInterrupt.nmi;
      },
      onCycleChanged: (int increased) {
        cpu.cycles += increased;
      },
    ));

    final apu = ApuBusAdapter();

    // 注册总线上的所有从设备
    [ppu, apu, ram, rom, joyPad].forEach(bus.registerDevice);
  }
}
