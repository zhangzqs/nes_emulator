typedef U8 = int;
typedef U16 = int;

/// 主线的从设备必须实现此接口
abstract class AddressableDevice {
  /// 读取数据
  U8 read(U16 address);

  /// 写入数据
  void write(U16 address, U8 value);

  /// 判定该设备是否接受此地址
  bool accept(U16 address);
}
