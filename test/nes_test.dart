import "dart:io";

import 'package:nes_emulator/board.dart';
import 'package:nes_emulator/cartridge/cartridge.dart';
import 'package:nes_emulator/cartridge/nes_file.dart';
import 'package:nes_emulator/cpu/cpu.dart';
import 'package:nes_emulator/util.dart';
import 'package:test/test.dart';

class NesLog {
  NesLog({
    required this.regPC,
    required this.opcode,
    required this.bytes,
    required this.instructionAbbr,
    required this.addressingDisplay,
    required this.regA,
    required this.regX,
    required this.regY,
    required this.regPS,
    required this.regSP,
    required this.cpuCycles,
    required this.ppuFrames,
    required this.ppuCycles,
  });

  int regPC;
  int opcode;
  int bytes;
  String instructionAbbr;
  String addressingDisplay;

  int regA;
  int regX;
  int regY;
  int regPS;
  int regSP;

  int cpuCycles;

  int ppuFrames;
  int ppuCycles;

  // log eg: C72F  B0 04     BCS $C735                       A:00 X:00 Y:00 P:27 SP:FB PPU:  0, 93 CYC:31
  static NesLog from(String log) {
    var r = RegExp(r"^(\w{4})  (\w{2}) (\w{2}|  ) (\w{2}|  ) [ *]([A-Z]{3}) (.+) " +
        r"A:(\w{2}) X:(\w{2}) Y:(\w{2}) P:(\w{2}) SP:(\w{2}) PPU:([0-9 ]{3}),([0-9 ]{3}) CYC:(\d+)$");
    var match = r.firstMatch(log);

    if (match == null || match.groupCount != 14) {
      print("log: $log");
      throw "parse log failed";
    }

    var bytesStr = (match.group(4)! + match.group(3)!).trim();

    return NesLog(
        regPC: int.parse(match.group(1)!, radix: 16),
        opcode: int.parse(match.group(2)!, radix: 16),
        bytes: bytesStr != '' ? int.parse(bytesStr, radix: 16) : 0,
        instructionAbbr: match.group(5)!,
        addressingDisplay: match.group(6)!,
        regA: int.parse(match.group(7)!, radix: 16),
        regX: int.parse(match.group(8)!, radix: 16),
        regY: int.parse(match.group(9)!, radix: 16),
        regPS: int.parse(match.group(10)!, radix: 16),
        regSP: int.parse(match.group(11)!, radix: 16),
        ppuFrames: int.parse(match.group(12)!),
        ppuCycles: int.parse(match.group(13)!),
        cpuCycles: int.parse(match.group(14)!));
  }
}

void main() {
  test("cpu test", () async {
    final testlogs = File("testfiles/nestest.txt").readAsLinesSync();

    final Board board =
        Board(cartridge: Cartridge(NesFileReader(File("testfiles/nestest.nes").readAsBytesSync())), sampleRate: 44100);

    board.reset();
    final cpu = board.cpu;
    final ppu = board.ppu;

    cpu.regPC = 0xc000;

    for (int index = 0;; index++) {
      if (index > testlogs.length - 1) {
        // test finished;
        return;
      }

      var log = NesLog.from(testlogs[index]);
      final opcode = cpu.readBus8Bit(cpu.regPC);

      Op op = OpcodeManager.getOp(opcode);

      expect(cpu.regPC.toHex(), log.regPC.toHex(), reason: "regPC not expected at line: ${index + 1}");
      expect(opcode.toHex(), log.opcode.toHex(), reason: "opcode not expected at line: ${index + 1}");
      expect(op.mode.call(cpu).bytes.toHex(), log.bytes.toHex(), reason: "bytes not expected at line: ${index + 1}");
      expect(cpu.regA, log.regA);
      expect(cpu.regX, log.regX);
      expect(cpu.regY, log.regY);
      expect(cpu.regStatus.value, log.regPS);
      expect(cpu.regSP, log.regSP);
      expect(cpu.totalCycles, log.cpuCycles, reason: "cpu cycles not expected at line: ${index + 1}");
      do {
        cpu.clock();
      } while (cpu.isRunningInstruction());
    }
  });
}
