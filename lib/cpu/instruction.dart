part of 'cpu.dart';

// --------------------------------------------
// here is the implementation of all the instructions
class Instruction {
  Instruction(this.abbr, this.call);

  final String abbr;

  final void Function(CPU cpu) call;

  matchAbbr(String input) => bool;
}

void branchSuccess(CPU cpu) {
  cpu._remainingCycles += isPageCrossed(cpu._dataAddress, cpu.regPC + 1) ? 2 : 1;
  cpu.regPC = cpu._dataAddress;
}

final ADC = Instruction("ADC", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  int tmp = cpu.regA + fetched + cpu.regStatus[CpuStatusFlag.carry].asInt();

  // overflow is basically negative + negative = positive
  // postive + positive = negative
  cpu.regStatus[CpuStatusFlag.overflow] = (tmp ^ cpu.regA) & 0x80 != 0 && (fetched ^ tmp) & 0x80 != 0;
  cpu.regStatus[CpuStatusFlag.carry] = tmp > 0xff;
  cpu.regStatus[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = tmp.getBit(7);

  cpu.regA = tmp & 0xff;
});

final AND = Instruction("AND", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  cpu.regA &= fetched;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final ASL = Instruction("ASL", (CPU cpu) {
  int tmp = cpu._op.mode == Accumulator ? cpu.regA : cpu.readBus8Bit(cpu._dataAddress);

  cpu.regStatus[CpuStatusFlag.carry] = tmp.getBit(7);

  tmp = (tmp << 1) & 0xff;

  if (cpu._op.mode == Accumulator) {
    cpu.regA = tmp;
  } else {
    cpu.writeBus8Bit(cpu._dataAddress, tmp);
  }

  cpu.regStatus[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = tmp.getBit(7);
});

final BIT = Instruction("BIT", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  int test = fetched & cpu.regA;

  cpu.regStatus[CpuStatusFlag.zero] = test.getZeroBit();
  cpu.regStatus[CpuStatusFlag.overflow] = fetched.getBit(6);
  cpu.regStatus[CpuStatusFlag.negative] = fetched.getBit(7);
});

final BCC = Instruction("BCC", (CPU cpu) {
  if (!cpu.regStatus[CpuStatusFlag.carry]) branchSuccess(cpu);
});

final BCS = Instruction("BCS", (CPU cpu) {
  if (cpu.regStatus[CpuStatusFlag.carry]) branchSuccess(cpu);
});

final BEQ = Instruction("BEQ", (CPU cpu) {
  if (cpu.regStatus[CpuStatusFlag.zero]) branchSuccess(cpu);
});

final BMI = Instruction("BMI", (CPU cpu) {
  if (cpu.regStatus[CpuStatusFlag.negative]) branchSuccess(cpu);
});

final BNE = Instruction("BNE", (CPU cpu) {
  if (!cpu.regStatus[CpuStatusFlag.zero]) branchSuccess(cpu);
});

final BPL = Instruction("BPL", (CPU cpu) {
  if (!cpu.regStatus[CpuStatusFlag.negative]) branchSuccess(cpu);
});

final BVC = Instruction("BVC", (CPU cpu) {
  if (!cpu.regStatus[CpuStatusFlag.overflow]) branchSuccess(cpu);
});

final BVS = Instruction("BVS", (CPU cpu) {
  if (cpu.regStatus[CpuStatusFlag.overflow]) branchSuccess(cpu);
});

final BRK = Instruction("BRK", (CPU cpu) {
  cpu.pushStack16Bit(cpu.regPC + 1);
  cpu.pushStack(cpu.regStatus.value);

  cpu.regStatus[CpuStatusFlag.interruptDisable] = true;
  cpu.regStatus[CpuStatusFlag.breakCommand] = true;

  cpu.regPC = cpu.readBus16Bit(0xfffe);
});

final CLC = Instruction("CLC", (CPU cpu) => cpu.regStatus[CpuStatusFlag.carry] = false);

final CLD = Instruction(
  "CLD",
  (CPU cpu) => cpu.regStatus[CpuStatusFlag.decimalMode] = false,
);

final CLI = Instruction(
  "CLI",
  (CPU cpu) => cpu.regStatus[CpuStatusFlag.interruptDisable] = false,
);

final CLV = Instruction(
  "CLV",
  (CPU cpu) => cpu.regStatus[CpuStatusFlag.overflow] = false,
);

final CMP = Instruction("CMP", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  int tmp = cpu.regA - fetched;

  cpu.regStatus[CpuStatusFlag.carry] = tmp >= 0;
  cpu.regStatus[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = tmp.getBit(7);
});

final CPX = Instruction("CPX", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  int tmp = cpu.regX - fetched;

  cpu.regStatus[CpuStatusFlag.carry] = tmp >= 0;
  cpu.regStatus[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = tmp.getBit(7);
});

final CPY = Instruction("CPY", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  int tmp = cpu.regY - fetched;

  cpu.regStatus[CpuStatusFlag.carry] = tmp >= 0;
  cpu.regStatus[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = tmp.getBit(7);
});

final DEC = Instruction("DEC", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  fetched--;
  fetched &= 0xff;
  cpu.writeBus8Bit(cpu._dataAddress, fetched & 0xff);

  cpu.regStatus[CpuStatusFlag.zero] = fetched.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = fetched.getBit(7);
});

