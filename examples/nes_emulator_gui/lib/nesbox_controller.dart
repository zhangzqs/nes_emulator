import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nes_emulator/cartridge/cartridge.dart';
import 'package:nes_emulator/cartridge/nes_file.dart';
import 'package:nes_emulator/controller/controller.dart';
import 'package:nes_emulator/framebuffer.dart';
import 'package:nes_emulator/nes.dart';
import 'package:nes_emulator/ppu/adapter.dart';
import 'package:nes_emulator/ppu/pattern_tables_reader.dart';

class NesBoxController {
  NesBoxController();

  late Nes nes;

  Timer? _frameLoopTimer;

  Completer _gameLoadedCompleter = Completer();

  late Future gameLoaded = _gameLoadedCompleter.future;

  final _frameStreamController = StreamController<FrameBuffer>.broadcast();

  Stream<FrameBuffer> get frameStream => _frameStreamController.stream;

  final _paletteStreamController = StreamController<FrameBuffer>.broadcast();
  Stream<FrameBuffer> get paletteStream => _paletteStreamController.stream;

  late ICartridge cartridge;
  late JoyPadController controller1, controller2;

  late TileFrame tileFrame1, tileFrame2, palettes;
  late PalettesReader palettesReader;

  Future<void> loadGame([String gamePath = 'roms/Super_mario_brothers.nes']) async {
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
    final tileFrameReader = PatternTablesReader(PatternTablesAdapterForPpu(cartridge));
    palettesReader = PalettesReader(nes.board.ppuBus);
    tileFrame1 = tileFrameReader.firstTileFrame;
    tileFrame2 = tileFrameReader.secondTileFrame;
    if (!_gameLoadedCompleter.isCompleted) _gameLoadedCompleter.complete('loaded');
    runFrameLoop();
  }

  void runFrameLoop() {
    _frameLoopTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) async {
      _frameStreamController.sink.add(nes.stepFrame());
      _paletteStreamController.sink.add(palettesReader.create());
    });
  }

  void pause() {
    _frameLoopTimer?.cancel();
  }

  void resume() {
    runFrameLoop();
  }
}
