import '../device.dart';
import 'ppu.dart';

class PpuAdapter implements BusAdapter {
  final Ppu ppu;
  PpuAdapter(this.ppu);

  @override
  bool accept(U16 address) => ((0x2000 <= address && address < 0x4000) || address == 0x4014);

  @override
  U8 read(U16 address) => ppu.readRegister(address);

  @override
  void write(U16 address, U8 value) => ppu.writeRegister(address, value);
}
