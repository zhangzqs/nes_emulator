import 'dart:typed_data';

extension IntExtension on int {
  String toHex([int len = 2]) => toUnsigned(16).toRadixString(16).padLeft(len, "0").toUpperCase();

  bool getBit(int n) => (this >> n) & 1 == 1;

  int setBit(int n, bool value) => value ? this | (1 << n) : this & ~(1 << n);

  bool getZeroBit() => (this & 0xff) == 0;
}

extension BoolExtension on bool {
  int asInt() => this ? 1 : 0;
}

/// 通过枚举实现标志位对象
class FlagBits<T extends Enum> {
  int value;
  FlagBits(this.value);
  bool operator [](T flag) => value.getBit(flag.index);
  void operator []=(T flag, bool bit) => value = value.setBit(flag.index, bit);
  void set(T flag) => this[flag] = true;
  void reset(T flag) => this[flag] = false;
  void resetAll() => value = 0;
}

class BitSet {
  final Uint8List _data;
  final int _length;
  BitSet(int length)
      : _length = length,
        _data = Uint8List((length / 8).floor() + 1);

  Uint8List get rawData => _data;

  void set(int i) {
    int n = (i / 8).floor();
    int offset = i % 8;
    _data[n] |= 1 << offset;
  }

  void reset(int i) {
    int n = (i / 8).floor();
    int offset = i % 8;
    if (_data[n] >> offset & 1 == 1) {
      _data[n] &= ~(1 << offset);
    }
  }

  void resetAll() {
    for (int i = 0; i < _data.length; i++) {
      _data[i] = 0;
    }
  }

  bool get(int i) {
    int n = (i / 8).floor();
    int offset = i % 8;
    return _data[n] >> offset & 1 == 1;
  }

  bool operator [](int i) => get(i);
  void operator []=(int i, bool val) => val ? set(i) : reset(i);

  int get length => _length;

  BitSet operator <<(int n) {
    BitSet bs = BitSet(length);
    for (int i = 0; i < length - n; i++) {
      bs[i + n] = this[i];
    }
    return bs;
  }

  BitSet operator >>(int n) {
    BitSet bs = BitSet(length);
    for (int i = 0; i < length - n; i++) {
      bs[i] = this[i + n];
    }
    return bs;
  }

  @override
  String toString() {
    return Iterable.generate(length).map((i) => get(i).asInt()).toList().reversed.join();
  }

  BitSet subset(int start, int end) {
    BitSet bs = BitSet(end - start);
    for (int i = start; i < end; i++) {
      bs[i - start] = this[i];
    }
    return bs;
  }

  void or(BitSet bs) {
    for (int i = 0; i < bs.length; i++) {
      this[i] = this[i] || bs[i];
    }
  }

  static BitSet from(int n, int bitLength) {
    BitSet bs = BitSet(bitLength);
    for (int i = 0; i < bitLength; i++) {
      bs[i] = (n >> i) & 1 == 1;
    }
    return bs;
  }

  int toInt() {
    int num = 0;
    for (int i = 0; i < length; i++) {
      num |= (get(i).asInt() << i);
    }
    return num;
  }
}
