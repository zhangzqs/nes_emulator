import 'dart:convert';
import 'dart:typed_data';

import '../common.dart';

/// PPU内部的NES调色板, 记录了整个NES系统所有可用的颜色
/// 共64个颜色

typedef Color = int;

extension ColorMethod on Color {
  U8 getR() => (this >> 16) & 0xFF;
  U8 getG() => (this >> 8) & 0xFF;
  U8 getB() => this & 0xFF;
}

class NesPalettes {
  final Uint8List data;
  NesPalettes(this.data);
  Color readColor(U8 index) {
    U8 r = data[index * 3];
    U8 g = data[index * 3 + 1];
    U8 b = data[index * 3 + 2];
    return r << 16 | g << 8 | b;
  }

  Color operator [](U8 index) => readColor(index);
}

const String a =
    'dHR0JBiMAACoRACcjAB0qAAQpAAAfAgAQCwAAEQAAFAAADwUGDxcAAAAAAAAAAAAvLy8AHDsIDjsgADwvAC85ABY2CgAyEwMiHAAAJQAAKgAAJA4AICIAAAAAAAAAAAA/Pz8PLz8XJT8zIj89Hj8/HS0/HRg/Jg48Lw8gNAQTNxIWPiYAOjYeHh4AAAAAAAA/Pz8qOT8xNT81Mj8/MT8/MTY/Lyw/Nio/OSg4PygqPC8sPzMnPzwxMTEAAAAAAAA';

final nesSysPalettes = NesPalettes(base64Decode(a));
