import '../bus_adapter.dart';
import '../common.dart';

class NameTableReader {
  BusAdapter bus;
  NameTableReader(this.bus);

  /// 根据id获得名称表
  /// 一个nameTable表示了32列30行个tile
  U8 getNameTableTileIndexBy(int id, int row, int col) {
    if (id < 0 || id > 4) {
      throw Exception('NameTable id must be 0, 1, 2 or 3 ,not $id');
    }
    U16 baseAddress = 0x2000 + id * 0x400;
    return bus.read(baseAddress + row * 32 + col);
  }

  /// 根据id获得属性表
  /// 一个属性表表示整个NameTable的颜色信息
  /// 64B
  /// 4x4个tile使用1B
  getAttributeTableById(int id, int row, int col) {
    if (id < 0 || id > 4) {
      throw Exception('AttributeTable id must be 0, 1, 2 or 3 ,not $id');
    }
    // NameTable address + 0x3C0
    // 0x3c0 tile == 960 tile = 32 * 30 tile = 32*8 * 30*8 pixel= 256 * 240 pixel
    U16 baseAddress = 0x23C0 + id * 0x400;
    // 先计算该tile属于哪个4x4的网格坐标
    // 16列
    int row1 = row ~/ 4;
    int col1 = col ~/ 4;
    // U8 data = bus.read(baseAddress+row1*)
  }
}
