import '../bus_adapter.dart';
import '../common.dart';

class ApuBusAdapter implements BusAdapter {
  @override
  bool accept(U16 address) => (0x4000 <= address && address < 0x4020);

  @override
  U8 read(U16 address) => 0;

  @override
  void write(U16 address, U8 value) {}
}
