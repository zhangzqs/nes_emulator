import 'dart:typed_data';

import '../device.dart';

class Ram {
  final Uint8List _ramData;

  Ram(int size) : _ramData = Uint8List(size);

  U8 read(U16 address) => _ramData[address];

  void write(U16 address, U8 value) => _ramData[address] = value;
}
