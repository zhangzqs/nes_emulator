extension BitOperator on int {
  String toHex([int len = 2]) {
    return toUnsigned(16).toRadixString(16).padLeft(len, "0").toUpperCase();
  }

  int getBit(int n) => (this >> n) == 1 ? 1 : 0;
  int setBit(int n, int value) => value == 1 ? this | (1 << n) : this & (~(1 << n));
  int getZeroBit() => (this & 0xff) == 0 ? 1 : 0;
}
