import 'package:nes_emulator/util.dart';

import '../constant.dart';
import '../framebuffer.dart';
import 'adapter.dart';

class TileFrameReader {
  CartridgeAdapterForPpu adapter;
  TileFrameReader(this.adapter);

  late TileFrame firstTileFrame = createTileFrame();
  late TileFrame secondTileFrame = createTileFrame(0x1000);

  TileFrame createTileFrame([int baseAddress = 0]) {
    final frame = TileFrame();
    for (int tiles = 0; tiles < 0x100; tiles++) {
      for (int fineY = 0; fineY < 8; fineY++) {
        var lowTile = adapter.read(baseAddress + tiles * 8 + fineY);
        var highTile = adapter.read(baseAddress + tiles * 8 + fineY + 8);

        for (int fineX = 0; fineX < 8; fineX++) {
          int lowBit = lowTile.getBit(7 - fineX).asInt();
          int highBit = highTile.getBit(7 - fineX).asInt();

          int x = (tiles % 16) * 8 + fineX;
          int y = (tiles / 16).floor() * 8 + fineY;

          frame.setPixel(x, y, Constant.nesSysPalettes[highBit << 1 | lowBit] ?? 0);
        }
      }
    }
    return frame;
  }
}
