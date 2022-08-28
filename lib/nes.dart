import 'board.dart';
import 'framebuffer.dart';
import 'rom/cartridge.dart';

class Nes {
  Board board;
  double fps = 0;

  final Cartridge cartridge;
  Nes(this.cartridge) : board = Board(cartridge);

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
