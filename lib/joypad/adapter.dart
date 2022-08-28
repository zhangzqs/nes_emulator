import '../bus_adapter.dart';

class JoyPadAdapter implements BusAdapter {
  @override
  bool accept(U16 address) => (0x4016 <= address && address < 0x4018);

  @override
  U8 read(U16 address) => 0;

  @override
  void write(U16 address, U8 value) {}
}
