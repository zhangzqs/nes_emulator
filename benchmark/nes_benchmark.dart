import 'dart:io';

import 'package:benchmarking/benchmarking.dart';
import 'package:nes_emulator/nes_emulator.dart';

void main() {
  Nes nes = Nes(
    cartridge: Cartridge(NesFileReader(File('testfiles/nestest.nes').readAsBytesSync())),
    sampleRate: 44100,
    videoOutput: (FrameBuffer frame) {},
  );

  nes.nextFrame();

  syncBenchmark('a', () {
    nes.nextFrame();
  }).report(units: 100);
}
