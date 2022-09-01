import 'package:nes_emulator/bus_adapter.dart';
import 'package:nes_emulator/common.dart';
import 'package:nes_emulator/ppu/ppu3/ppu.dart';

class Ppu3Adapter implements BusAdapter {
  PPU ppu;
  PPUMemory ppu_memory;
  int _sprite_memory_addr = 0;
  int get _ppu_addr_increase => ((ppu_memory.control_register >> 2) & 1) == 1 ? 32 : 1;
  int _ppu_memory_buffer = 0;
  Ppu3Adapter(this.ppu) : ppu_memory = ppu.memory;
  @override
  bool accept(U16 address) => 0x2000 <= address && address <= 0x2007;

  @override
  U8 read(U16 address) {
    switch (address) {
      case 0x2000:
        return ppu_memory.control_register;

      case 0x2001:
        return ppu_memory.mask_register;

      case 0x2002:
        int res = ppu_memory.status_register;
        // reading PPUSTATUS reset bit 7, PPUSCROLL and PPUADDRESS
        ppu_memory
          ..status_register &= ~(1 << 7)
          ..toggle_second_w = false;
        return res;

      case 0x2004:
        int res = ppu_memory.spr_ram[_sprite_memory_addr];
        return res;

      case 0x2007:
        int res = ppu_memory[ppu_memory.memory_addr];
        if ((ppu_memory.memory_addr & 0x3FFF) < 0x3F00) {
          // emulate buffered read when to reading palette
          int temp = _ppu_memory_buffer;
          _ppu_memory_buffer = res;
          res = temp;
        }
        // for more accuracy, scrolling related registers should also be set
        ppu_memory.memory_addr += _ppu_addr_increase;
        ppu_memory.memory_addr &= 0xFFFF;
        return res;
    }
    throw UnsupportedError('');
  }

  @override
  void write(U16 address, U8 value) {
    switch (address) {
      case 0x2000:
        ppu_memory
          ..control_register = value
          ..temp_addr &= ~(3 << 10)
          ..temp_addr |= (value & 3) << 10;
        break;
      case 0x2001:
        ppu_memory.mask_register = value;
        break;
      case 0x2003:
        _sprite_memory_addr = value;
        break;
      case 0x2004:
        if (_sprite_memory_addr & 3 == 2) {
          // bits 234 of byte 2 are unimplemented
          value &= 0xE3;
        }
        ppu_memory.spr_ram[_sprite_memory_addr] = value;
        _sprite_memory_addr++;
        _sprite_memory_addr &= 0xFF;
        break;
      case 0x2005:
        if (ppu_memory.toggle_second_w) {
          ppu_memory
            ..temp_addr &= 0xC1F
            ..temp_addr |= ((value & 7) << 12)
            ..temp_addr |= ((value & 0xF8) << 2)
            ..toggle_second_w = false;
        } else {
          ppu_memory
            ..x_scroll &= ~7
            ..x_scroll |= value & 7
            ..temp_addr &= ~0x1F
            ..temp_addr |= (value >> 3)
            ..toggle_second_w = true;
        }
        break;
      case 0x2006:
        if (ppu_memory.toggle_second_w) {
          ppu_memory
            ..temp_addr &= 0xFF00
            ..temp_addr |= value
            ..transfer_temp_addr()
            ..toggle_second_w = false;
        } else {
          ppu_memory
            ..temp_addr &= 0x00FF
            ..temp_addr |= ((value & 0x3F) << 8)
            ..toggle_second_w = true;
        }
        break;
      case 0x2007:
        //if (ppu_memory.memory_addr == 0x3F01) debugger();
        ppu_memory[ppu_memory.memory_addr] = value;
        ppu_memory.memory_addr += _ppu_addr_increase;
        ppu_memory.memory_addr &= 0xFFFF;
        break;
    }
  }
}
