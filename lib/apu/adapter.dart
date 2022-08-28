import '../device.dart';

class ApuBusAdapter implements BusAdapter {
  @override
  bool accept(U16 address) => (0x4004 <= address && address <= 0x4007) || address == 0x4015;

  @override
  U8 read(U16 address) {
    throw UnimplementedError();
  }

  @override
  void write(U16 address, U8 value) {
    throw UnimplementedError();
  }
}
