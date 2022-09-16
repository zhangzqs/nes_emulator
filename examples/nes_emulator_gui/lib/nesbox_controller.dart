import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:nes_emulator/cartridge/cartridge.dart';
import 'package:nes_emulator/cartridge/nes_file.dart';
import 'package:nes_emulator/controller/controller.dart';
import 'package:nes_emulator/framebuffer.dart';
import 'package:nes_emulator/nes.dart';

class NesBoxController {
  NesBoxController();

  Timer? _frameLoopTimer, _fpsTimer;

  final _frameStreamController = StreamController<FrameBuffer>.broadcast();
  Stream<FrameBuffer> get frameStream => _frameStreamController.stream;

  final _fpsStreamController = StreamController<int>.broadcast();
  Stream<int> get fpsStream => _fpsStreamController.stream;

  final JoyPadController controller1 = JoyPadController();
  final JoyPadController controller2 = JoyPadController();

  Nes? nes;

  int frames = 0;

  Future<void> loadGame(Uint8List gameData) async {
    final nesFile = NesFileReader(gameData);
    final cartridge = Cartridge(nesFile);
    nes = Nes(
      cartridge: cartridge,
      controller1: controller1,
      controller2: controller2,
      sampleRate: 44100,
      videoOutput: (FrameBuffer frameBuffer) {
        _frameStreamController.sink.add(frameBuffer);
        frames++;
      },
      audioOutput: (double sd) {},
    );
    runFrameLoop();
  }

  void runFrameLoop() {
    _frameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      nes?.nextFrame();
    });
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fpsStreamController.sink.add(frames);
      frames = 0;
    });
  }

  void pause() {
    _frameLoopTimer?.cancel();
    _fpsTimer?.cancel();
  }

  void resume() {
    runFrameLoop();
  }
}
