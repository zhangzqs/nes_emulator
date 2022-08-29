import 'dart:typed_data';

import '../common.dart';
import '../constant.dart';
import '../framebuffer.dart';
import '../util.dart';
import 'mapper/mapper.dart';

class Cartridge {
  static const U16 _prgBankSize = 0x4000;
  static const U16 _chrBankSize = 0x2000;
  static const U16 _trainerSize = 0x0200;

  late Uint8List rom; // whole game rom

  late Uint8List prgROM;
  late Uint8List chrROM;
  late Uint8List trainerROM;
  late Uint8List sRAM; // battery-backed PRG RAM, 8kb

  late int prgBanks;
  late int chrBanks;
  late bool battery;

  late U16 mapperId;
  late Mapper mapper;
  late Mirroring mirroring;

  TileFrame firstTileFrame = TileFrame();
  TileFrame secondTileFrame = TileFrame();

  Cartridge(Uint8List gameBytes) {
    rom = gameBytes;

    parse();
    createTileFrame(firstTileFrame);
    createTileFrame(secondTileFrame, 0x1000);
  }

  int read(int address) => mapper.read(address);

  void write(int address, int value) => mapper.write(address, value);

  void parse() {
    // header[0-3]: Constant $4E $45 $53 $1A ("NES" followed by MS-DOS end-of-file)
    if (rom.sublist(0, 4).join() != [0x4e, 0x45, 0x53, 0x1a].join()) {
      throw ("invalid nes file");
    }

    // mirroring type
    mirroring = {
      0: Mirroring.horizontal,
      1: Mirroring.vertical,
      2: Mirroring.fourScreen,
      3: Mirroring.fourScreen,
    }[rom[6].getBit(3).asInt() << 1 | rom[6].getBit(0).asInt()]!;

    // battery-backed RAM Save-RAM
    battery = rom[6].getBit(1);
    sRAM = Uint8List(0x2000);

    int offset = 0x10; // start after header
    // trainer
    if (rom[6].getBit(2)) {
      trainerROM = rom.sublist(0x10, offset += _trainerSize);
    }

    // program rom
    prgBanks = rom[4];
    prgROM = rom.sublist(offset, offset += prgBanks * _prgBankSize);

    // character rom
    chrBanks = rom[5];
    chrROM = rom.sublist(offset, offset += chrBanks * _chrBankSize);

    // sometimes rom file do not provide chr rom, instead providing in runtime
    if (chrBanks == 0) {
      chrROM = Uint8List(_chrBankSize);
    }

    // mapper
    int lowerMapper = rom[6] & 0xf0;
    int upperMapper = rom[7] & 0xf0;
    mapperId = upperMapper | lowerMapper >> 4;
    mapper = Mapper(this);
  }

  void createTileFrame(TileFrame frame, [int baseAddress = 0]) {
    for (int tiles = 0; tiles < 0x100; tiles++) {
      for (int fineY = 0; fineY < 8; fineY++) {
        var lowTile = read(baseAddress + tiles * 8 + fineY);
        var highTile = read(baseAddress + tiles * 8 + fineY + 8);

        for (int fineX = 0; fineX < 8; fineX++) {
          int lowBit = lowTile.getBit(7 - fineX).asInt();
          int highBit = highTile.getBit(7 - fineX).asInt();

          int x = (tiles % 16) * 8 + fineX;
          int y = (tiles / 16).floor() * 8 + fineY;

          frame.setPixel(x, y, Constant.nesSysPalettes[highBit << 1 | lowBit] ?? 0);
        }
      }
    }
  }
}
