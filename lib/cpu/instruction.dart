part of 'cpu.dart';

// --------------------------------------------
// here is the implementation of all the instructions
class Instruction {
  Instruction(this.abbr, this.call);

  final String abbr;

  final void Function(CPU cpu) call;

  matchAbbr(String input) => bool;
}

branchSuccess(CPU cpu) {
  cpu.cycles += isPageCrossed(cpu.dataAddress, cpu.regPC + 1) ? 2 : 1;
  cpu.regPC = cpu.dataAddress;
}

final ADC = Instruction("ADC", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  int tmp = cpu.regA + fetched + cpu.ps[CpuStatusFlag.carry].asInt();

  // overflow is basically negative + negative = positive
  // postive + positive = negative
  cpu.ps[CpuStatusFlag.overflow] = (tmp ^ cpu.regA) & 0x80 != 0 && (fetched ^ tmp) & 0x80 != 0;
  cpu.ps[CpuStatusFlag.carry] = tmp > 0xff;
  cpu.ps[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = tmp.getBit(7);

  cpu.regA = tmp & 0xff;
});

final AND = Instruction("AND", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  cpu.regA &= fetched;

  cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final ASL = Instruction("ASL", (CPU cpu) {
  int tmp = cpu.op.mode == Accumulator ? cpu.regA : cpu.read(cpu.dataAddress);

  cpu.ps[CpuStatusFlag.carry] = tmp.getBit(7);

  tmp = (tmp << 1) & 0xff;

  if (cpu.op.mode == Accumulator) {
    cpu.regA = tmp;
  } else {
    cpu.write(cpu.dataAddress, tmp);
  }

  cpu.ps[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = tmp.getBit(7);
});

final BIT = Instruction("BIT", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  int test = fetched & cpu.regA;

  cpu.ps[CpuStatusFlag.zero] = test.getZeroBit();
  cpu.ps[CpuStatusFlag.overflow] = fetched.getBit(6);
  cpu.ps[CpuStatusFlag.negative] = fetched.getBit(7);
});

final BCC = Instruction("BCC", (CPU cpu) {
  if (!cpu.ps[CpuStatusFlag.carry]) branchSuccess(cpu);
});

final BCS = Instruction("BCS", (CPU cpu) {
  if (cpu.ps[CpuStatusFlag.carry]) branchSuccess(cpu);
});

final BEQ = Instruction("BEQ", (CPU cpu) {
  if (cpu.ps[CpuStatusFlag.zero]) branchSuccess(cpu);
});

final BMI = Instruction("BMI", (CPU cpu) {
  if (cpu.ps[CpuStatusFlag.negative]) branchSuccess(cpu);
});

final BNE = Instruction("BNE", (CPU cpu) {
  if (!cpu.ps[CpuStatusFlag.zero]) branchSuccess(cpu);
});

final BPL = Instruction("BPL", (CPU cpu) {
  if (!cpu.ps[CpuStatusFlag.negative]) branchSuccess(cpu);
});

final BVC = Instruction("BVC", (CPU cpu) {
  if (!cpu.ps[CpuStatusFlag.overflow]) branchSuccess(cpu);
});

final BVS = Instruction("BVS", (CPU cpu) {
  if (cpu.ps[CpuStatusFlag.overflow]) branchSuccess(cpu);
});

final BRK = Instruction("BRK", (CPU cpu) {
  cpu.pushStack16Bit(cpu.regPC + 1);
  cpu.pushStack(cpu.ps.value);

  cpu.ps[CpuStatusFlag.interruptDisable] = true;
  cpu.ps[CpuStatusFlag.breakCommand] = true;

  cpu.regPC = cpu.read16Bit(0xfffe);
});

final CLC = Instruction("CLC", (CPU cpu) => cpu.ps[CpuStatusFlag.carry] = false);

final CLD = Instruction(
  "CLD",
  (CPU cpu) => cpu.ps[CpuStatusFlag.decimalMode] = false,
);

final CLI = Instruction(
  "CLI",
  (CPU cpu) => cpu.ps[CpuStatusFlag.interruptDisable] = false,
);

final CLV = Instruction(
  "CLV",
  (CPU cpu) => cpu.ps[CpuStatusFlag.overflow] = false,
);

final CMP = Instruction("CMP", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  int tmp = cpu.regA - fetched;

  cpu.ps[CpuStatusFlag.carry] = tmp >= 0;
  cpu.ps[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = tmp.getBit(7);
});

final CPX = Instruction("CPX", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  int tmp = cpu.regX - fetched;

  cpu.ps[CpuStatusFlag.carry] = tmp >= 0;
  cpu.ps[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = tmp.getBit(7);
});

final CPY = Instruction("CPY", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  int tmp = cpu.regY - fetched;

  cpu.ps[CpuStatusFlag.carry] = tmp >= 0;
  cpu.ps[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = tmp.getBit(7);
});

final DEC = Instruction("DEC", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  fetched--;
  fetched &= 0xff;
  cpu.write(cpu.dataAddress, fetched & 0xff);

  cpu.ps[CpuStatusFlag.zero] = fetched.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = fetched.getBit(7);
});

