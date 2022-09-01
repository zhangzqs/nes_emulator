library nesbox.ppu;

import 'dart:typed_data';

import 'package:nes_emulator/common.dart';
import 'package:nes_emulator/framebuffer.dart';
import 'package:nes_emulator/ppu/abstruct_ppu.dart';
import 'package:nes_emulator/util.dart';

import '../bus_adapter.dart';

const Map<int, int> NES_SYS_PALETTES = {
  // NES colour palettes is in NESDoc page 45.
  // value is a 32-bit int mean RGB
  0x00: 0x757575,
  0x01: 0x271b8f,
  0x02: 0x0000ab,
  0x03: 0x47009f,
  0x04: 0x8f0077,
  0x05: 0xab0013,
  0x06: 0xa70000,
  0x07: 0x7f0b00,
  0x08: 0x432f00,
  0x09: 0x004700,
  0x0a: 0x005100,
  0x0b: 0x003f17,
  0x0c: 0x1b3f5f,
  0x0d: 0x000000,
  0x0e: 0x000000,
  0x0f: 0x000000,

  0x10: 0xbcbcbc,
  0x11: 0x0073ef,
  0x12: 0x233bef,
  0x13: 0x8300f3,
  0x14: 0xbf00bf,
  0x15: 0xe7005b,
  0x16: 0xdb2b00,
  0x17: 0xcb4f0f,
  0x18: 0x8b7300,
  0x19: 0x009700,
  0x1a: 0x00ab00,
  0x1b: 0x00933b,
  0x1c: 0x00838b,
  0x1d: 0x000000,
  0x1e: 0x000000,
  0x1f: 0x000000,

  0x20: 0xffffff,
  0x21: 0x3fbfff,
  0x22: 0x5f97ff,
  0x23: 0xa78bfd,
  0x24: 0xf77bff,
  0x25: 0xff77b7,
  0x26: 0xff7763,
  0x27: 0xff9b3b,
  0x28: 0xf3bf3f,
  0x29: 0x83d313,
  0x2a: 0x4fdf4b,
  0x2b: 0x58f898,
  0x2c: 0x00ebdb,
  0x2d: 0x000000,
  0x2e: 0x000000,
  0x2f: 0x000000,

  0x30: 0xffffff,
  0x31: 0xabe7ff,
  0x32: 0xc7d7ff,
  0x33: 0xd7cbff,
  0x34: 0xffc7ff,
  0x35: 0xffc7db,
  0x36: 0xffbfb3,
  0x37: 0xffdbab,
  0x38: 0xffe7a3,
  0x39: 0xe3ffa3,
  0x3a: 0xabf3bf,
  0x3b: 0xb3ffcf,
  0x3c: 0x9ffff3,
  0x3d: 0x000000,
  0x3e: 0x000000,
  0x3f: 0x000000,
};

class Ppu implements IPpu {
  final VoidCallback onNmiInterrupted;
  final BusAdapter bus;

  Ppu({
    required this.bus,
    required this.onNmiInterrupted,
  });
  // https://wiki.nesdev.com/w/index.php/PPUregisters

  // Controller ($2000) > write
  int fBaseNameTable = 0; // 0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00
  int fAddressIncrement = 0; // 0: add 1, going across; 1: add 32, going down
  int fSpritePatternTable = 0; // 0: $0000; 1: $1000; ignored in 8x16 mode
  int fBackPatternTable = 0; // 0: $0000; 1: $1000
  int fSpriteSize = 0; // 0: 8x8 pixels; 1: 8x16 pixels
  int fSelect = 0; // 0: read backdrop from EXT pins; 1: output color on EXT pins
  int fNmiOutput = 0; // 1bit, 0: 0ff, 1: on

  @override
  set regController(int value) {
    fBaseNameTable = value & 0x3;
    fAddressIncrement = value >> 2 & 0x1;
    fSpritePatternTable = value >> 3 & 0x1;
    fBackPatternTable = value >> 4 & 0x1;
    fSpriteSize = value >> 5 & 0x1;
    fSelect = value >> 6 & 0x1;
    fNmiOutput = value >> 7 & 0x1;

    // t: ...GH.. ........ <- d: ......GH
    // <used elsewhere> <- d: ABCDEF..
    regT = (regT & 0xf3ff) | (value & 0x03) << 10;
  }

