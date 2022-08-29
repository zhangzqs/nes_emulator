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
class FlagBit<T extends Enum> {
  int value;
  FlagBit(this.value);
  bool operator [](T flag) => value.getBit(flag.index);
  void operator []=(T flag, bool bit) => value = value.setBit(flag.index, bit);
  void set(T flag) => this[flag] = true;
  void reset(T flag) => this[flag] = false;
  void resetAll() => value = 0;
}
