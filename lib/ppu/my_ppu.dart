library nesbox.ppu;

import 'dart:typed_data';

import 'package:nes_emulator/ppu/palettes.dart';
import 'package:nes_emulator/ram/ram.dart';

import '../bus_adapter.dart';
import '../common.dart';
import '../framebuffer.dart';
import 'abstruct_ppu.dart';

class MyPpu implements IPpu {
  /// nmi中断信号
  final VoidCallback onNmiInterrupted;

  /// 游戏卡带
  final BusAdapter bus;

  MyPpu({
    required this.bus,
    required this.onNmiInterrupted,
  }) {
    reset();
  }

  final _oam = Ram(256);
  FrameBuffer _front = FrameBuffer(width: 256, height: 240);
  FrameBuffer get front => _front;
  FrameBuffer _back = FrameBuffer(width: 256, height: 240);
  FrameBuffer get back => _back;

  int _cycle = 340;
  int get cycle => _cycle;

  int _scanLine = 240;
  int get scanLine => _scanLine;

  int _frame = 0;
  @override
  int get totalFrames => _frame;

  /// PPU registers
  U8 _x = 0; // fine x scroll (3 bit)
  U8 _w = 0; // write toggle (1 bit)
  U8 _f = 0; // even/odd frame flag (1 bit)
  U16 _v = 0; // current vram address (15 bit)
  U16 _t = 0; // temporary vram address (15 bit)

  /// cpu write
  U8 _register = 0;

  /// NMI flags
  bool _nmiOccurred = false;
  bool _nmiPrevious = false;
  U8 _nmiDelay = 0;

  /// background temporary variables
  U8 _nameTableByte = 0;
  U8 _attributeTableByte = 0;
  U8 _lowTileByte = 0;
  U8 _highTileByte = 0;
  int _tileData = 0;

  void normalize() {
    _x &= 0xFF;
    _w &= 0xFF;
    _f &= 0xFF;
    _v &= 0xFFFF;
    _t &= 0xFFFF;
    _register &= 0xFF;
    _nmiDelay &= 0xFF;
    _nameTableByte &= 0xFF;
    _attributeTableByte &= 0xFF;
    _lowTileByte &= 0xFF;
    _highTileByte &= 0xFF;
  }

  /// sprite temporary variables
  int _spriteCount = 0;
  final Uint32List _spritePatterns = Uint32List(8);
  final Uint8List _spritePositions = Uint8List(8);
  final Uint8List _spritePriorities = Uint8List(8);
  final Uint8List _spriteIndexes = Uint8List(8);

  /// $2000 PPUCTRL
  // $2000 PPUCTRL
  U8 flagNameTable = 0; // 0: $2000; 1: $2400; 2: $2800; 3: $2C00
  U8 flagIncrement = 0; // 0: add 1; 1: add 32
  U8 flagSpriteTable = 0; // 0: $0000; 1: $1000; ignored in 8x16 mode
  U8 flagBackgroundTable = 0; // 0: $0000; 1: $1000
  U8 flagSpriteSize = 0; // 0: 8x8; 1: 8x16
  U8 flagMasterSlave = 0; // 0: read EXT; 1: write EXT
  bool nmiOutput = false;
  // $2001 PPUMASK
  U8 flagGrayscale = 0; // 0: color; 1: grayscale
  U8 flagShowLeftBackground = 0; // 0: hide; 1: show
  U8 flagShowLeftSprites = 0; // 0: hide; 1: show
  U8 flagShowBackground = 0; // 0: hide; 1: show
  U8 flagShowSprites = 0; // 0: hide; 1: show
  U8 flagRedTint = 0; // 0: normal; 1: emphasized
  U8 flagGreenTint = 0; // 0: normal; 1: emphasized
  U8 flagBlueTint = 0; // 0: normal; 1: emphasized

  // $2002 PPUSTATUS
  U8 flagSpriteZeroHit = 0;
  U8 flagSpriteOverflow = 0;

