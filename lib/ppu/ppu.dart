library nesbox.ppu;

import 'dart:typed_data';

import 'package:nes_emulator/ppu/controller.dart';
import 'package:nes_emulator/ppu/mask.dart';
import 'package:nes_emulator/ppu/status.dart';

import '../bus_adapter.dart';
import '../common.dart';
import '../framebuffer.dart';
import '../util.dart';
import 'palettes.dart';

class Ppu {
  /// nmi中断信号
  final VoidCallback onNmiInterrupted;

  /// 游戏卡带
  final BusAdapter ppuBus;

  /// PPU显存
  final Uint8List videoRAM = Uint8List(0x1000);

  /// 调色板
  final Uint8List paletteTable = Uint8List(0x20);

  final Mirroring mirroring;

  Ppu({
    required this.ppuBus,
    required this.mirroring,
    required this.onNmiInterrupted,
  });

  // https://wiki.nesdev.com/w/index.php/PPUregisters

  // Control ($2000) > write
  final regControl = ControlRegister();

  // Mask ($2001) > write
  final regMask = MaskRegister();

  // Status ($2002) < read
  final regStatus1 = StatusRegister();

  set regController(int value) {
    regControl.bits.value = value;

    // t: ...GH.. ........ <- d: ......GH
    // <used elsewhere> <- d: ABCDEF..
    regT = (regT & 0xf3ff) | (value & 0x03) << 10;
  }

  int get regStatus {
    U8 status = regStatus1.bits[StatusFlag.spriteOverflow].asInt() << 5 |
        regStatus1.bits[StatusFlag.spriteZeroHit].asInt() << 6;

    status |= fNmiOccurred << 7;
    fNmiOccurred = 0;

    // w:                  <- 0
    regW = 0;

    return status;
  }

  // OAM address ($2003) > write
  int regOamAddress = 0x00;

  // The OAM (Object Attribute Memory) is internal memory inside the PPU that contains a display list of up to 64 sprites,
  // where each sprite's information occupies 4 bytes. So OAM takes 256 bytes
  Uint8List oam = Uint8List(0x100);

  // OAM(SPR-RAM) data ($2004) <> read/write
  int get regOamData => oam[regOamAddress];
  set regOamData(int value) => oam[regOamAddress++] = value;

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
  U8 dataBuffer = 0x00;

  // Data ($2007) <> read/write
  // this is the port that CPU read/write data via VRAM.
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

