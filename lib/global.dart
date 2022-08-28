import 'package:nes/apu.dart';
import 'package:nes/cpu/cpu.dart';
import 'package:nes/joypad.dart';
import 'package:nes/ppu.dart';
import 'package:nes/ram.dart';

import 'bus.dart';
import 'rom/rom.dart';

class Global {
  final bus = Bus();
  final ppu = Ppu();
  final apu = Apu();
  final ram = Ram();
  final rom = Rom();
  final joyPad = JoyPad();
  late CPU cpu;
  void init() {
    // cpu作为总线的主设备需要拿到总线对象
    cpu = CPU(bus);

    // 注册总线上的所有从设备
    [ppu, apu, ram, rom, joyPad].forEach(bus.registerDevice);
  }
}
