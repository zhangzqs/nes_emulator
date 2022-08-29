part of 'cpu.dart';

class Op {
  final int opcode;

  final Instruction instruction;
  final AddressMode mode;
  final int cycles;
  final bool increaseCycleWhenCrossPage;

  Op(this.opcode, this.instruction, this.mode, this.cycles, [this.increaseCycleWhenCrossPage = false]);
}

class OpcodeManager {
  static final Map<U8, List<dynamic>> _opArgsTable = {
    0x69: [ADC, Immediate, 2],
    0x65: [ADC, ZeroPage, 3],
    0x75: [ADC, ZeroPageX, 4],
    0x6d: [ADC, Absolute, 4],
    0x7d: [ADC, AbsoluteX, 4, true],
    0x79: [ADC, AbsoluteY, 4, true],
    0x61: [ADC, IndexedIndirect, 6],
    0x71: [ADC, IndirectIndexed, 5, true],
    0x29: [AND, Immediate, 2],
    0x25: [AND, ZeroPage, 3],
    0x35: [AND, ZeroPageX, 4],
    0x2d: [AND, Absolute, 4],
    0x3d: [AND, AbsoluteX, 4, true],
    0x39: [AND, AbsoluteY, 4, true],
    0x21: [AND, IndexedIndirect, 6],
    0x31: [AND, IndirectIndexed, 5, true],
    0x0a: [ASL, Accumulator, 2],
    0x06: [ASL, ZeroPage, 5],
    0x16: [ASL, ZeroPageX, 6],
    0x0e: [ASL, Absolute, 6],
    0x1e: [ASL, AbsoluteX, 7],
    0x90: [BCC, Relative, 2, true],
    0xb0: [BCS, Relative, 2, true],
    0xf0: [BEQ, Relative, 2, true],
    0x24: [BIT, ZeroPage, 3],
    0x2c: [BIT, Absolute, 4],
    0x30: [BMI, Relative, 2, true],
    0xd0: [BNE, Relative, 2, true],
    0x10: [BPL, Relative, 2, true],
    0x00: [BRK, Implied, 7],
    0x50: [BVC, Relative, 2, true],
    0x70: [BVS, Relative, 2, true],
    0x18: [CLC, Implied, 2],
    0xd8: [CLD, Implied, 2],
    0x58: [CLI, Implied, 2],
    0xb8: [CLV, Implied, 2],
    0xc9: [CMP, Immediate, 2],
    0xc5: [CMP, ZeroPage, 3],
    0xd5: [CMP, ZeroPageX, 4],
    0xcd: [CMP, Absolute, 4],
    0xdd: [CMP, AbsoluteX, 4, true],
    0xd9: [CMP, AbsoluteY, 4, true],
    0xc1: [CMP, IndexedIndirect, 6, true],
    0xd1: [CMP, IndirectIndexed, 5, true],
    0xe0: [CPX, Immediate, 2],
    0xe4: [CPX, ZeroPage, 3],
    0xec: [CPX, Absolute, 4],
    0xc0: [CPY, Immediate, 2],
    0xc4: [CPY, ZeroPage, 3],
    0xcc: [CPY, Absolute, 4],
    0xc6: [DEC, ZeroPage, 5],
    0xd6: [DEC, ZeroPageX, 6],
    0xce: [DEC, Absolute, 6],
    0xde: [DEC, AbsoluteX, 7],
    0xca: [DEX, Implied, 2],
    0x88: [DEY, Implied, 2],
    0x49: [EOR, Immediate, 2],
    0x45: [EOR, ZeroPage, 3],
    0x55: [EOR, ZeroPageX, 4],
    0x4d: [EOR, Absolute, 4],
    0x5d: [EOR, AbsoluteX, 4, true],
    0x59: [EOR, AbsoluteY, 4, true],
    0x41: [EOR, IndexedIndirect, 6],
    0x51: [EOR, IndirectIndexed, 5, true],
    0xe6: [INC, ZeroPage, 5],
    0xf6: [INC, ZeroPageX, 6],
    0xee: [INC, Absolute, 6],
    0xfe: [INC, AbsoluteX, 7],
    0xe8: [INX, Implied, 2],
    0xc8: [INY, Implied, 2],
    0x4c: [JMP, Absolute, 3],
    0x6c: [JMP, Indirect, 5],
    0x20: [JSR, Absolute, 6],
    0xa9: [LDA, Immediate, 2],
    0xa5: [LDA, ZeroPage, 3],
    0xb5: [LDA, ZeroPageX, 4],
    0xad: [LDA, Absolute, 4],
    0xbd: [LDA, AbsoluteX, 4, true],
    0xb9: [LDA, AbsoluteY, 4, true],
    0xa1: [LDA, IndexedIndirect, 6],
    0xb1: [LDA, IndirectIndexed, 5, true],
    0xa2: [LDX, Immediate, 2],
    0xa6: [LDX, ZeroPage, 3],
    0xb6: [LDX, ZeroPageY, 4],
    0xae: [LDX, Absolute, 4],
    0xbe: [LDX, AbsoluteY, 4, true],
    0xa0: [LDY, Immediate, 2],
    0xa4: [LDY, ZeroPage, 3],
    0xb4: [LDY, ZeroPageX, 4],
    0xac: [LDY, Absolute, 4],
    0xbc: [LDY, AbsoluteX, 4, true],
    0x4a: [LSR, Accumulator, 2],
    0x46: [LSR, ZeroPage, 5],
    0x56: [LSR, ZeroPageX, 6],
    0x4e: [LSR, Absolute, 6],
    0x5e: [LSR, AbsoluteX, 7],
    0x1a: [NOP, Implied, 2],
    0x3a: [NOP, Implied, 2],
    0x5a: [NOP, Implied, 2],
    0x7a: [NOP, Implied, 2],
    0xda: [NOP, Implied, 2],
    0xea: [NOP, Implied, 2],
    0xfa: [NOP, Implied, 2],
    0x09: [ORA, Immediate, 2],
    0x05: [ORA, ZeroPage, 3],
    0x15: [ORA, ZeroPageX, 4],
    0x0d: [ORA, Absolute, 4],
    0x1d: [ORA, AbsoluteX, 4, true],
    0x19: [ORA, AbsoluteY, 4, true],
    0x01: [ORA, IndexedIndirect, 6],
    0x11: [ORA, IndirectIndexed, 5, true],
    0x48: [PHA, Implied, 3],
    0x08: [PHP, Implied, 3],
    0x68: [PLA, Implied, 4],
    0x28: [PLP, Implied, 4],
    0x2a: [ROL, Accumulator, 2],
    0x26: [ROL, ZeroPage, 5],
    0x36: [ROL, ZeroPageX, 6],
    0x2e: [ROL, Absolute, 6],
    0x3e: [ROL, AbsoluteX, 7],
    0x6a: [ROR, Accumulator, 2],
    0x66: [ROR, ZeroPage, 5],
    0x76: [ROR, ZeroPageX, 6],
    0x6e: [ROR, Absolute, 6],
    0x7e: [ROR, AbsoluteX, 7],
    0x40: [RTI, Implied, 6],
    0x60: [RTS, Implied, 6],
    0xeb: [SBC, Immediate, 2],
    0xe9: [SBC, Immediate, 2],
    0xe5: [SBC, ZeroPage, 3],
    0xf5: [SBC, ZeroPageX, 4],
    0xed: [SBC, Absolute, 4],
    0xfd: [SBC, AbsoluteX, 4, true],
    0xf9: [SBC, AbsoluteY, 4, true],
    0xe1: [SBC, IndexedIndirect, 6],
    0xf1: [SBC, IndirectIndexed, 5, true],
    0x38: [SEC, Implied, 2],
    0xf8: [SED, Implied, 2],
    0x78: [SEI, Implied, 2],
    0x85: [STA, ZeroPage, 3],
    0x95: [STA, ZeroPageX, 4],
    0x8d: [STA, Absolute, 4],
    0x9d: [STA, AbsoluteX, 5],
    0x99: [STA, AbsoluteY, 5],
    0x81: [STA, IndexedIndirect, 6],
    0x91: [STA, IndirectIndexed, 6],
    0x86: [STX, ZeroPage, 3],
    0x96: [STX, ZeroPageY, 4],
    0x8e: [STX, Absolute, 4],
    0x84: [STY, ZeroPage, 3],
    0x94: [STY, ZeroPageX, 4],
    0x8c: [STY, Absolute, 4],
    0xaa: [TAX, Implied, 2],
    0xa8: [TAY, Implied, 2],
    0xba: [TSX, Implied, 2],
    0x8a: [TXA, Implied, 2],
    0x9a: [TXS, Implied, 2],
    0x98: [TYA, Implied, 2],
    0x4b: [ALR, Immediate, 2],
    0x0b: [ANC, Immediate, 2],
    0x2b: [ANC, Immediate, 2],
    0x6b: [ARR, Immediate, 2],
    0xcb: [AXS, Immediate, 2],
    0xa7: [LAX, ZeroPage, 3],
    0xb7: [LAX, ZeroPageY, 4],
    0xaf: [LAX, Absolute, 4],
    0xbf: [LAX, AbsoluteY, 4, true],
    0xa3: [LAX, IndexedIndirect, 6],
    0xb3: [LAX, IndirectIndexed, 5, true],
    0x87: [SAX, ZeroPage, 3],
    0x97: [SAX, ZeroPageY, 4],
    0x8f: [SAX, Absolute, 4],
    0x83: [SAX, IndexedIndirect, 6, true],
    0xc7: [DCP, ZeroPage, 5],
    0xd7: [DCP, ZeroPageX, 6],
    0xcf: [DCP, Absolute, 6],
    0xdf: [DCP, AbsoluteX, 7],
    0xdb: [DCP, AbsoluteY, 7],
    0xc3: [DCP, IndexedIndirect, 8],
    0xd3: [DCP, IndirectIndexed, 8],
    0xe7: [ISC, ZeroPage, 5],
    0xf7: [ISC, ZeroPageX, 6],
    0xef: [ISC, Absolute, 6],
    0xff: [ISC, AbsoluteX, 7],
    0xfb: [ISC, AbsoluteY, 7],
    0xe3: [ISC, IndexedIndirect, 8],
    0xf3: [ISC, IndirectIndexed, 8],
    0x27: [RLA, ZeroPage, 5],
    0x37: [RLA, ZeroPageX, 6],
    0x2f: [RLA, Absolute, 6],
    0x3f: [RLA, AbsoluteX, 7],
    0x3b: [RLA, AbsoluteY, 7],
    0x23: [RLA, IndexedIndirect, 8],
    0x33: [RLA, IndirectIndexed, 8],
    0x67: [RRA, ZeroPage, 5],
    0x77: [RRA, ZeroPageX, 6],
    0x6f: [RRA, Absolute, 6],
    0x7f: [RRA, AbsoluteX, 7],
    0x7b: [RRA, AbsoluteY, 7],
    0x63: [RRA, IndexedIndirect, 8],
    0x73: [RRA, IndirectIndexed, 8],
    0x07: [SLO, ZeroPage, 5],
    0x17: [SLO, ZeroPageX, 6],
    0x0f: [SLO, Absolute, 6],
    0x1f: [SLO, AbsoluteX, 7],
    0x1b: [SLO, AbsoluteY, 7],
    0x03: [SLO, IndexedIndirect, 8],
    0x13: [SLO, IndirectIndexed, 8],
    0x47: [SRE, ZeroPage, 5],
    0x57: [SRE, ZeroPageX, 6],
    0x4f: [SRE, Absolute, 6],
    0x5f: [SRE, AbsoluteX, 7],
    0x5b: [SRE, AbsoluteY, 7],
    0x43: [SRE, IndexedIndirect, 8],
    0x53: [SRE, IndirectIndexed, 8],
    0x80: [SKB, Immediate, 2],
    0x82: [SKB, Immediate, 2],
    0x89: [SKB, Immediate, 2],
    0xc2: [SKB, Immediate, 2],
    0xe2: [SKB, Immediate, 2],
    0x0c: [IGN, Absolute, 4],
    0x1c: [IGN, AbsoluteX, 4, true],
    0x3c: [IGN, AbsoluteX, 4, true],
    0x5c: [IGN, AbsoluteX, 4, true],
    0x7c: [IGN, AbsoluteX, 4, true],
    0xdc: [IGN, AbsoluteX, 4, true],
    0xfc: [IGN, AbsoluteX, 4, true],
    0x04: [IGN, ZeroPage, 3],
    0x44: [IGN, ZeroPage, 3],
    0x64: [IGN, ZeroPage, 3],
    0x14: [IGN, ZeroPageX, 4],
    0x34: [IGN, ZeroPageX, 4],
    0x54: [IGN, ZeroPageX, 4],
    0x74: [IGN, ZeroPageX, 4],
    0xd4: [IGN, ZeroPageX, 4],
    0xf4: [IGN, ZeroPageX, 4],
  };

  static final List<Op?> _opTable = List<Op?>.filled(256, null);

  static Op getOp(U8 opcode) {
    if (_opTable[opcode] != null) return _opTable[opcode]!;

    List<dynamic>? opArgs = _opArgsTable[opcode];
    if (opArgs == null) throw "unknow opcode ${opcode.toHex()}";

    _opTable[opcode] = Op(opcode, opArgs[0], opArgs[1], opArgs[2], opArgs.length == 4 ? opArgs[3] : false);
    return _opTable[opcode]!;
  }
}