  /// $2003 OAMADDR
  int _oamAddress = 0;

  /// $2007 PPUDATA
  U8 _bufferedData = 0;

  int get backgroundColor => nesSysPalettes[_readPalette(0) % 64];

  @override
  void reset() {
    _cycle = 340;
    _scanLine = 240;
    _frame = 0;
    regController = 0;
    regMask = 0;
    regOamAddress = 0;
  }

  /// 读取调色板
  /// address取值为0<=address<=31
  U8 _readPalette(U16 address) {
    // 调色板有32字节组成，有8个子调色板
    // 前4个调色板供背景使用，后四个调色板供精灵使用
    // 每个子调色板有4种颜色，每个颜色由一字节索引组成
    // 即4*8 = 32字节

    // 如果是精灵的调色板且命中0号颜色
    // 没搞懂
    // https://github.com/fogleman/nes/blob/master/nes/ppu.go#L195
    if (address >= 16 && address % 4 == 0) {
      address -= 16;
    }
    return bus.read(0x3F00 + address);
  }

  /// 写入调色板
  void _writePalette(U16 address, U8 value) {
    if (address >= 16 && address % 4 == 0) {
      address -= 16;
    }
    return bus.write(0x3F00 + address, value);
  }

  /// control 寄存器被写入
  @override
  set regController(U8 value) {
    // https://github.com/fogleman/nes/blob/master/nes/ppu.go#L243
    _register = value;
    flagNameTable = (value >> 0) & 3;
    flagIncrement = (value >> 2) & 1;
    flagSpriteTable = (value >> 3) & 1;
    flagBackgroundTable = (value >> 4) & 1;
    flagSpriteSize = (value >> 5) & 1;
    flagMasterSlave = (value >> 6) & 1;
    nmiOutput = (value >> 7) & 1 == 1;
    nmiChange();
    // t: ....BA.. ........ = d: ......BA
    _t = (_t & 0xF3FF) | ((value & 0x03) << 10);
  }

  @override
  set regMask(U8 value) {
    _register = value;
    flagGrayscale = (value >> 0) & 1;
    flagShowLeftBackground = (value >> 1) & 1;
    flagShowLeftSprites = (value >> 2) & 1;
    flagShowBackground = (value >> 3) & 1;
    flagShowSprites = (value >> 4) & 1;
    flagRedTint = (value >> 5) & 1;
    flagGreenTint = (value >> 6) & 1;
    flagBlueTint = (value >> 7) & 1;
  }

  @override
  U8 get regStatus {
    var result = _register & 0x1F;
    result |= flagSpriteOverflow << 5;
    result |= flagSpriteZeroHit << 6;
    if (_nmiOccurred) {
      result |= 1 << 7;
    }
    _nmiOccurred = false;
    nmiChange();
    // w:                   = 0
    _w = 0;
    return result;
  }

  @override
  set regOamAddress(U8 val) {
    _register = val;
    _oamAddress = val;
  }

  @override
  U8 get regOamData {
    var data = _oam[_oamAddress];
    if ((_oamAddress & 0x03) == 0x02) {
      data = data & 0xE3;
    }
    return data;
  }

  @override
  set regOamData(U8 oamData) {
    _register = oamData;
    _oam[_oamAddress] = oamData;
    _oamAddress++;
  }

  @override
  set regScroll(U8 value) {
    // https://github.com/fogleman/nes/blob/master/nes/ppu.go#L304
    _register = value;
    if (_w == 0) {
      // t: ........ ...HGFED = d: HGFED...
      // x:               CBA = d: .....CBA
      // w:                   = 1
      _t = (_t & 0xFFE0) | (value >> 3);
      _x = value & 0x07;
      _w = 1;
    } else {
      // t: .CBA..HG FED..... = d: HGFEDCBA
      // w:                   = 0
      _t = (_t & 0x8FFF) | ((value & 0x07) << 12);
      _t = (_t & 0xFC1F) | ((value & 0xF8) << 2);
      _w = 0;
    }
  }

