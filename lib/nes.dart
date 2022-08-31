import 'board.dart';
import 'cartridge/cartridge.dart';
import 'controller/controller.dart';
import 'framebuffer.dart';

class Nes {
  final Board board;

  Nes({
    required ICartridge cartridge,
    IStandardController? controller1,
    IStandardController? controller2,
  }) : board = Board(
          cartridge: cartridge,
          controller1: controller1,
          controller2: controller2,
        );

  /// 执行一个cpu时钟周期
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
    int frame = board.ppu.frames;
    while (board.ppu.frames == frame) {
      // clock可能会影响frame
      clock();
    }

    return board.ppu.frame;
  }
}
