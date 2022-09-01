import 'dart:core';
import 'dart:typed_data';

import '../bus_adapter.dart';
import '../common.dart';
import '../framebuffer.dart';
import '../ram/ram.dart';
import 'abstruct_ppu.dart';
import 'palettes.dart';

class PpuImpl {
  final VoidCallback onNmiInterrupted;
  final BusAdapter bus;

  PpuImpl({
    required this.bus,
    required this.onNmiInterrupted,
  }) {
    reset();
  }

  int cycle = 0; // 0-340
  int scanLine = 0; // 0-261, 0-239=visible, 240=post, 241-260=vblank, 261=pre
  int frame = 0; // frame counter

  // storage variables
  // paletteData   [32]
  // nameTableData [2048]
  final oamData = Ram(256);
  var front = FrameBuffer();
  var back = FrameBuffer();

  // PPU registers
  int v = 0; // current vram address (15 bit)
  int t = 0; // temporary vram address (15 bit)
  U8 x = 0; // fine x scroll (3 bit)
  U8 w = 0; // write toggle (1 bit)
  U8 f = 0; // even/odd frame flag (1 bit)

  U8 register = 0;

  // NMI flags
  bool nmiOccurred = false;
  bool nmiOutput = false;
  bool nmiPrevious = false;
  U8 nmiDelay = 0;

  // background temporary variables
  U8 nameTableByte = 0;
  U8 attributeTableByte = 0;
  U8 lowTileByte = 0;
  U8 highTileByte = 0;
  int tileData = 0;

  // sprite temporary variables
  int spriteCount = 0;
  final spritePatterns = Uint32List(8);
  final spritePositions = Uint8List(8);
  final spritePriorities = Uint8List(8);
  final spriteIndexes = Uint8List(8);

  // $2000 PPUCTRL
  U8 flagNameTable = 0; // 0: $2000; 1: $2400; 2: $2800; 3: $2C00
  U8 flagIncrement = 0; // 0: add 1; 1: add 32
  U8 flagSpriteTable = 0; // 0: $0000; 1: $1000; ignored in 8x16 mode
  U8 flagBackgroundTable = 0; // 0: $0000; 1: $1000
  U8 flagSpriteSize = 0; // 0: 8x8; 1: 8x16
  U8 flagMasterSlave = 0; // 0: read EXT; 1: write EXT

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

  // $2003 OAMADDR
  U8 oamAddress = 0;

  // $2007 PPUDATA
  U8 bufferedData = 0; // for buffered reads

  void reset() {
    cycle = 340;
    scanLine = 240;
    frame = 0;
    writeControl(0);
    writeMask(0);
    writeOAMAddress(0);
  }

  U8 readPalette(U16 address) {
    return bus.read(0x3F00 + address);
  }

  void writeControl(value) {
    flagNameTable = (value >> 0) & 3;
    flagIncrement = (value >> 2) & 1;
    flagSpriteTable = (value >> 3) & 1;
    flagBackgroundTable = (value >> 4) & 1;
    flagSpriteSize = (value >> 5) & 1;
    flagMasterSlave = (value >> 6) & 1;
    nmiOutput = (value >> 7) & 1 == 1;
    nmiChange();
    // t: ....BA.. ........ = d: ......BA
    t = (t & 0xF3FF) | ((value & 0x03) << 10);
  }

  void writeMask(value) {
    flagGrayscale = (value >> 0) & 1;
    flagShowLeftBackground = (value >> 1) & 1;
    flagShowLeftSprites = (value >> 2) & 1;
    flagShowBackground = (value >> 3) & 1;
    flagShowSprites = (value >> 4) & 1;
    flagRedTint = (value >> 5) & 1;
    flagGreenTint = (value >> 6) & 1;
    flagBlueTint = (value >> 7) & 1;
  }

  U8 readStatus() {
    var result = register & 0x1F;
    result |= flagSpriteOverflow << 5;
    result |= flagSpriteZeroHit << 6;
    if (nmiOccurred) {
      result |= 1 << 7;
    }
    nmiOccurred = false;
    nmiChange();
// w:                   = 0
    w = 0;
    return result;
  }

  void writeOAMAddress(value) {
    oamAddress = value;
  }