  @override
  set regAddress(U8 value) {
    _register = value;

    if (_w == 0) {
      // t: ..FEDCBA ........ = d: ..FEDCBA
      // t: .X...... ........ = 0
      // w:                   = 1
      _t = (_t & 0x80FF) | ((value & 0x3F) << 8);
      _w = 1;
    } else {
      // t: ........ HGFEDCBA = d: HGFEDCBA
      // v                    = t
      // w:                   = 0
      _t = (_t & 0xFF00) | value;
      _v = _t;
      _w = 0;
    }
  }

  @override
  U8 get regData {
    U8 value = bus.read(_v);
    // emulate buffered reads
    if (_v % 0x4000 < 0x3F00) {
      final buffered = _bufferedData;
      _bufferedData = value;
      value = buffered;
    } else {
      _bufferedData = bus.read(_v - 0x1000);
    }
    // increment address
    if (flagIncrement == 0) {
      _v += 1;
    } else {
      _v += 32;
    }
    return value;
  }

  @override
  set regData(U8 value) {
    _register = value;
    bus.write(_v, value);
    // increment address
    if (flagIncrement == 0) {
      _v += 1;
    } else {
      _v += 32;
    }
  }

  // NTSC Timing Helper Functions
  void incrementX() {
    // increment hori(v)
    // if coarse X == 31
    if (_v & 0x001F == 31) {
      // coarse X = 0
      _v &= 0xFFE0;
      // switch horizontal nametable
      _v ^= 0x0400;
    } else {
      // increment coarse X
      _v++;
    }
  }

  void incrementY() {
    // increment vert(v)
    // if fine Y < 7
    if (_v & 0x7000 != 0x7000) {
      // increment fine Y
      _v += 0x1000;
    } else {
      // fine Y = 0
      _v &= 0x8FFF;
      // let y = coarse Y
      int y = (_v & 0x03E0) >> 5;
      if (y == 29) {
        // coarse Y = 0
        y = 0;
        // switch vertical nametable
        _v ^= 0x0800;
      } else if (y == 31) {
        // coarse Y = 0, nametable not switched
        y = 0;
      } else {
        // increment coarse Y
        y++;
      }
      // put coarse Y back into v
      _v = (_v & 0xFC1F) | (y << 5);
    }
  }

  void copyX() {
    // hori(v) = hori(t)
    // v: .....F.. ...EDCBA = t: .....F.. ...EDCBA
    _v = (_v & 0xFBE0) | (_t & 0x041F);
  }

  void copyY() {
    // vert(v) = vert(t)
    // v: .IHGF.ED CBA..... = t: .IHGF.ED CBA.....
    _v = (_v & 0x841F) | (_t & 0x7BE0);
  }

  void nmiChange() {
    final nmi = nmiOutput && _nmiOccurred;
    if (nmi && !_nmiPrevious) {
      // TODO: this fixes some games but the delay shouldn't have to be so
      // long, so the timings are off somewhere
      _nmiDelay = 15;
    }
    _nmiPrevious = nmi;
  }

  void setVerticalBlank() {
    final tmp = _front;
    _front = _back;
    _back = tmp;

    _nmiOccurred = true;
    nmiChange();
  }

  void clearVerticalBlank() {
    _nmiOccurred = false;
    nmiChange();
  }

  void fetchNameTableByte() {
    final v = _v;
    final address = 0x2000 | (v & 0x0FFF);
    _nameTableByte = bus.read(address);
  }

  void fetchAttributeTableByte() {
    final v = _v;
    final address = 0x23C0 | (v & 0x0C00) | ((v >> 4) & 0x38) | ((v >> 2) & 0x07);
    final shift = ((v >> 4) & 4) | (v & 2);
    _attributeTableByte = ((bus.read(address) >> shift) & 3) << 2;
  }

