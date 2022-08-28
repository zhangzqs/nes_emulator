import '../device.dart';
import 'cartridge.dart';

class RomAdapter implements BusAdapter {
  final Cartridge cartridge;
  RomAdapter(this.cartridge);

  @override
  bool accept(U16 address) => (0x8000 <= address && address <= 0xFFFF);

  @override
  U8 read(U16 address) => cartridge.read(address);

  @override
  void write(U16 address, U8 value) => cartridge.write(address, value);
}
