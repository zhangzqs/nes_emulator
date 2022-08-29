import 'package:nes_emulator/ram/ram.dart';

import '../bus_adapter.dart';
import '../common.dart';

class PpuBusVideoRamAdapter implements BusAdapter {
  final Ram ram;
  PpuBusVideoRamAdapter(this.ram);

  @override
  bool accept(U16 address) {
    // TODO: implement accept
    throw UnimplementedError();
  }

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
