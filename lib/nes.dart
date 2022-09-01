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
    // 运行一次cpu
    int clk = board.cpu.runOneInstruction();
    i += clk;
    // 执行三次ppu
    for (int i = 0; i < 3 * clk; i++) {
      board.ppu.clock();
    }
  }

  FrameBuffer stepFrame() {
    int frame = board.ppu.frame_finished;
    while (board.ppu.frame_finished == frame) {
      // clock可能会影响frame
      clock();
    }

    return board.ppu.frame_data;
  }
}