  void fetchLowTileByte() {
    final fineY = (_v >> 12) & 7;
    final table = flagBackgroundTable;
    final tile = _nameTableByte;
    final address = 0x1000 * table + tile * 16 + fineY;
    _lowTileByte = bus.read(address);
  }

  fetchHighTileByte() {
    final fineY = (_v >> 12) & 7;
    final table = flagBackgroundTable;

    final tile = _nameTableByte;
    final address = 0x1000 * table + tile * 16 + fineY;
    _highTileByte = bus.read(address);
  }

  void storeTileData() {
    int data = 0;
    for (int i = 0; i < 8; i++) {
      final a = _attributeTableByte;
      final p1 = (_lowTileByte & 0x80) >> 7;
      final p2 = (_highTileByte & 0x80) >> 6;
      _lowTileByte <<= 1;
      _highTileByte <<= 1;
      data <<= 4;
      data |= (a | p1 | p2);
    }
    _tileData |= data;
  }

  int fetchTileData() {
    return _tileData >> 32;
  }

  U8 backgroundPixel() {
    if (flagShowBackground == 0) {
      return 0;
    }
    final data = fetchTileData() >> ((7 - _x) * 4);
    return data & 0x0F;
  }

  List<U8> spritePixel() {
    if (flagShowSprites == 0) {
      return [0, 0];
    }

    for (int i = 0; i < _spriteCount; i++) {
      int offset = (_cycle - 1) - _spritePositions[i];
      if (offset < 0 || offset > 7) {
        continue;
      }
      offset = 7 - offset;
      final color = (_spritePatterns[i] >> offset * 4) & 0x0F;
      if (color % 4 == 0) {
        continue;
      }
      return [i, color];
    }
    return [0, 0];
  }

  void renderPixel() {
    final x = _cycle - 1;
    final y = _scanLine;
    U8 background = backgroundPixel();

    final sp = spritePixel();
    final i = sp[0];
    U8 sprite = sp[1];

    if (x < 8 && flagShowLeftBackground == 0) {
      background = 0;
    }
    if (x < 8 && flagShowLeftSprites == 0) {
      sprite = 0;
    }
    final b = background % 4 != 0;
    final s = sprite % 4 != 0;
    U8 color = 0;
    if (!b && !s) {
      color = 0;
    } else if (!b && s) {
      color = sprite | 0x10;
    } else if (b && !s) {
      color = background;
    } else {
      if (_spriteIndexes[i] == 0 && x < 255) {
        flagSpriteZeroHit = 1;
      }
      if (_spritePriorities[i] == 0) {
        color = sprite | 0x10;
      } else {
        color = background;
      }
    }
    // https://github.com/fogleman/nes/blob/master/nes/ppu.go#L565
    final c = nesSysPalettes[_readPalette(color) % 64];
    _back.setPixel(x, y, c);
    // print(c);
  }

  int fetchSpritePattern(int i, int row) {
    U8 tile = _oam[i * 4 + 1];
    U8 attributes = _oam[i * 4 + 2];
    U16 address = 0;

    if (flagSpriteSize == 0) {
      if (attributes & 0x80 == 0x80) {
        row = 7 - row;
      }
      final table = flagSpriteTable;
      address = 0x1000 * table + tile * 16 + row;
    } else {
      if (attributes & 0x80 == 0x80) {
        row = 15 - row;
      }
      final table = tile & 1;
      tile &= 0xFE;
      if (row > 7) {
        tile++;
        row -= 8;
      }
      address = 0x1000 * table + tile * 16 + row;
    }
    final a = (attributes & 3) << 2;
    U8 lowTileByte = bus.read(address);
    U8 highTileByte = bus.read(address + 8);
    int data = 0;
    for (int i = 0; i < 8; i++) {
      U8 p1 = 0, p2 = 0;
      if (attributes & 0x40 == 0x40) {
        p1 = (lowTileByte & 1) << 0;
        p2 = (highTileByte & 1) << 1;
        lowTileByte >>= 1;
        highTileByte >>= 1;
      } else {
        p1 = (lowTileByte & 0x80) >> 7;
        p2 = (highTileByte & 0x80) >> 6;
        lowTileByte <<= 1;
        highTileByte <<= 1;
      }
      data <<= 4;
      data |= a | p1 | p2;
    }
    return data;
  }

