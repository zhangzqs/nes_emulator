import 'dart:typed_data';

import 'package:nes_emulator/ram/ram.dart';

import '../common.dart';
import 'mapper/mapper.dart';
import 'nes_file.dart';

abstract class ICartridge {
  Mapper? _mapper;
  Mapper get mapper {
    return _mapper ??= MapperFactory.getMapper(this);
  }

  Ram? _sRam;
  Ram get sRam {
    if (!hasBatteryBacked) {
      throw UnsupportedError('nes cartridge have no battery');
    }
    return _sRam ??= Ram(0x2000);
  }

  Uint8List get trainerRom {
    if (!hasTrainer) {
      throw UnsupportedError('nes cartridge have no trainer');
    }
    throw UnimplementedError();
  }

  Uint8List get prgRom;
  Uint8List get chrRom;
  U8 get prgBanks;
  U8 get chrBanks;
  bool get hasTrainer;
  bool get hasBatteryBacked;
  Mirroring get mirroring;
  U8 get mapperId;

  @override
  String toString() {
    final a = {
      'prgBanks': prgBanks,
      'chrBanks': chrBanks,
      'mirroring': mirroring.name,
      'hasBatteryBacked': hasBatteryBacked,
      'hasTrainer': hasTrainer,
      'mapperId': mapperId,
    };
    return 'Cartridge{$a}';
  }
}

class Cartridge extends ICartridge {
  @override
  final Uint8List prgRom;
  @override
  Uint8List chrRom;
  @override
  final bool hasBatteryBacked;
  @override
  final Mirroring mirroring;
  @override
  final U8 mapperId;
  @override
  final U8 prgBanks;
  @override
  final U8 chrBanks;
  @override
  final bool hasTrainer;

  Cartridge(NesFileReader reader)
      : prgRom = reader.prgRom,
        chrRom = reader.chrBanks != 0 ? reader.chrRom : Uint8List(8192),
        hasBatteryBacked = reader.hasBatteryBacked,
        mirroring = reader.mirroring,
        mapperId = reader.mapperId,
        prgBanks = reader.prgBanks,
        chrBanks = reader.chrBanks,
        hasTrainer = reader.hasTrainer {
    if (!reader.isValid) {
      throw FormatException('Nes file format error');
    }
  }
}