final DEX = Instruction("DEX", (CPU cpu) {
  cpu.regX = (cpu.regX - 1) & 0xff;

  cpu.ps[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final DEY = Instruction("DEY", (CPU cpu) {
  cpu.regY = (cpu.regY - 1) & 0xff;

  cpu.ps[CpuStatusFlag.zero] = cpu.regY.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regY.getBit(7);
});

final EOR = Instruction("EOR", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  cpu.regA ^= fetched;

  cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final INC = Instruction("INC", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  fetched++;
  fetched &= 0xff;

  cpu.write(cpu.dataAddress, fetched & 0xff);

  cpu.ps[CpuStatusFlag.zero] = fetched.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = fetched.getBit(7);
});

final INX = Instruction("INX", (CPU cpu) {
  cpu.regX = (cpu.regX + 1) & 0xff;

  cpu.ps[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final INY = Instruction("INY", (CPU cpu) {
  cpu.regY = (cpu.regY + 1) & 0xff;

  cpu.ps[CpuStatusFlag.zero] = cpu.regY.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regY.getBit(7);
});

final JMP = Instruction(
  "JMP",
  (CPU cpu) => cpu.regPC = cpu.dataAddress,
);

final JSR = Instruction("JSR", (CPU cpu) {
  cpu.pushStack16Bit(cpu.regPC - 1);
  cpu.regPC = cpu.dataAddress;
});

final LDA = Instruction("LDA", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  cpu.regA = fetched;

  cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final LDX = Instruction("LDX", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  cpu.regX = fetched;

  cpu.ps[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final LDY = Instruction("LDY", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  cpu.regY = fetched;

  cpu.ps[CpuStatusFlag.zero] = cpu.regY.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regY.getBit(7);
});

final LSR = Instruction("LSR", (CPU cpu) {
  int tmp = cpu.op.mode == Accumulator ? cpu.regA : cpu.read(cpu.dataAddress);

  cpu.ps[CpuStatusFlag.carry] = tmp.getBit(0);
  tmp = (tmp >> 1) & 0xff;

  if (cpu.op.mode == Accumulator) {
    cpu.regA = tmp;
  } else {
    cpu.write(cpu.dataAddress, tmp);
  }

  cpu.ps[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = false;
});

final ORA = Instruction("ORA", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  cpu.regA |= fetched;

  cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final PHA = Instruction(
  "PHA",
  (CPU cpu) => cpu.pushStack(cpu.regA),
);

final PHP = Instruction("PHP", (CPU cpu) {
  // with the breakCommand flag and bit 5 set to 1.
  cpu.pushStack(cpu.ps.value | 0x30);
});

final PLA = Instruction("PLA", (CPU cpu) {
  cpu.regA = cpu.popStack();

  cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final PLP = Instruction("PLP", (CPU cpu) {
  // with the breakCommand flag and bit 5 ignored.
  cpu.ps.value = cpu.popStack().setBit(4, cpu.ps[CpuStatusFlag.breakCommand]).setBit(5, cpu.ps[CpuStatusFlag.unused]);
});

final ROL = Instruction("ROL", (CPU cpu) {
  int tmp = cpu.op.mode == Accumulator ? cpu.regA : cpu.read(cpu.dataAddress);

  bool oldCarry = cpu.ps[CpuStatusFlag.carry];

  cpu.ps[CpuStatusFlag.carry] = tmp.getBit(7);
  tmp = (tmp << 1) | oldCarry.asInt();

  if (cpu.op.mode == Accumulator) {
    cpu.regA = tmp & 0xff;
    cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  } else {
    cpu.write(cpu.dataAddress, tmp);
  }

  cpu.ps[CpuStatusFlag.negative] = tmp.getBit(7);
});

final ROR = Instruction("ROR", (CPU cpu) {
  int tmp = cpu.op.mode == Accumulator ? cpu.regA : cpu.read(cpu.dataAddress);
  bool oldCarry = cpu.ps[CpuStatusFlag.carry];

  cpu.ps[CpuStatusFlag.carry] = tmp.getBit(0);
  tmp = (tmp >> 1).setBit(7, oldCarry);

  if (cpu.op.mode == Accumulator) {
    cpu.regA = tmp;
    cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  } else {
    cpu.write(cpu.dataAddress, tmp);
  }

  cpu.ps[CpuStatusFlag.negative] = tmp.getBit(7);
});

final RTI = Instruction("RTI", (CPU cpu) {
  int value = cpu.popStack().setBit(4, cpu.ps[CpuStatusFlag.breakCommand]).setBit(5, cpu.ps[CpuStatusFlag.unused]);
  cpu.ps.value = value;
  cpu.regPC = cpu.popStack16Bit();
});

final RTS = Instruction(
  "RTS",
  (CPU cpu) => cpu.regPC = cpu.popStack16Bit() + 1,
);

final SBC = Instruction("SBC", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  int tmp = cpu.regA - fetched - (1 - cpu.ps[CpuStatusFlag.carry].asInt());

  cpu.ps[CpuStatusFlag.overflow] = (tmp ^ cpu.regA) & 0x80 != 0 && (cpu.regA ^ fetched) & 0x80 != 0;
  cpu.ps[CpuStatusFlag.carry] = tmp >= 0;
  cpu.ps[CpuStatusFlag.zero] = tmp.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = tmp.getBit(7);

  cpu.regA = tmp & 0xff;
});

final SEC = Instruction(
  "SEC",
  (CPU cpu) => cpu.ps[CpuStatusFlag.carry] = true,
);

final SED = Instruction("SED", (CPU cpu) => cpu.ps[CpuStatusFlag.decimalMode] = true);

final SEI = Instruction("SEI", (CPU cpu) => cpu.ps[CpuStatusFlag.interruptDisable] = true);

final STA = Instruction("STA", (CPU cpu) => cpu.write(cpu.dataAddress, cpu.regA));

final STX = Instruction("STX", (CPU cpu) => cpu.write(cpu.dataAddress, cpu.regX));

final STY = Instruction("STY", (CPU cpu) => cpu.write(cpu.dataAddress, cpu.regY));

final TAX = Instruction("TAX", (CPU cpu) {
  cpu.regX = cpu.regA;

  cpu.ps[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final TAY = Instruction("TAY", (CPU cpu) {
  cpu.regY = cpu.regA;

  cpu.ps[CpuStatusFlag.zero] = cpu.regY.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regY.getBit(7);
});

final TSX = Instruction("TSX", (CPU cpu) {
  cpu.regX = cpu.regSP;

  cpu.ps[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final TXA = Instruction("TXA", (CPU cpu) {
  cpu.regA = cpu.regX;

  cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final TXS = Instruction("TXS", (CPU cpu) => cpu.regSP = cpu.regX);

final TYA = Instruction("TYA", (CPU cpu) {
  cpu.regA = cpu.regY;

  cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final ALR = Instruction("ALR", (CPU cpu) {
  AND.call(cpu);
  LSR.call(cpu);
});

final ANC = Instruction("ANC", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  cpu.regA &= fetched;

  cpu.ps[CpuStatusFlag.carry] = cpu.regA.getBit(7);
  cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final ARR = Instruction("ARR", (CPU cpu) {
  AND.call(cpu);
  ROR.call(cpu);
});

final AXS = Instruction("AXS", (CPU cpu) {
  cpu.regX &= cpu.regA;

  cpu.ps[CpuStatusFlag.carry] = false;
  cpu.ps[CpuStatusFlag.zero] = cpu.regX.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regX.getBit(7);
});

final LAX = Instruction("LAX", (CPU cpu) {
  int fetched = cpu.read(cpu.dataAddress);
  cpu.regX = cpu.regA = fetched;

  cpu.ps[CpuStatusFlag.zero] = cpu.regA.getZeroBit();
  cpu.ps[CpuStatusFlag.negative] = cpu.regA.getBit(7);
});

final SAX = Instruction("SAX", (CPU cpu) {
  cpu.write(cpu.dataAddress, cpu.regX & cpu.regA);
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
