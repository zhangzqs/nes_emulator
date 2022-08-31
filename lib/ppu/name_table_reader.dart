import '../bus_adapter.dart';
import '../common.dart';

class NameTableReader {
  BusAdapter adapter;
  NameTableReader(this.adapter);

  /// 根据id获得名称表
  getNameTableById(int id) {
    if (id < 0 || id > 4) {
      throw Exception('NameTable id must be 0, 1, 2 or 3 ,not $id');
    }
    // 0. 0x2000
    // 1. 0x2400
    // 2. 0x2800
    // 3. 0x2c00
    U16 baseAddress = 0x2000 + id * 0x400;
  }

  getAttributeTableById(int id) {
    // NameTable address + 0x3C0
    // 0x3c0 tile == 960 tile = 32 * 30 tile = 32*8 * 30*8 pixel= 256 * 240 pixel
    U16 baseAddress = 0x23C0 + id * 0x400;
  }
}
