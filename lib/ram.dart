import 'dart:typed_data';

import 'device.dart';

class Ram implements AddressableDevice {
  /// nes的ram大小为0x800字节, 即 8*16^2B / (1024(B/KB)) = 2KB
  final Uint8List _ramData = Uint8List(0x800);

  @override
  bool accept(U16 address) => (0 <= address && address < 0x2000);

  @override
  U8 read(U16 address) => _ramData[address % 0x800];

  @override
  void write(U16 address, U8 value) => _ramData[address % 0x800] = value;
}
