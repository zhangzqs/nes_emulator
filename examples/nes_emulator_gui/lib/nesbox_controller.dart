import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nes_emulator/cartridge/cartridge.dart';
import 'package:nes_emulator/cartridge/nes_file.dart';
import 'package:nes_emulator/controller/controller.dart';
import 'package:nes_emulator/framebuffer.dart';
import 'package:nes_emulator/nes.dart';

class NesBoxController {
  NesBoxController();

  late Nes nes;

  Timer? _frameLoopTimer;

  Completer _gameLoadedCompleter = Completer();

  late Future gameLoaded = _gameLoadedCompleter.future;

  final _frameStreamController = StreamController<FrameBuffer>.broadcast();

  Stream<FrameBuffer> get frameStream => _frameStreamController.stream;

  late ICartridge cartridge;
  late JoyPadController controller1, controller2;

  loadGame([String gamePath = 'roms/Super_mario_brothers.nes']) async {
    final ByteData gameBytes = await rootBundle.load(gamePath);
    final nesFile = NesFileReader(gameBytes.buffer.asUint8List());
    cartridge = Cartridge(nesFile);
    controller1 = JoyPadController();
    controller2 = JoyPadController();
    print(cartridge);
    nes = Nes(
      cartridge: cartridge,
      controller1: controller1,
      controller2: controller2,
    );
    _gameLoadedCompleter.complete('loaded');
    runFrameLoop();
  }

  runFrameLoop() {
    _frameLoopTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) async {
      _frameStreamController.sink.add(nes.stepFrame());
    });
  }

  pause() {
    _frameLoopTimer?.cancel();
  }

  resume() {
    runFrameLoop();
  }
}

NesBoxController useNesBoxController() {
  final boxContorller = useState(NesBoxController());

  return boxContorller.value;
}