  // Mask ($2001) > write
  int fGeryScale = 0; // 0: normal color, 1: produce a greyscale display
  int fBackLeftMost = 0; // 1: Show background in leftmost 8 pixels of screen, 0: Hide
  int fSpriteLeftMost = 0; // 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
  int fShowBack = 0; // 1: Show background
  int fShowSprite = 0; // 1: Show sprites
  int fEmphasizeRed = 0; // green on PAL/Dendy
  int fEmphasizeGreen = 0; // red on PAL/Dendy
  int fEmphasizeBlue = 0;

  @override
  set regMask(int value) {
    fGeryScale = value & 0x1;
    fBackLeftMost = value >> 1 & 0x1;
    fSpriteLeftMost = value >> 2 & 0x1;
    fShowBack = value >> 3 & 0x1;
    fShowSprite = value >> 4 & 0x1;
    fEmphasizeRed = value >> 5 & 0x1;
    fEmphasizeGreen = value >> 6 & 0x1;
    fEmphasizeBlue = value >> 7 & 0x1;
  }

  // Status ($2002) < read
  int fSign = 0;
  int fSpriteOverflow = 0;
  int fSpirteZeroHit = 0;
  int fVerticalBlanking = 0;

  @override
  int get regStatus {
    int status = (fSign & 0x1f) | fSpriteOverflow << 5 | fSpirteZeroHit << 6;

    status |= fNmiOccurred << 7;
    fNmiOccurred = 0;

    // w:                  <- 0
    regW = 0;

    return status;
  }

  // OAM address ($2003) > write
  @override
  int regOamAddress = 0x00;

  // The OAM (Object Attribute Memory) is internal memory inside the PPU that contains a display list of up to 64 sprites,
  // where each sprite's information occupies 4 bytes. So OAM takes 256 bytes
  Uint8List oam = Uint8List(256);

  // OAM(SPR-RAM) data ($2004) <> read/write
  @override
  int get regOamData => oam[regOamAddress];
  @override
  set regOamData(int value) {
    oam[regOamAddress] = value;
  }

  // https://wiki.nesdev.org/w/index.php?title=PPU_scrolling
  // reg V bits map
  // yyy NN YYYYY XXXXX
  // ||| || ||||| +++++-- coarse X scroll
  // ||| || +++++-------- coarse Y scroll
  // ||| ++-------------- nametable select
  // +++----------------- fine Y scroll
  int regV = 0x00; // current VRAM Address 15bits
  int regT = 0x00; // temporary  VRAM address, 15bits
  int regX = 0x0; // fine x scroll 3bits;
  int regW = 0; // First or second write toggle, 1bit

  // Scroll ($2005) >> write x2
  @override
  set regScroll(int value) {
    if (regW == 0) {
      // first write
      // t: ....... ...ABCDE <- d: ABCDE...
      // x:              FGH <- d: .....FGH
      // w:                  <- 1
      regT = (regT & 0xffe0) | value >> 3;
      regX = value & 0x07;
      regW = 1;
    } else {
      // second write
      // t: FGH..AB CDE..... <- d: ABCDEFGH
      // w:                  <- 0
      regT &= 0x8c1f;
      regT |= (value & 0x07) << 12;
      regT |= (value & 0xf8) << 2;
      regW = 0;
    }
  }

  // Address ($2006) >> write x2
  @override
  set regAddress(int value) {
    if (regW == 0) {
      // first write
      // t: .CDEFGH ........ <- d: ..CDEFGH
      //        <unused>     <- d: AB......
      // t: Z...... ........ <- 0 (bit Z is cleared)
      // w:                  <- 1

      regT = (regT & 0xc0ff) | (value & 0x3f) << 8;
      regT = regT.setBit(14, false);
      regW = 1;
    } else {
      // second write
      // t: ....... ABCDEFGH <- d: ABCDEFGH
      // v: <...all bits...> <- t: <...all bits...>
      // w:                  <- 0

      regT = (regT & 0xff00) | value;
      regV = regT;
      regW = 0;
    }
  }

