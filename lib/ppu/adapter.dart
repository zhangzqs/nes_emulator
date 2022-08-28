import '../bus_adapter.dart';
import 'ppu.dart';

class PpuAdapter implements BusAdapter {
  final Ppu ppu;
  PpuAdapter(this.ppu);

  @override
  bool accept(U16 address) => ((0x2000 <= address && address < 0x4000));

  @override
  U8 read(U16 address) => ppu.readRegister(0x2000 + address % 0x08);

  @override
  void write(U16 address, U8 value) => ppu.writeRegister(0x2000 + address % 0x08, value);
}