  U8 readOAMData() {
    var data = oamData[oamAddress];
    if ((oamAddress & 0x03) == 0x02) {
      data = data & 0xE3;
    }
    return data;
  }

  void writeOAMData(value) {
    oamData[oamAddress] = value;
    oamAddress++;
    oamAddress &= 0xff;
  }

  void writeScroll(value) {
    if (w == 0) {
      // t: ........ ...HGFED = d: HGFED...
      // x:               CBA = d: .....CBA
      // w:                   = 1
      t = (t & 0xFFE0) | ((value) >> 3);
      x = value & 0x07;
      w = 1;
    } else {
      // t: .CBA..HG FED..... = d: HGFEDCBA
      // w:                   = 0
      t = (t & 0x8FFF) | (((value) & 0x07) << 12);
      t = (t & 0xFC1F) | (((value) & 0xF8) << 2);
      w = 0;
    }
  }

  void writeAddress(value) {
    if (w == 0) {
      // t: ..FEDCBA ........ = d: ..FEDCBA
      // t: .X...... ........ = 0
      // w:                   = 1
      t = (t & 0x80FF) | (((value) & 0x3F) << 8);
      w = 1;
    } else {
      // t: ........ HGFEDCBA = d: HGFEDCBA
      // v                    = t
      // w:                   = 0
      t = (t & 0xFF00) | (value);
      v = t;
      w = 0;
    }
  }

  U8 readPpuBus(U16 address) => bus.read(address);
  void writePpuBus(U16 address, U8 value) => bus.write(address, value);

  U8 readData() {
    var value = readPpuBus(v);
    // emulate buffered reads
    if (v % 0x4000 < 0x3F00) {
      var buffered = bufferedData;
      bufferedData = value;
      value = buffered;
    } else {
      bufferedData = readPpuBus(v - 0x1000);
    }
    // increment address
    if (flagIncrement == 0) {
      v += 1;
    } else {
      v += 32;
    }
    return value;
  }

  void writeData(value) {
    writePpuBus(v, value);
    if (flagIncrement == 0) {
      v += 1;
    } else {
      v += 32;
    }
  }

  void incrementX() {
    // increment hori(v)
    // if coarse X == 31
    if (v & 0x001F == 31) {
      // coarse X = 0
      v &= 0xFFE0;
      // switch horizontal nametable
      v ^= 0x0400;
    } else {
      // increment coarse X
      v++;
    }
  }

  void incrementY() {
    // increment vert(v)
    // if fine Y < 7
    if (v & 0x7000 != 0x7000) {
      // increment fine Y
      v += 0x1000;
    } else {
      // fine Y = 0
      v &= 0x8FFF;
      // let y = coarse Y
      var y = (v & 0x03E0) >> 5;
      if (y == 29) {
        // coarse Y = 0
        y = 0;
        // switch vertical nametable
        v ^= 0x0800;
      } else if (y == 31) {
        // coarse Y = 0, nametable not switched
        y = 0;
      } else {
        // increment coarse Y
        y++;
      }
      // put coarse Y back into v
      v = (v & 0xFC1F) | (y << 5);
    }
  }

  void copyX() {
    // hori(v) = hori(t)
    // v: .....F.. ...EDCBA = t: .....F.. ...EDCBA
    v = (v & 0xFBE0) | (t & 0x041F);
  }

  void copyY() {
    // vert(v) = vert(t)
    // v: .IHGF.ED CBA..... = t: .IHGF.ED CBA.....
    v = (v & 0x841F) | (t & 0x7BE0);
  }

  void nmiChange() {
    var nmi = nmiOutput && nmiOccurred;
    if (nmi && !nmiPrevious) {
      // TODO: this fixes some games but the delay shouldn't have to be so
      // long, so the timings are off somewhere
      nmiDelay = 15;
    }
    nmiPrevious = nmi;
  }

  void setVerticalBlank() {
    var tmp = front;
    front = back;
    back = tmp;

    nmiOccurred = true;
    nmiChange();
  }

  void clearVerticalBlank() {
    nmiOccurred = false;
    nmiChange();
  }

  void fetchNameTableByte() {
    final address = 0x2000 | (v & 0x0FFF);
    nameTableByte = readPpuBus(address);
  }