  // see: https://wiki.nesdev.com/w/index.php/PPUregisters#The_PPUDATA_read_buffer_.28post-fetch.29
  // the first result should be discard when CPU reading PPUDATA
  int dataBuffer = 0x00;

  // Data ($2007) <> read/write
  // this is the port that CPU read/write data via VRAM.
  @override
  int get regData {
    int vramData = read(regV);
    int value;

    if (regV % 0x4000 < 0x3f00) {
      value = dataBuffer;
      dataBuffer = vramData; // update data buffer with vram data
    } else {
      // when reading palttes, the buffer data is the mirrored nametable data that would appear "underneath" the palette.
      value = vramData;
      dataBuffer = read(regV - 0x1000);
    }

    regV += fAddressIncrement == 1 ? 32 : 1;
    return value;
  }

  @override
  set regData(int value) {
    write(regV, value);
    regV += fAddressIncrement == 1 ? 32 : 1;
  }

  // https://wiki.nesdev.org/w/index.php?title=NMI
  int fNmiOccurred = 0; // 1bit

  void checkNmiPulled() {
    if (fNmiOccurred == 1 && fNmiOutput == 1) {
      onNmiInterrupted();
    }
  }

  int scanline = 0;
  int cycle = 0;
  int frames = 0;
  bool fOddFrames = false;

  int nameTableByte = 0;
  int attributeTableByte = 0;
  int lowBGTileByte = 0;
  int highBGTileByte = 0;
  int bgTile = 0;

  FrameBuffer frame = FrameBuffer();

