import 'package:nes_emulator/dma/dma.dart';

import '../bus_adapter.dart';
import '../common.dart';
import '../util.dart';

part 'address_mode.dart';
part 'instruction.dart';
part 'op.dart';

enum CpuInterruptSignal {
  nmi,
  irq,
  reset,
}

enum CpuStatusFlag {
  carry,
  zero,
  interruptDisable,
  decimalMode,
  breakCommand,
  unused,
  overflow,
  negative,
}

class CPU {
  /// cpu总线
  final BusAdapter bus;

  CPU({required this.bus});

  // this is registers
  // see https://en.wikipedia.org/wiki/MOS_Technology_6502#Registers
  U16 regPC = 0x0000; // Program Counter, the only 16-bit register, others are 8-bit
  U8 regSP = 0x00; // Stack Pointer register, 8-bit
  U8 regA = 0x00; // Accumulator register, 8-bit
  U8 regX = 0x00; // Index register, used for indexed addressing mode, 8-bit
  U8 regY = 0x00; // Index register, 8-bit
  FlagBits regStatus = FlagBits(CpuStatusFlag.values.length);

  /// cpu运行的总周期数
  int totalCycles = 0;

  /// 执行当前指令剩余的时钟周期数
  int _remainingCycles = 0;

  late Op _op; // 要执行的指令
  late int _dataAddress; // 目标操作数地址

  void waitDma() {}
  // stack works top-down, see NESDoc page 12.
  void pushStack(U8 value) => writeBus8Bit(0x100 + regSP--, value & 0xff);

  U8 popStack() => readBus8Bit(0x100 + ++regSP) & 0xff;

  void pushStack16Bit(U16 value) {
    pushStack(value >> 8);
    pushStack(value & 0xff);
  }

  U16 popStack16Bit() => popStack() | (popStack() << 8);

  CpuInterruptSignal? _interrupt;

  /// 判断当前CPU是否处于执行周期
  bool isRunningInstruction() => _remainingCycles != 0;

  /// cpu允许一个周期
  void runOneClock() {
    // 上一条指令还没执行完毕
    if (_remainingCycles > 0) {
      _remainingCycles--;
      totalCycles++;
      return;
    }
    // 上一条指令执行周期结束，进入中断周期，检查是否有中断需要处理
    if (_interrupt != null) {
      handleInterrupt(_interrupt!); // 处理中断请求
      _interrupt = null; // 清除中断信号
    }

    final opcode = readBus8Bit(regPC); // 读指令操作码

    _op = OpcodeManager.getOp(opcode); // 读指令

    _remainingCycles = _op.cycles; // 当前指令需要执行的周期数

    final result = _op.mode.call(this);

    _dataAddress = result.address; // 指令操作数地址
    regPC += result.pcStepSize; // 更新pc

    // 如果指令产生跨页，那么需要额外增加一个时钟周期
    if (result.pageCrossed && _op.increaseCycleWhenCrossPage) _remainingCycles++;

    // 执行指令
    _op.instruction.call(this);
  }

  /// 发送中断信号
  void sendInterruptSignal(CpuInterruptSignal signal) => _interrupt = signal;

  /// 处理中断请求
  void handleInterrupt(CpuInterruptSignal signal) {
    switch (signal) {
      case CpuInterruptSignal.nmi:
        nmi();
        break;
      case CpuInterruptSignal.irq:
        irq();
        break;

      case CpuInterruptSignal.reset:
        reset();
        break;
    }
  }

  /// NMI中断
  void nmi() {
    pushStack16Bit(regPC);
    pushStack(regStatus.value & 0x30);

    regPC = readBus16Bit(0xfffa);

    // Set the interrupt disable flag to prevent further interrupts.
    regStatus.set(CpuStatusFlag.interruptDisable);

    _remainingCycles = 7;
  }

  /// IRQ中断
  void irq() {
    // IRQ is ignored when interrupt disable flag is set.
    if (regStatus[CpuStatusFlag.interruptDisable]) return;

    pushStack16Bit(regPC);
    pushStack(regStatus.value);

    regStatus.set(CpuStatusFlag.interruptDisable);

    regPC = readBus16Bit(0xfffe);

    _remainingCycles = 7;
  }

  /// RESET中断
  void reset() {
    regSP = 0xfd;
    regPC = readBus16Bit(0xfffc);
    regStatus.value = 0x24;

    _remainingCycles = 7;
  }

  /// 读取总线
  U8 readBus8Bit(U16 address) {
    if (address == 0x4014) {
      print('dma read');
    }
    return bus.read(address);
  }

  /// 写入总线
  void writeBus8Bit(U16 address, U8 value) {
    if (address == 0x4014) {
      print('dma write');
    }
    bus.write(address, value);
  }

  U16 readBus16Bit(U16 address) => readBus8Bit(address + 1) << 8 | readBus8Bit(address);

  U16 readBus16BitUncrossPage(U16 address) {
    int nextAddress = address & 0xFF00 | ((address + 1) & 0xFF);
    return readBus8Bit(nextAddress) << 8 | readBus8Bit(address);
  }

  BusAdapter getDmaControllerAdapter({
    required DmaController dmaController,
    required int targetPage,
  }) {
    return DmaControllerAdapter(this, dmaController, targetPage);
  }
}

/// 该控制器已集成到cpu内部
class DmaControllerAdapter implements BusAdapter {
  final CPU cpu;
  final DmaController dmaController;
  final U8 targetPage;
  DmaControllerAdapter(this.cpu, this.dmaController, this.targetPage);

  @override
  bool accept(U16 address) {
    if (address == 0x4014) {
      print('dma');
    }
    return address == 0x4014;
  }

  @override
  U8 read(U16 address) => throw UnsupportedError('DMA controller cannot be read');

  @override
  void write(U16 address, U8 value) {
    // 启动DMA传输
    final page = cpu.readBus8Bit(value); // 获得页号
    // 开始拷贝
    dmaController.transferPage(page, targetPage);
    // 写入完毕需要更新剩余周期数, 之前的总周期若为奇数则等待513周期，偶数为514
    cpu._remainingCycles += 513 + (cpu.totalCycles % 2);
  }
}