  void fetchAttributeTableByte() {
    final address = 0x23C0 | (v & 0x0C00) | ((v >> 4) & 0x38) | ((v >> 2) & 0x07);
    final shift = ((v >> 4) & 4) | (v & 2);
    attributeTableByte = ((readPpuBus(address) >> shift) & 3) << 2;
  }

  void fetchLowTileByte() {
    final fineY = (v >> 12) & 7;
    final table = flagBackgroundTable;
    final tile = nameTableByte;
    final address = 0x1000 * (table) + (tile) * 16 + fineY;
    lowTileByte = readPpuBus(address);
  }

  void fetchHighTileByte() {
    final fineY = (v >> 12) & 7;
    final table = flagBackgroundTable;
    final tile = nameTableByte;
    final address = 0x1000 * (table) + (tile) * 16 + fineY;
    highTileByte = readPpuBus(address + 8);
  }

  void storeTileData() {
    int data = 0;
    for (int i = 0; i < 8; i++) {
      var a = attributeTableByte;
      var p1 = (lowTileByte & 0x80) >> 7;
      var p2 = (highTileByte & 0x80) >> 6;
      lowTileByte <<= 1;
      highTileByte <<= 1;
      data <<= 4;
      data |= (a | p1 | p2);
    }
    tileData |= data;
  }

  int fetchTileData() {
    return (tileData >> 32);
  }

  int backgroundPixel() {
    if (flagShowBackground == 0) {
      return 0;
    }
    var data = fetchTileData() >> ((7 - x) * 4);
    return (data & 0x0F);
  }

  List<int> spritePixel() {
    if (flagShowSprites == 0) {
      return [0, 0];
    }
    for (int i = 0; i < spriteCount; i++) {
      var offset = (cycle - 1) - (spritePositions[i]);
      if (offset < 0 || offset > 7) {
        continue;
      }
      offset = 7 - offset;
      final color = ((spritePatterns[i] >> (offset * 4)) & 0x0F);
      if (color % 4 == 0) {
        continue;
      }
      return [(i), color];
    }
    return [0, 0];
  }

  renderPixel() {
    final x = cycle - 1;
    final y = scanLine;
    var background = backgroundPixel();
    final li = spritePixel();
    final i = li[0];
    var sprite = li[1];
    if (x < 8 && flagShowLeftBackground == 0) {
      background = 0;
    }
    if (x < 8 && flagShowLeftSprites == 0) {
      sprite = 0;
    }
    var b = background % 4 != 0;
    var s = sprite % 4 != 0;
    var color = 0;
    if (!b && !s) {
      color = 0;
    } else if (!b && s) {
      color = sprite | 0x10;
    } else if (b && !s) {
      color = background;
    } else {
      if (spriteIndexes[i] == 0 && x < 255) {
        flagSpriteZeroHit = 1;
      }
      if (spritePriorities[i] == 0) {
        color = sprite | 0x10;
      } else {
        color = background;
      }
    }

    var c = nesSysPalettes[readPalette((color)) % 64];
    back.setPixel(x, y, c);
  }

  int fetchSpritePattern(int i, int row) {
    var tile = oamData[i * 4 + 1];
    var attributes = oamData[i * 4 + 2];
    var address = 0;
    if (flagSpriteSize == 0) {
      if (attributes & 0x80 == 0x80) {
        row = 7 - row;
      }
      var table = flagSpriteTable;
      address = 0x1000 * table + tile * 16 + row;
    } else {
      if (attributes & 0x80 == 0x80) {
        row = 15 - row;
      }
      var table = tile & 1;
      tile &= 0xFE;
      if (row > 7) {
        tile++;
        row -= 8;
      }
      address = 0x1000 * (table) + (tile) * 16 + (row);
    }
    var a = (attributes & 3) << 2;
    var lowTileByte = readPpuBus(address);
    var highTileByte = readPpuBus(address + 8);
    var data = 0;
    for (int i = 0; i < 8; i++) {
      var p1 = 0, p2 = 0;
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
      data |= (a | p1 | p2);
    }
    return data;
  }

