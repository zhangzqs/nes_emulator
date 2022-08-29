import '../bus_adapter.dart';
import '../common.dart';
import '../util.dart';

part 'address_mode.dart';
part 'instruction.dart';
part 'op.dart';

enum CpuInterrupt {
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

// emualtor for 6502 CPU
class CPU {
  final BusAdapter bus;

  CPU(this.bus);

  // this is registers
  // see https://en.wikipedia.org/wiki/MOS_Technology_6502#Registers
  U16 regPC = 0x0000; // Program Counter, the only 16-bit register, others are 8-bit
  U8 regSP = 0x00; // Stack Pointer register, 8-bit
  U8 regA = 0x00; // Accumulator register, 8-bit
  U8 regX = 0x00; // Index register, used for indexed addressing mode, 8-bit
  U8 regY = 0x00; // Index register, 8-bit
  FlagBit ps = FlagBit(CpuStatusFlag.values.length);

  int cycles = 0;
  int totalCycles = 0;

  late Op op; // the executing op
  int dataAddress = 0x00; // the address after address mode.
  CpuInterrupt? interrupt;

  // stack works top-down, see NESDoc page 12.
  void pushStack(U8 value) => write(0x100 + regSP--, value & 0xff);

  U8 popStack() => read(0x100 + ++regSP) & 0xff;

  void pushStack16Bit(U16 value) {
    pushStack(value >> 8);
    pushStack(value & 0xff);
  }

  U16 popStack16Bit() => popStack() | (popStack() << 8);

  U16 read16Bit(U16 address) => read(address + 1) << 8 | read(address);

  U16 read16BitUncrossPage(U16 address) {
    int nextAddress = address & 0xff00 | ((address + 1) % 0x100);
    return read(nextAddress) << 8 | read(address);
  }

  int clock() {
    if (cycles == 0) {
      handleInterrupt();

      final opcode = read(regPC);

      op = OpcodeManager.getOp(opcode);

      cycles = op.cycles;

      // addressing
      final result = op.mode.call(this);

      dataAddress = result.address;
      regPC += result.pcStepSize;

      if (result.pageCrossed && op.increaseCycleWhenCrossPage) cycles++;

      // run instruction
      op.instruction.call(this);
    }

    cycles--;
    totalCycles++;

    return 1;
  }

  /// 处理中断请求
  void handleInterrupt() {
    switch (interrupt) {
      case CpuInterrupt.nmi:
        nmi();
        break;
      case CpuInterrupt.irq:
        irq();
        break;

      case CpuInterrupt.reset:
        reset();
        break;

      default:
        return;
    }

    interrupt = null;
  }

  void nmi() {
    pushStack16Bit(regPC);
    pushStack(ps.value & 0x30);

    regPC = read16Bit(0xfffa);

    // Set the interrupt disable flag to prevent further interrupts.
    ps.set(CpuStatusFlag.interruptDisable);

    cycles = 7;
  }

  void irq() {
    // IRQ is ignored when interrupt disable flag is set.
    if (ps[CpuStatusFlag.interruptDisable]) return;

    pushStack16Bit(regPC);
    pushStack(ps.value);

    ps.set(CpuStatusFlag.interruptDisable);

    regPC = read16Bit(0xfffe);

    cycles = 7;
  }

  void reset() {
    regSP = 0xfd;
    regPC = read16Bit(0xfffc);
    ps.value = 0x24;

    cycles = 7;
  }

  // 读取总线
  U8 read(U16 address) => bus.read(address);
  // 写入总线
  void write(U16 address, U8 value) => bus.write(address, value);
}
