import '../device.dart';

class JoyPadAdapter implements BusAdapter {
  @override
  bool accept(U16 address) => (0x4016 <= address && address < 0x4018);

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
