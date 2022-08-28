import 'package:nes/ppu/my_ppu.dart';

import '../common.dart';
import '../device.dart';

class Ppu implements AddressableDevice {
  final MyPPU _ppu;
  Ppu({
    required AddressableDevice bus,
    required AddressableDevice card,
    required Mirroring mirroring,
    required VoidCallback onNmiInterrupted,
    required void Function(int increased) onCycleChanged,
  }) : _ppu = MyPPU(
          bus: bus,
          card: card,
          mirroring: mirroring,
          onNmiInterrupted: onNmiInterrupted,
          onCycleChanged: onCycleChanged,
        );

  @override
  bool accept(U16 address) => ((0x2000 <= address && address < 0x4000) || address == 0x4014);

  @override
  U8 read(U16 address) => _ppu.readRegister(address);

  @override
  void write(U16 address, U8 value) => _ppu.writeRegister(address, value);
}
