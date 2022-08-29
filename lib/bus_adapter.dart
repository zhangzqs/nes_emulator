import 'common.dart';

/// 主线的从设备必须实现此接口
abstract class BusAdapter {
  /// 读取数据
  U8 read(U16 address);

  /// 写入数据
  void write(U16 address, U8 value);

  /// 判定该设备是否接受此地址
  bool accept(U16 address);
}

class FunctionalBusAdapter implements BusAdapter {
  // 收到读取请求
  final U8 Function(U16 address)? onRead;
  // 收到写入请求
  final void Function(U16 address, U8 value)? onWritten;
  // 收到是否接受请求
  final bool Function(U16 address)? onAccepted;

  FunctionalBusAdapter({this.onRead, this.onWritten, this.onAccepted});

  @override
  bool accept(U16 address) => onAccepted != null ? onAccepted!(address) : true;

  @override
  U8 read(U16 address) {
    if (onRead != null) {
      return onRead!(address);
    }
    throw UnsupportedError('cannot read address: $address');
  }

  @override
  void write(U16 address, U8 value) {
    if (onWritten != null) {
      onWritten!(address, value);
    }
    throw UnsupportedError('cannot write address: $address value: $value');
  }
}
