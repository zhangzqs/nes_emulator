import '../common.dart';

export 'joypad.dart';

/// 暴露给外部操作的IO端口
abstract class IStandardController {
  /// CPU发送选通信号
  set regStrobe(U8 val);

  /// CPU接收按键状态
  U8 get regKeyState;
}
