import '../common.dart';

/// Ppu暴露给Cpu的8个寄存器io端口
/// https://www.nesdev.org/wiki/PPU_registers
abstract class IPpu {
  /// Controller ($2000) > write
  set regController(U8 val);

  /// Mask ($2001) > write
  set regMask(U8 val);

  /// Status ($2002) < read
  U8 get regStatus;

  /// OAM address ($2003) > write
  set regOamAddress(U8 val);

  /// OAM data ($2004) <> read/write
  U8 get regOamData;
  set regOamData(U8 val);

  /// Scroll ($2005) >> write x2
  set regScroll(U8 val);

  /// Address ($2006) >> write x2
  set regAddress(U8 val);

  /// Data ($2007) <> read/write
  U8 get regData;
  set regData(U8 val);

  /// 外部提供复位信号
  void reset();

  /// 外部提供时钟信号
  void clock();

  /// 获取当前总帧数
  int get totalFrames;
}
