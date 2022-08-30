import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nes_emulator/cartridge/cartridge.dart';
import 'package:nes_emulator/cartridge/nes_file.dart';
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

  loadGame([String gamePath = 'roms/Super_mario_brothers.nes']) async {
    final ByteData gameBytes = await rootBundle.load(gamePath);
    final nesFile = NesFileReader(gameBytes.buffer.asUint8List());
    final cartridge = Cartridge(nesFile);
    print(nesFile);
    print(cartridge);
    nes = Nes(cartridge);
    _gameLoadedCompleter.complete('loaded');
    runFrameLoop();
  }

  runFrameLoop() {
    _frameLoopTimer = Timer.periodic(const Duration(milliseconds: 1), (timer) async {
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
