import 'dart:typed_data';

import '../common.dart';
import '../util.dart';

class NesFileReader {
  static const U16 _prgBankSize = 0x4000;
  static const U16 _chrBankSize = 0x2000;
  static const U16 _trainerSize = 0x0200;

  final Uint8List bytes;
  NesFileReader(this.bytes) {
    if (!isValid) {
      throw UnsupportedError('Error nes file content!!!');
    }
  }

  /// 文件是否有效
  bool get isValid => bytes[0] == 0x4e && bytes[1] == 0x45 && bytes[2] == 0x53 && bytes[3] == 0x1a;

  /// 程序指令块数量
  int get prgBanks => bytes[4];

  /// 图案点阵块数量
  int get chrBanks => bytes[5];

  Mirroring get mirroring {
    final isVerticalMirror = bytes[6].getBit(0);
    final fourScreen = bytes[6].getBit(3);
    if (fourScreen) return Mirroring.fourScreen;
    return isVerticalMirror ? Mirroring.vertical : Mirroring.horizontal;
  }

  bool get hasBatteryBacked => bytes[6].getBit(1);
  bool get hasTrainer => bytes[6].getBit(2);

  U8 get mapperId {
    U8 lowerMapperId = bytes[6] & 0xf0;
    U8 upperMapperId = bytes[7] & 0xf0;
    return upperMapperId | lowerMapperId >> 4;
  }

  Uint8List get prgRom => bytes.sublist(_prgRomStart, _prgRomStart + prgBanks * _prgBankSize);

  Uint8List get chrRom => bytes.sublist(_chrRomStart, _chrRomStart + chrBanks * _chrBankSize);

  Uint8List get trainerRom {
    if (!hasTrainer) {
      throw UnsupportedError('nes file is not support to get trainer rom');
    }
    return bytes.sublist(0x10, 0x10 + _trainerSize);
  }

  int get _prgRomStart => 0x10 + (hasTrainer ? _trainerSize : 0);

  int get _chrRomStart => _prgRomStart + prgBanks * _prgBankSize;
}
