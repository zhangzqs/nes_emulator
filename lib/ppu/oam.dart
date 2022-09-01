import '../common.dart';
import '../ram/ram.dart';
import '../util.dart';

class OamSprite {
  /// 精灵的X坐标
  U8 positionX = 0;

  /// 精灵的Y坐标
  U8 positionY = 0;

  /// 精灵使用的调色板编号
  U8 paletteId = 0;

  /// 精灵使用的图案表地址
  U16 patternTableAddress = 0;

  /// 在背景后面(true)还是前面(false)
  bool behindBackground = false;

  /// 水平翻转
  bool flipHorizontally = false;

  /// 垂直翻转
  bool flipVertically = false;
}

class OAM {
  // OAM有256个字节
  // 每个精灵需要4个字节，故共可存放64个精灵的数据结构
  final Ram data = Ram(256);

  /// 返回非公共字段byte1
  U8 setCommonField(U8 index, OamSprite sprite) {
    final offset = index * 4;
    final byte0 = data.read(offset);
    final byte1 = data.read(offset + 1);
    final byte2 = data.read(offset + 2);
    final byte3 = data.read(offset + 3);

    sprite.positionY = byte0;
    sprite.positionX = byte3;
    sprite.paletteId = byte2 & 0x03; // 0b11
    // 2,3,4位不使用
    sprite.behindBackground = byte2.getBit(5);
    sprite.flipHorizontally = byte2.getBit(6);
    sprite.flipVertically = byte2.getBit(7);
    return byte1;
  }

  OamSprite getSprite8x8(U8 index) {
    final sprite = OamSprite();
    final U8 byte1 = setCommonField(index, sprite);

    sprite.patternTableAddress = byte1 * 16;
    return sprite;
  }

  OamSprite getSprite8x16(U8 index) {
    final sprite = OamSprite();
    final U8 byte1 = setCommonField(index, sprite);

    final tileIndex = byte1 >> 1;
    sprite.patternTableAddress = (byte1 & 1) * 0x1000 + tileIndex * 32;
    return sprite;
  }
}