  void evaluateSprites() {
    int h = 0;
    if (flagSpriteSize == 0) {
      h = 8;
    } else {
      h = 16;
    }
    int count = 0;
    for (int i = 0; i < 64; i++) {
      final y = _oam[i * 4 + 0];
      final a = _oam[i * 4 + 2];
      final x = _oam[i * 4 + 3];
      final row = _scanLine - y;
      if (row < 0 || row >= h) {
        continue;
      }
      if (count < 8) {
        _spritePatterns[count] = fetchSpritePattern(i, row);
        _spritePositions[count] = x;
        _spritePriorities[count] = (a >> 5) & 1;
        _spriteIndexes[count] = i;
      }
      count++;
    }
    if (count > 8) {
      count = 8;
      flagSpriteOverflow = 1;
    }
    _spriteCount = count;
  }

  void tick() {
    normalize();
    if (_nmiDelay > 0) {
      _nmiDelay--;
      if (_nmiDelay == 0 && nmiOutput && _nmiOccurred) {
        onNmiInterrupted();
      }
    }

    if (flagShowBackground != 0 || flagShowSprites != 0) {
      if (_f == 1 && _scanLine == 261 && cycle == 339) {
        _cycle = 0;
        _scanLine = 0;
        _frame++;
        _f ^= 1;
        return;
      }
    }
    _cycle++;
    if (_cycle > 340) {
      _cycle = 0;
      _scanLine++;
      if (_scanLine > 261) {
        _scanLine = 0;
        _frame++;
        _f ^= 1;
      }
    }
  }

  @override
  void clock() {
    tick();

    final renderingEnabled = flagShowBackground != 0 || flagShowSprites != 0;
    final preLine = _scanLine == 261;
    final visibleLine = _scanLine < 240;
    final postLine = _scanLine == 240;
    final renderLine = preLine || visibleLine;
    final preFetchCycle = _cycle >= 321 && _cycle <= 336;
    final visibleCycle = _cycle >= 1 && _cycle <= 256;
    final fetchCycle = preFetchCycle || visibleCycle;

    // background logic
    if (renderingEnabled) {
      if (visibleLine && visibleCycle) {
        renderPixel();
      }
      if (renderLine && fetchCycle) {
        _tileData <<= 4;
        switch (_cycle % 8) {
          case 1:
            fetchNameTableByte();
            break;
          case 3:
            fetchAttributeTableByte();
            break;

          case 5:
            fetchLowTileByte();
            break;

          case 7:
            fetchHighTileByte();
            break;

          case 0:
            storeTileData();
            break;
        }
      }
      if (preLine && _cycle >= 280 && _cycle <= 304) {
        copyY();
      }
      if (renderLine) {
        if (fetchCycle && _cycle % 8 == 0) {
          incrementX();
        }
        if (_cycle == 256) {
          incrementY();
        }
        if (_cycle == 257) {
          copyX();
        }
      }
    }

    // sprite logic
    if (renderingEnabled) {
      if (_cycle == 257) {
        if (visibleLine) {
          evaluateSprites();
        } else {
          _spriteCount = 0;
        }
      }
    }

    // vblank logic
    if (_scanLine == 241 && _cycle == 1) {
      setVerticalBlank();
    }
    if (preLine && _cycle == 1) {
      clearVerticalBlank();
      flagSpriteZeroHit = 0;
      flagSpriteOverflow = 0;
    }
  }

  @override
  FrameBuffer get frameBuffer => _front;
}