  void _renderPixel() {
    int x = cycle - 1, y = scanline;

    int backgroundPixel = _renderBGPixel();

    frame.setPixel(
      x,
      y,
      backgroundPixel,
    );
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

  int _renderBGPixel() {
    int currentTile = bgTile >> 32;
    int palette = currentTile >> ((7 - regX) * 4);
    int entry = _readPalette(palette & 0x0f);

    return NES_SYS_PALETTES[entry]!;
  }

  void _fetchNameTableByte() {
    int addr = 0x2000 | (regV & 0x0fff);
    nameTableByte = read(addr);
  }

  void _fetchAttributeTableByte() {
    int addr = 0x23c0 | (regV & 0x0c00) | ((regV >> 4) & 0x38) | ((regV >> 2) & 0x07);
    int shift = ((regV >> 4) & 4) | (regV & 2);
    attributeTableByte = ((read(addr) >> shift) & 3) << 2;
  }

  void _fetchLowBGTileByte() {
    int fineY = (regV >> 12) & 0x7;
    int addr = 0x1000 * fBackPatternTable + nameTableByte * 16 + fineY;

    lowBGTileByte = read(addr);
  }

  void _fetchHighBGTileByte() {
    int fineY = (regV >> 12) & 0x7;
    int addr = 0x1000 * fBackPatternTable + nameTableByte * 16 + fineY;

    highBGTileByte = read(addr + 8);
  }

  void _composeBGTile() {
    int tile = 0;

    for (int i = 7; i >= 0; i--) {
      int lowBit = lowBGTileByte.getBit(i).asInt();
      int highBit = highBGTileByte.getBit(i).asInt();

      tile <<= 4;
      tile |= attributeTableByte | highBit << 1 | lowBit;
    }

    bgTile |= tile;
  }

  void _incrementCoarseX() {
    if ((regV & 0x001f) == 31) {
      regV &= 0xffe0; // coarse X = 0
      regV ^= 0x0400; // switch horizontal nametable
    } else {
      regV++;
    }
  }

  void _incrementScrollY() {
    // if fine Y < 7
    if (regV & 0x7000 != 0x7000) {
      regV += 0x1000; // increment fine Y
    } else {
      regV &= 0x8fff; // fine Y = 0

      int y = (regV & 0x03e0) >> 5; // let y = coarse Y
      if (y == 29) {
        y = 0; // coarse Y = 0
        regV ^= 0x0800; // switch vertical nametable
      } else if (y == 31) {
        y = 0; // coarse Y = 0, nametable not switched
      } else {
        y++; // increment coarse Y
      }

      regV = (regV & 0xfc1f) | (y << 5); // put coarse Y back into v
    }
  }

  void copyX() {
    // v: ....A.. ...BCDEF <- t: ....A.. ...BCDEF
    regV = (regV & 0xfbe0) | (regT & 0x041f);
  }

  void copyY() {
    // v: GHIA.BC DEF..... <- t: GHIA.BC DEF.....
    regV = (regV & 0x841f) | (regT & 0x7be0);
  }

  _evaluateSprites() {}

  // every cycle behaivor is here: https://wiki.nesdev.com/w/index.php/PPU_rendering#Line-by-line_timing
  @override
  void clock() {
    bool isScanlineVisible = scanline < 240;
    bool isScanlinePreRender = scanline == 261;
    bool isScanlineFetching = isScanlineVisible || isScanlinePreRender;

    bool isCycleVisible = cycle >= 1 && cycle <= 256;
    bool isCyclePreFetch = cycle >= 321 && cycle <= 336;
    bool isCycleFetching = isCycleVisible || isCyclePreFetch;

    bool isRenderingEnabled = fShowBack == 1 || fShowSprite == 1;

    // OAMADDR is set to 0 during each of ticks 257-320
    if (isScanlineFetching && cycle >= 257 && cycle <= 320) {
      regOamAddress = 0x00;
    }

    if (isRenderingEnabled) {
      if (isCycleVisible && isScanlineVisible) {
        _renderPixel();
      }

      // fetch background data
      if (isCycleFetching && isScanlineFetching) {
        bgTile <<= 4;

        switch (cycle % 8) {
          case 0:
            _composeBGTile();
            break;
          case 1:
            _fetchNameTableByte();
            break;
          case 3:
            _fetchAttributeTableByte();
            break;
          case 5:
            _fetchLowBGTileByte();
            break;
          case 7:
            _fetchHighBGTileByte();
            break;
        }
      }

      if (isScanlinePreRender && cycle >= 280 && cycle <= 304) {
        copyY();
      }

      // after fetch next tile
      if (isScanlineFetching && isCycleFetching && (cycle % 8 == 0)) {
        _incrementCoarseX();
      }

      if (isScanlineFetching && cycle == 256) {
        _incrementScrollY();
      }

      if (isScanlineFetching && cycle == 257) {
        copyX();
      }
    }

    // start vertical blanking
    if (scanline == 241 && cycle == 1) {
      fVerticalBlanking = 1;
      fNmiOccurred = 1;
      checkNmiPulled();
    }

    // end vertical blanking
    if (isScanlinePreRender && cycle == 1) {
      fVerticalBlanking = 0;
      fNmiOccurred = 0;
    }

    _updateCounters();
  }

  void _updateCounters() {
    if (fShowBack == 1 || fShowSprite == 1) {
      if (scanline == 261 && cycle == 339 && fOddFrames) {
        cycle = 0;
        scanline = 0;
        frames++;
        fOddFrames = !fOddFrames;
        return;
      }
    }

    cycle++;
    // one scanline is completed.
    if (cycle > 340) {
      cycle = 0;
      scanline++;
    }

    // one frame is completed.
    if (scanline > 261) {
      scanline = 0;
      frames++;
      fOddFrames = !fOddFrames;
    }
  }

  @override
  void reset() {
    cycle = 0;
    scanline = 0;
    frames = 0;

    regController = 0x00;
    regMask = 0x00;
    regScroll = 0x00;
    dataBuffer = 0x00;
  }

  int read(int address) {
    return bus.read(address);
  }

  void write(int address, int value) {
    bus.write(address, value);
  }

  @override
  FrameBuffer get frameBuffer => frame;

  @override
  int get totalFrames => frames;
}
