import 'board.dart';
import 'cartridge/cartridge.dart';
import 'framebuffer.dart';

class Nes {
  Board board;

  final Cartridge cartridge;
  Nes(this.cartridge) : board = Board(cartridge);

  /// 执行一个时钟周期
  void clock() {
    // 运行一次cpu
    board.cpu.runOneClock();
    // 执行三次ppu
    for (int i = 0; i < 3; i++) {
      board.ppu.clock();
    }
  }

  /// 执行下一步CPU指令
  void stepInstruction() {
    do {
      clock();
    } while (board.cpu.isRunningInstruction());
  }

  FrameBuffer stepFrame() {
    clock();
    return board.ppu.frame;
  }
}
