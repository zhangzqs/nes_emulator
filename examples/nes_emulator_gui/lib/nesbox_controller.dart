import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
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

  Timer? _frameLoopTimer, _fpsTimer;

  final _frameStreamController = StreamController<FrameBuffer>.broadcast();
  Stream<FrameBuffer> get frameStream => _frameStreamController.stream;

  final _paletteStreamController = StreamController<FrameBuffer>.broadcast();
  Stream<FrameBuffer> get paletteStream => _paletteStreamController.stream;

  final _fpsStreamController = StreamController<int>.broadcast();
  Stream<int> get fpsStream => _fpsStreamController.stream;

  late ICartridge cartridge;
  late JoyPadController controller1, controller2;

  late TileFrame tileFrame1, tileFrame2, palettes;
  late PalettesReader palettesReader;

  // final _soundPlayer = FlutterSoundPlayer();
  var sampleCount = 0;

  final sample = <double>[];
  int samplePtr = 0;
  int frames = 0;

  bool isStop = false;

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
      sampleRate: 44100,
      videoOutput: (FrameBuffer frameBuffer) {
        _frameStreamController.sink.add(frameBuffer);
        _paletteStreamController.sink.add(palettesReader.create());
        frames++;
      },
      audioOutput: (double sd) {
        // sample.add(sd);
      },
    );
    final tileFrameReader = PatternTablesReader(PatternTablesAdapterForPpu(cartridge.mapper));
    palettesReader = PalettesReader(nes.board.ppuBus);
    tileFrame1 = tileFrameReader.firstTileFrame;
    tileFrame2 = tileFrameReader.secondTileFrame;
    // await play();
    runFrameLoop();
  }

  Future<void> play() async {
    // await _soundPlayer.openPlayer();
    // await _soundPlayer.startPlayerFromStream(
    //   codec: Codec.pcm16,
    //   sampleRate: 44100,
    // );
  }

  void runFrameLoop() {
    _frameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      nes.nextFrame();
    });
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fpsStreamController.sink.add(frames);
      frames = 0;
    });
    // Timer.periodic(const Duration(seconds: 3), (timer) {
    //   final int16List = sample.map((e) => (e * 32767).floor()).toList();
    //   final buffer = Int16List.fromList(int16List);
    //   _soundPlayer.feedFromStream(Uint8List.view(buffer.buffer));
    //   sample.clear();
    // });
  }

  void pause() {
    _frameLoopTimer?.cancel();
    _fpsTimer?.cancel();
  }

  void resume() {
    runFrameLoop();
  }
}
