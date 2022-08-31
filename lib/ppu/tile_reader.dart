import 'package:nes_emulator/util.dart';

import '../common.dart';
import '../framebuffer.dart';
import 'adapter.dart';

class TileFrameReader {
  PatternTablesAdapterForPpu adapter;
  TileFrameReader(this.adapter);

  late TileFrame firstTileFrame = createTileFrame();
  late TileFrame secondTileFrame = createTileFrame(0x1000);

  TileFrame createTileFrame([int baseAddress = 0]) {
    final frame = TileFrame();
    for (int tiles = 0; tiles < 0x100; tiles++) {
      for (int fineY = 0; fineY < 8; fineY++) {
        U8 lowTile = adapter.read(baseAddress + tiles * 8 + fineY);
        U8 highTile = adapter.read(baseAddress + tiles * 8 + fineY + 8);

        for (int fineX = 0; fineX < 8; fineX++) {
          int lowBit = lowTile.getBit(7 - fineX).asInt();
          int highBit = highTile.getBit(7 - fineX).asInt();

          int x = (tiles % 16) * 8 + fineX;
          int y = (tiles / 16).floor() * 8 + fineY;

          final color = [
            0xffffff, // 00 蓝色
            0xff0000, // 01 红色
            0x0000ff, // 10 黄色
            0xffffff, // 11 褐色
          ][highBit << 1 | lowBit];

          frame.setPixel(x, y, color);
        }
      }
    }
    return frame;
  }
}