    regV += regControl.videoRamAddressIncrement;
    return value;
  }

  set regData(int value) {
    write(regV, value);
    regV += regControl.videoRamAddressIncrement;
  }

  // https://wiki.nesdev.org/w/index.php?title=NMI
  int fNmiOccurred = 0; // 1bit

  checkNmiPulled() {
    if (fNmiOccurred == 1 && regControl.generateVBlankNmi) {
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

  _renderPixel() {
    int x = cycle - 1, y = scanline;

    int backgroundPixel = _renderBGPixel();

    frame.setPixel(
      x,
      y,
      backgroundPixel,
    );
  }

  _renderBGPixel() {
    int currentTile = bgTile >> 32;
    int palette = currentTile >> ((7 - regX) * 4);
    int entry = paletteTable[palette & 0x0f];

    return nesSysPalettes[entry] ?? 0;
  }

  _fetchNameTableByte() {
    int addr = 0x2000 | (regV & 0x0fff);
    nameTableByte = read(addr);
  }

  _fetchAttributeTableByte() {
    int addr = 0x23c0 | (regV & 0x0c00) | ((regV >> 4) & 0x38) | ((regV >> 2) & 0x07);
    int shift = ((regV >> 4) & 4) | (regV & 2);
    attributeTableByte = ((read(addr) >> shift) & 3) << 2;
  }

  _fetchLowBGTileByte() {
    int fineY = (regV >> 12) & 0x7;
    int addr = regControl.backgroundPatternAddress + nameTableByte * 16 + fineY;

    lowBGTileByte = read(addr);
  }

  _fetchHighBGTileByte() {
    int fineY = (regV >> 12) & 0x7;
    int addr = regControl.backgroundPatternAddress + nameTableByte * 16 + fineY;

    highBGTileByte = read(addr + 8);
  }

  _composeBGTile() {
    int tile = 0;

    for (int i = 7; i >= 0; i--) {
      int lowBit = lowBGTileByte.getBit(i).asInt();
      int highBit = highBGTileByte.getBit(i).asInt();

      tile <<= 4;
      tile |= attributeTableByte | highBit << 1 | lowBit;
    }

    bgTile |= tile;
  }

  _incrementCoarseX() {
    if ((regV & 0x001f) == 31) {
      regV &= 0xffe0; // coarse X = 0
      regV ^= 0x0400; // switch horizontal nametable
    } else {
      regV++;
    }
  }

  _incrementScrollY() {
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

  // _evaluateSprites() {}

  // every cycle behaivor is here: https://wiki.nesdev.com/w/index.php/PPU_rendering#Line-by-line_timing
  void clock() {
    bool isScanlineVisible = scanline < 240;
    bool isScanlinePreRender = scanline == 261;
    bool isScanlineFetching = isScanlineVisible || isScanlinePreRender;

    bool isCycleVisible = cycle >= 1 && cycle <= 256;
    bool isCyclePreFetch = cycle >= 321 && cycle <= 336;
    bool isCycleFetching = isCycleVisible || isCyclePreFetch;

    bool isRenderingEnabled = regMask.bits[MaskFlag.showBackground] || regMask.bits[MaskFlag.showSprite];

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
      regStatus1.bits[StatusFlag.verticalBlankStarted] = true;
      fNmiOccurred = 1;
      checkNmiPulled();
    }

    // end vertical blanking
    if (isScanlinePreRender && cycle == 1) {
      regStatus1.bits[StatusFlag.verticalBlankStarted] = false;
      fNmiOccurred = 0;
    }

    _updateCounters();
  }

  void _updateCounters() {
    if (regMask.bits[MaskFlag.showBackground] || regMask.bits[MaskFlag.showSprite]) {
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

  void reset() {
    cycle = 0;
    scanline = 0;
    frames = 0;

    regController = 0x00;
    regMask.bits.resetAll();
    regScroll = 0x00;
    dataBuffer = 0x00;

    for (int i = 0; i < videoRAM.length; i++) {
      videoRAM[i] = 0;
    }
    for (int i = 0; i < paletteTable.length; i++) {
      paletteTable[i] = 0;
    }
  }

  int readRegister(int address) {
    if (address == 0x2) return regStatus;
    if (address == 0x4) return regOamData;
    if (address == 0x7) return regData;

    throw "Unhandled ppu register reading: ${address.toHex()}";
  }

  void writeRegister(int address, int value) {
    value &= 0xff;

    if (address == 0x0) {
      regController = value;
      return;
    }
    if (address == 0x1) {
      regMask.bits.value = value;
      return;
    }
    if (address == 0x3) {
      regOamAddress = value;
      return;
    }
    if (address == 0x4) {
      regOamData = value;
      return;
    }
    if (address == 0x5) {
      regScroll = value;
      return;
    }
    if (address == 0x6) {
      regAddress = value;
      return;
    }
    if (address == 0x7) {
      regData = value;
      return;
    }

    throw "Unhandled register writing: ${address.toHex()}";
  }

  int read(int address) {
    address = (address & 0xffff) % 0x4000;

    // CHR-ROM or Pattern Tables
    if (address < 0x2000) return ppuBus.read(address);

    // NameTables (RAM)
    if (address < 0x3f00) return videoRAM[nameTableMirroring(address)];

    // Palettes
    return paletteTable[address % 0x20];
  }

  void write(int address, int value) {
    address = (address & 0xffff) % 0x4000;
    value &= 0xff;

    // CHR-ROM or Pattern Tables
    if (address < 0x2000) {
      ppuBus.write(address, value);
      return;
    }

    // NameTables (RAM)
    if (address < 0x3f00) {
      videoRAM[nameTableMirroring(address)] = value;
      return;
    }

    // Palettes
    paletteTable[address % 0x20] = value;
  }

  int nameTableMirroring(int address) {
    address = address % 0x1000;
    int chunk = (address / 0x400).floor();

    switch (mirroring) {
      // [A][A] --> [0x2000][0x2400]
      // [B][B] --> [0x2800][0x2c00]
      case Mirroring.horizontal:
        return [1, 3].contains(chunk) ? address - 0x400 : address;

      // [A][B] --> [0x2000][0x2400]
      // [A][B] --> [0x2800][0x2c00]
      case Mirroring.vertical:
        return chunk > 1 ? address - 0x800 : address;

      // [A][B] --> [0x2000][0x2400]
      // [C][D] --> [0x2800][0x2c00]
      case Mirroring.fourScreen:
        return address;

      // [A][A] --> [0x2000][0x2400]
      // [A][A] --> [0x2800][0x2c00]
      case Mirroring.singleScreen:
        return address % 0x400;
    }
    return address;
  }
}
