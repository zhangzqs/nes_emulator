import 'dart:typed_data';

import 'package:nes/board.dart';
import 'package:nes/rom/cartridge.dart';

import 'framebuffer.dart';

class Nes {
  Board board;
  Uint8List gameBytes;
  double fps = 0;

  Nes(this.gameBytes) : board = Board(Cartridge(gameBytes));

  void clock() {
    int times = board.cpu.clock() * 3;

    while (times-- > 0) {
      board.ppu.clock();
    }
  }

  void stepInstruction() {
    do {
      clock();
    } while (board.cpu.cycles != 0);
  }

  FrameBuffer stepFrame() {
    int frame = board.ppu.frames;
    var start = DateTime.now();
    while (board.ppu.frames == frame) {
      clock();
    }

    // update fps
    fps = 1000 / DateTime.now().difference(start).inMilliseconds;
    return board.ppu.frame;
  }
}
