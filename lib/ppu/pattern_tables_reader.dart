import 'package:nes_emulator/bus_adapter.dart';
import 'package:nes_emulator/util.dart';

import '../common.dart';
import '../framebuffer.dart';

class PatternTablesReader {
  BusAdapter adapter;
  PatternTablesReader(this.adapter);

  TileFrame? _firstTileFrame, _secondTileFrame;
  TileFrame get firstTileFrame => _firstTileFrame ??= createTileFrame();
  TileFrame get secondTileFrame => _secondTileFrame ??= createTileFrame(0x1000);

  TileFrame createTileFrame([int baseAddress = 0]) {
    // https://zhuanlan.zhihu.com/p/459786029
    // 一个PatternTable = 4KB
    // 一个PatternTable 有256个tile
    // 每个tile占用4KB / 256 = 16B
    // 每个tile有8*8像素
    // 故一个像素有16B/64 = 2bit

    final frame = TileFrame();
    // 有256个tile
    for (int tiles = 0; tiles < 0x100; tiles++) {
      // 该tile的y确定的行像素
      for (int fineY = 0; fineY < 8; fineY++) {
        // 行像素为两个字节分开存储
        U8 lowTile = adapter.read(baseAddress + tiles * 8 + fineY);
        U8 highTile = adapter.read(baseAddress + tiles * 8 + fineY + 8);
        // 该tile的x像素
        for (int fineX = 0; fineX < 8; fineX++) {
          int lowBit = lowTile.getBit(7 - fineX).asInt();
          int highBit = highTile.getBit(7 - fineX).asInt();
          int colorId = highBit << 1 | lowBit;

          // 计算8*8的tile坐标在整个frame中的坐标
          int x = (tiles % 16) * 8 + fineX;
          int y = (tiles / 16).floor() * 8 + fineY;

          final color = [
            0xffffff, // 00 蓝色
            0xff0000, // 01 红色
            0x0000ff, // 10 黄色
            0xffffff, // 11 褐色
          ][colorId];

          frame.setPixel(x, y, color);
        }
      }
    }
    return frame;
  }
}
