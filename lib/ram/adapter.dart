import '../bus_adapter.dart';
import '../common.dart';
import 'ram.dart';

class RamAdapter implements BusAdapter {
  final Ram ram;

  RamAdapter(this.ram);

  @override
  bool accept(U16 address) => (0 <= address && address < 0x2000);

  @override
  U8 read(U16 address) => ram.read(address % 0x800);

  @override
  void write(U16 address, U8 value) => ram.write(address % 0x800, value);
}
