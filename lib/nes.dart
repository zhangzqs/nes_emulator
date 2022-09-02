import 'apu/apu.dart';
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
    required F64 sampleRate, // 音频信号采样率
    void Function(FrameBuffer)? videoOutput,
    void Function(F32)? audioOutput,
  }) : board = Board(
          cartridge: cartridge,
          controller1: controller1,
          controller2: controller2,
          sampleRate: sampleRate,
          videoOutput: videoOutput,
          audioOutput: audioOutput,
        );

  void reset() => board.reset();

  void nextFrame() => board.nextFrame();
}
