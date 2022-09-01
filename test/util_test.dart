import 'package:nes_emulator/util.dart';
import 'package:test/test.dart';

void main() {
  test('BitSet', () {
    BitSet bs = BitSet(10);
    expect(bs.length, 10);
    expect(bs.rawData.length, 2);
    for (int i = 0; i < 10; i++) {
      expect(bs.get(i), isFalse);
      bs.set(i);
      expect(bs.get(i), isTrue);
      bs.reset(i);
      expect(bs.get(i), isFalse);
    }
    expect(bs.toString(), '0000000000');
    bs[0] = true;
    bs[9] = true;
    expect(bs.toString(), '1000000001');
    bs = bs >> 2;
    expect(bs.toString(), '0010000000');
    bs = bs << 1;
    expect(bs.toString(), '0100000000');
    expect(bs.subset(7, 10).toInt(), 2);
  });

  test('no name', () {
    int a = 0xFEFFFFFFFFFFFFFF;
    for (int i = 0; i < 8; i++) {
      print((a & 0xff));
      a >>= 8;
    }
  });
}
