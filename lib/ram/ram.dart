import 'dart:typed_data';

import '../common.dart';

class Ram {
  final Uint8List _ramData;

  Ram(int size) : _ramData = Uint8List(size);

  U8 read(U16 address) => _ramData[address];

  void write(U16 address, U8 value) => _ramData[address] = value;

  U8 operator [](U16 address) => read(address);
  void operator []=(U16 address, U8 value) => write(address, value);

  void reset() {
    for (int i = 0; i < _ramData.length; i++) {
      _ramData[i] = 0;
    }
  }
}
