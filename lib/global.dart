import 'dart:typed_data';

import 'package:nes/apu.dart';
import 'package:nes/cpu/cpu.dart';
import 'package:nes/joypad.dart';
import 'package:nes/ppu/ppu.dart';
import 'package:nes/ram.dart';
import 'package:nes/rom/cartridge.dart';

import 'bus.dart';
import 'rom/rom.dart';

class Global {
  final bus = Bus();
  final apu = Apu();
  final ram = Ram();

  final joyPad = JoyPad();
  late CPU cpu;
  late Ppu ppu;
  late Rom rom;
  late Cartridge card;

  void init(Uint8List gameBytes) {
    // 构造卡带
    card = Cartridge(gameBytes);

    // 构造总线适配器
    rom = Rom(card);

    // 连接ppu的中断线
    ppu = Ppu(
      bus: bus,
      card: card,
      mirroring: card.mirroring,
      onNmiInterrupted: () {
        cpu.interrupt = CpuInterrupt.nmi;
      },
      onCycleChanged: (int increased) {
        cpu.cycles += increased;
      },
    );

    // cpu作为总线的主设备需要拿到总线对象
    cpu = CPU(bus);

    // 注册总线上的所有从设备
    [ppu, apu, ram, rom, joyPad].forEach(bus.registerDevice);
  }
}