final DEX = Instruction("DEX", (CPU cpu) {
  cpu.regX = (cpu.regX - 1) & 0xff;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final DEY = Instruction("DEY", (CPU cpu) {
  cpu.regY = (cpu.regY - 1) & 0xff;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regY.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regY.getBit(7);
});

final EOR = Instruction("EOR", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  cpu.regA ^= fetched;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final INC = Instruction("INC", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  fetched++;
  fetched &= 0xff;

  cpu.writeBus8Bit(cpu._dataAddress, fetched & 0xff);

  cpu.regStatus[CpuStatusFlag.zero] = fetched.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = fetched.getBit(7);
});

final INX = Instruction("INX", (CPU cpu) {
  cpu.regX = (cpu.regX + 1) & 0xff;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final INY = Instruction("INY", (CPU cpu) {
  cpu.regY = (cpu.regY + 1) & 0xff;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regY.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regY.getBit(7);
});

final JMP = Instruction(
  "JMP",
  (CPU cpu) => cpu.regPC = cpu._dataAddress,
);

final JSR = Instruction("JSR", (CPU cpu) {
  cpu.pushStack16Bit(cpu.regPC - 1);
  cpu.regPC = cpu._dataAddress;
});

final LDA = Instruction("LDA", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  cpu.regA = fetched;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final LDX = Instruction("LDX", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  cpu.regX = fetched;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final LDY = Instruction("LDY", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  cpu.regY = fetched;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regY.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regY.getBit(7);
});

final LSR = Instruction("LSR", (CPU cpu) {
  int tmp = cpu._op.mode == Accumulator ? cpu.regA : cpu.readBus8Bit(cpu._dataAddress);

  cpu.regStatus[CpuStatusFlag.carry] = tmp.getBit(0);
  tmp = (tmp >> 1) & 0xff;

  if (cpu._op.mode == Accumulator) {
    cpu.regA = tmp;
  } else {
    cpu.writeBus8Bit(cpu._dataAddress, tmp);
  }

  cpu.regStatus[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = false;
});

final ORA = Instruction("ORA", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  cpu.regA |= fetched;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final PHA = Instruction(
  "PHA",
  (CPU cpu) => cpu.pushStack(cpu.regA),
);

final PHP = Instruction("PHP", (CPU cpu) {
  // with the breakCommand flag and bit 5 set to 1.
  cpu.pushStack(cpu.regStatus.value | 0x30);
});

final PLA = Instruction("PLA", (CPU cpu) {
  cpu.regA = cpu.popStack();

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final PLP = Instruction("PLP", (CPU cpu) {
  // with the breakCommand flag and bit 5 ignored.
  cpu.regStatus.value = cpu
      .popStack()
      .setBit(4, cpu.regStatus[CpuStatusFlag.breakCommand])
      .setBit(5, cpu.regStatus[CpuStatusFlag.unused]);
});

final ROL = Instruction("ROL", (CPU cpu) {
  int tmp = cpu._op.mode == Accumulator ? cpu.regA : cpu.readBus8Bit(cpu._dataAddress);

  bool oldCarry = cpu.regStatus[CpuStatusFlag.carry];

  cpu.regStatus[CpuStatusFlag.carry] = tmp.getBit(7);
  tmp = (tmp << 1) | oldCarry.asInt();

  if (cpu._op.mode == Accumulator) {
    cpu.regA = tmp & 0xff;
    cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  } else {
    cpu.writeBus8Bit(cpu._dataAddress, tmp);
  }

  cpu.regStatus[CpuStatusFlag.negative] = tmp.getBit(7);
});

final ROR = Instruction("ROR", (CPU cpu) {
  int tmp = cpu._op.mode == Accumulator ? cpu.regA : cpu.readBus8Bit(cpu._dataAddress);
  bool oldCarry = cpu.regStatus[CpuStatusFlag.carry];

  cpu.regStatus[CpuStatusFlag.carry] = tmp.getBit(0);
  tmp = (tmp >> 1).setBit(7, oldCarry);

  if (cpu._op.mode == Accumulator) {
    cpu.regA = tmp;
    cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  } else {
    cpu.writeBus8Bit(cpu._dataAddress, tmp);
  }

  cpu.regStatus[CpuStatusFlag.negative] = tmp.getBit(7);
});

final RTI = Instruction("RTI", (CPU cpu) {
  int value = cpu
      .popStack()
      .setBit(4, cpu.regStatus[CpuStatusFlag.breakCommand])
      .setBit(5, cpu.regStatus[CpuStatusFlag.unused]);
  cpu.regStatus.value = value;
  cpu.regPC = cpu.popStack16Bit();
});

final RTS = Instruction(
  "RTS",
  (CPU cpu) => cpu.regPC = cpu.popStack16Bit() + 1,
);

final SBC = Instruction("SBC", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  int tmp = cpu.regA - fetched - (1 - cpu.regStatus[CpuStatusFlag.carry].asInt());

  cpu.regStatus[CpuStatusFlag.overflow] = (tmp ^ cpu.regA) & 0x80 != 0 && (cpu.regA ^ fetched) & 0x80 != 0;
  cpu.regStatus[CpuStatusFlag.carry] = tmp >= 0;
  cpu.regStatus[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = tmp.getBit(7);

  cpu.regA = tmp & 0xff;
});

final SEC = Instruction(
  "SEC",
  (CPU cpu) => cpu.regStatus[CpuStatusFlag.carry] = true,
);

final SED = Instruction("SED", (CPU cpu) => cpu.regStatus[CpuStatusFlag.decimalMode] = true);

final SEI = Instruction("SEI", (CPU cpu) => cpu.regStatus[CpuStatusFlag.interruptDisable] = true);

final STA = Instruction("STA", (CPU cpu) => cpu.writeBus8Bit(cpu._dataAddress, cpu.regA));

final STX = Instruction("STX", (CPU cpu) => cpu.writeBus8Bit(cpu._dataAddress, cpu.regX));

final STY = Instruction("STY", (CPU cpu) => cpu.writeBus8Bit(cpu._dataAddress, cpu.regY));

final TAX = Instruction("TAX", (CPU cpu) {
  cpu.regX = cpu.regA;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final TAY = Instruction("TAY", (CPU cpu) {
  cpu.regY = cpu.regA;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regY.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regY.getBit(7);
});

final TSX = Instruction("TSX", (CPU cpu) {
  cpu.regX = cpu.regSP;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final TXA = Instruction("TXA", (CPU cpu) {
  cpu.regA = cpu.regX;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final TXS = Instruction("TXS", (CPU cpu) => cpu.regSP = cpu.regX);

final TYA = Instruction("TYA", (CPU cpu) {
  cpu.regA = cpu.regY;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final ALR = Instruction("ALR", (CPU cpu) {
  AND.call(cpu);
  LSR.call(cpu);
});

final ANC = Instruction("ANC", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  cpu.regA &= fetched;

  cpu.regStatus[CpuStatusFlag.carry] = cpu.regA.getBit(7);
  cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final ARR = Instruction("ARR", (CPU cpu) {
  AND.call(cpu);
  ROR.call(cpu);
});

final AXS = Instruction("AXS", (CPU cpu) {
  cpu.regX &= cpu.regA;

  cpu.regStatus[CpuStatusFlag.carry] = false;
  cpu.regStatus[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final LAX = Instruction("LAX", (CPU cpu) {
  int fetched = cpu.readBus8Bit(cpu._dataAddress);
  cpu.regX = cpu.regA = fetched;

  cpu.regStatus[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.regStatus[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final SAX = Instruction("SAX", (CPU cpu) {
  cpu.writeBus8Bit(cpu._dataAddress, cpu.regX & cpu.regA);
});

final DCP = Instruction("DCP", (CPU cpu) {
  DEC.call(cpu);
  CMP.call(cpu);
});

final ISC = Instruction("ISC", (CPU cpu) {
  INC.call(cpu);
  SBC.call(cpu);
});

final RLA = Instruction("RLA", (CPU cpu) {
  ROL.call(cpu);
  AND.call(cpu);
});

final RRA = Instruction("RRA", (CPU cpu) {
  ROR.call(cpu);
  ADC.call(cpu);
});

final SLO = Instruction("SLO", (CPU cpu) {
  ASL.call(cpu);
  ORA.call(cpu);
});

final SRE = Instruction("SRE", (CPU cpu) {
  LSR.call(cpu);
  EOR.call(cpu);
});

// NOPs
final NOP = Instruction("NOP", (CPU cpu) {});

final SKB = Instruction("SKB", (CPU cpu) {});

final IGN = Instruction("IGN", (CPU cpu) {});
