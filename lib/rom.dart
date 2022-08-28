import 'device.dart';

class Rom implements AddressableDevice {
  @override
  bool accept(U16 address) => (0x8000 <= address && address <= 0xFFFF);

  @override
  U8 read(U16 address) {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  void write(U16 address, U8 value) {
    // TODO: implement write
  }
}