  void evaluateSprites() {
    var h = 0;
    if (flagSpriteSize == 0) {
      h = 8;
    } else {
      h = 16;
    }
    var count = 0;
    for (int i = 0; i < 64; i++) {
      var y = oamData[i * 4 + 0];
      var a = oamData[i * 4 + 2];
      var x = oamData[i * 4 + 3];
      var row = scanLine - (y);
      if (row < 0 || row >= h) {
        continue;
      }
      if (count < 8) {
        spritePatterns[count] = fetchSpritePattern(i, row);
        spritePositions[count] = x;
        spritePriorities[count] = (a >> 5) & 1;
        spriteIndexes[count] = (i);
      }
      count++;
    }
    if (count > 8) {
      count = 8;
      flagSpriteOverflow = 1;
    }
    spriteCount = count;
  }

  void tick() {
    if (nmiDelay > 0) {
      nmiDelay--;
      if (nmiDelay == 0 && nmiOutput && nmiOccurred) {
        onNmiInterrupted();
      }
    }

    if (flagShowBackground != 0 || flagShowSprites != 0) {
      if (f == 1 && scanLine == 261 && cycle == 339) {
        cycle = 0;
        scanLine = 0;
        frame++;
        f ^= 1;
        return;
      }
    }
    cycle++;
    if (cycle > 340) {
      cycle = 0;
      scanLine++;
      if (scanLine > 261) {
        scanLine = 0;
        frame++;
        f ^= 1;
      }
    }
  }

  void step() {
    tick();

    var renderingEnabled = flagShowBackground != 0 || flagShowSprites != 0;
    var preLine = scanLine == 261;
    var visibleLine = scanLine < 240;
    var postLine = scanLine == 240;
    var renderLine = preLine || visibleLine;
    var preFetchCycle = cycle >= 321 && cycle <= 336;
    var visibleCycle = cycle >= 1 && cycle <= 256;
    var fetchCycle = preFetchCycle || visibleCycle;

    // background logic
    if (renderingEnabled) {
      if (visibleLine && visibleCycle) {
        renderPixel();
      }
      if (renderLine && fetchCycle) {
        tileData <<= 4;
        switch (cycle % 8) {
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
      if (preLine && cycle >= 280 && cycle <= 304) {
        copyY();
      }
      if (renderLine) {
        if (fetchCycle && cycle % 8 == 0) {
          incrementX();
        }
        if (cycle == 256) {
          incrementY();
        }
        if (cycle == 257) {
          copyX();
        }
      }
    }

    // sprite logic
    if (renderingEnabled) {
      if (cycle == 257) {
        if (visibleLine) {
          evaluateSprites();
        } else {
          spriteCount = 0;
        }
      }
    }

    // vblank logic
    if (scanLine == 241 && cycle == 1) {
      setVerticalBlank();
    }
    if (preLine && cycle == 1) {
      clearVerticalBlank();
      flagSpriteZeroHit = 0;
      flagSpriteOverflow = 0;
    }
  }
}

class Ppu implements IPpu {
  PpuImpl ppu;

  Ppu({
    required BusAdapter bus,
    required VoidCallback onNmiInterrupted,
  }) : ppu = PpuImpl(bus: bus, onNmiInterrupted: onNmiInterrupted);
  @override
  FrameBuffer get frameBuffer => ppu.back;

  @override
  U8 get regData => ppu.readData();
  @override
  set regData(U8 regData) {
    ppu.register = regData;
    ppu.writeData(regData);
  }

  @override
  U8 get regOamData => ppu.readOAMData();
  @override
  set regOamData(U8 regOamData) {
    ppu.register = regOamData;
    ppu.writeOAMData(regOamData);
  }

  @override
  void clock() => ppu.step();

  @override
  set regController(U8 val) {
    ppu.register = val;
    ppu.writeControl(val);
  }

  @override
  set regMask(U8 val) {
    ppu.register = val;
    ppu.writeMask(val);
  }

  @override
  set regOamAddress(U8 val) {
    ppu.register = val;
    ppu.writeAddress(val);
  }

  @override
  set regScroll(U8 val) {
    ppu.register = val;
    ppu.writeScroll(val);
  }

  @override
  U8 get regStatus => ppu.readStatus();

  @override
  void reset() => ppu.reset();

  @override
  int get totalFrames => ppu.frame;

  @override
  set regAddress(U8 val) {
    ppu.register = val;
    ppu.writeAddress(val);
  }
}
