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
        ) {
    Future.delayed(Duration(seconds: 1), () async {
      while (true) {
        i = 0;
        await Future.delayed(Duration(seconds: 1));
        print(i / (1024 * 1024));
      }
    });
  }

  static int i = 0;

  /// 执行一个cpu时钟周期
  void clock() {
    i++;
    // 运行一次cpu
    board.cpu.runOneClock();
    // 执行三次ppu
    for (int i = 0; i < 3; i++) {
      board.ppu.clock();
    }
  }

  FrameBuffer stepFrame() {
    int frame = board.ppu.frame;
    while (board.ppu.frame == frame) {
      // clock可能会影响frame
      clock();
    }

    return board.ppu.front;
  }
}
