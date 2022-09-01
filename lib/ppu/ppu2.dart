import 'dart:typed_data';

import 'package:nes_emulator/bus_adapter.dart';
import 'package:nes_emulator/common.dart';
import 'package:nes_emulator/framebuffer.dart';
import 'package:nes_emulator/ppu/abstruct_ppu.dart';
import 'package:nes_emulator/ppu/oam.dart';
import 'package:nes_emulator/ppu/palettes.dart';
import 'package:nes_emulator/util.dart';

/// PPU控制寄存器
class PpuCtrl {
  U8 data = 0;

  int get nameTable {
    //使用哪个nameTable
    return data & 3;
  }

  int get addressIncrement {
    if (data.getBit(2)) {
      return 32;
    } else {
      return 1;
    }
  }

  /// Sprite哪个图案表。当标志位为1时，使用0x1000-0x1fff的图案表，否则用0x0000-0x0fff的
  U16 get spriteTableAddress {
    if (data.getBit(3)) {
      return 0x1000;
    } else {
      return 0x0000;
    }
  }

  /// Background使用哪个图案表。当标志位为1时，使用0x1000-0x1fff的图案表，否则用0x0000-0x0fff的
  U16 get backgroundTableAddress {
    if (data.getBit(4)) {
      return 0x1000;
    } else {
      return 0x0000;
    }
  }

  /// 获取sprite大小标志位。当标志位为1时，sprite大小更大
  bool get spriteSize {
    return data.getBit(5);
  }

  /// 是否在绘制结束后给CPU提供一个nmi中断的标志位
  bool get generateNmi {
    return data.getBit(7);
  }
}

class PpuMask {
  U8 data = 0;
  bool get greyMode => data.getBit(0);
  bool get showLeftBackground => data.getBit(1);
  bool get showLeftSprite => data.getBit(2);
  bool get showBackground => data.getBit(3);
  bool get showSprite => data.getBit(4);
}

class PpuStatus {
  U8 data = 0;
  bool get spriteOverflow => data.getBit(5);
  set spriteOverflow(bool v) {
    if (v) {
      data.setBit(5, v);
    } else {
      data &= 0xdf;
    }
  }

  bool get spriteZeroHit => data.getBit(6);

  set spriteZeroHit(bool v) {
    if (v) {
      data.setBit(6, v);
    } else {
      data &= 0xbf;
    }
  }

  /// 当前是否处在垂直消隐的阶段
  bool get vBlank => data.getBit(7);
  set vBlank(bool v) {
    if (v) {
      data.setBit(7, v);
    } else {
      data &= 0x7f;
    }
  }
}

class Reg {
  U16 data = 0;

  void set_low8(U8 data_in) {
    //设置寄存器的低八位值
    data &= 0xff00;
    data |= data_in;
  }

  void set_hi6(U8 data_in) {
    //设置寄存器的9-14位值. 更高的数值会被映射下去
    data &= 0x00ff;
    data |= ((data_in & 0x3f) << 8);
  }

  void set_nametable(U8 nametable_dx) {
    //设置NameTable的数值
    data &= 0xf3ff;
    data |= ((nametable_dx & 0x3) << 10);
  }

  void set_nametable_x(bool nametable_x) {
    //设置NameTable_X的数值
    if (nametable_x)
      data |= 1 << 10;
    else
      data &= 0xfbff;
  }

  void set_nametable_y(bool nametable_y) {
    //设置NameTable_Y的数值
    if (nametable_y)
      data |= 1 << 11;
    else
      data &= 0xf7ff;
  }

  void set_xscroll(U8 xscroll) {
    //设置x_scroll的数值
    data &= 0xffe0;
    data |= (xscroll & 0x1f);
  }

  void set_yscroll(U8 yscroll) {
    //设置y_scroll的数值
    data &= 0xfc1f;
    data |= ((yscroll & 0x1f) << 5);
  }

  void set_yfine(U8 yfine) {
    //设置y_fine的数值
    data &= 0x8fff;
    data |= ((yfine & 0x7) << 12);
  }

  U8 get_xscroll() {
    //获取x_scroll的数值
    return data & 0x1f;
  }

  bool get_nametable_x() {
    return data.getBit(10);
  }

  bool get_nametable_y() {
    return data.getBit(11);
  }

  U8 get_yscroll() {
    //获取y_scroll的数值
    return (data & 0x3e0) >> 5;
  }

  U8 get_yfine() {
    //获取y_fine的数值
    return (data & 0x7000) >> 12;
  }
}

extension ListClear on Uint8List {
  void setAllZero() {
    for (int i = 0; i < length; i++) {
      this[i] = 0;
    }
  }
}

class Ppu2 implements IPpu {
  final BusAdapter bus;

  /// nmi中断信号回调
  final VoidCallback onNmiInterrupted;

  Ppu2({required this.bus, required this.onNmiInterrupted});

  @override
  int totalFrames = 0;

  @override
  U8 get regData {
    U8 data_ret = bus.read(data_addr.data);
    if (data_addr.data < 0x3f00) {
      U8 tmp = data_buffer;
      data_buffer = data_ret;
      data_ret = tmp;
    } else {
      //data_buffer = p_bus->ram_data[data_addr.data & 0x3ff];
      data_buffer = bus.read(data_addr.data);
    }
    data_addr.data += reg_ctrl.addressIncrement;
    return data_ret;
  }

  @override
  set regData(U8 data) {
    bus.write(data_addr.data, data);
    data_addr.data += reg_ctrl.addressIncrement;
  }

  @override
  U8 get regOamData {
    return oamram.data[reg_oamaddr];
  }

  @override
  set regOamData(U8 regOamData) {
    oamram.data[reg_oamaddr] = regOamData;
    reg_oamaddr++;
  }

  @override
  void clock() {
    if (scanline == -1) {
      // PreRender扫描线
      if (cycle == 1) {
        reg_sta.vBlank = false;
        reg_sta.spriteZeroHit = false;
        reg_sta.spriteOverflow = false;
      }
      if (cycle == 258 && reg_mask.showBackground && reg_mask.showSprite) {
        data_addr.set_xscroll(tmp_addr.get_xscroll());
        data_addr.set_nametable_x(tmp_addr.get_nametable_x());
      }
      if (cycle >= 280 && cycle <= 304 && reg_mask.showBackground && reg_mask.showSprite) {
        data_addr.set_yscroll(tmp_addr.get_yscroll());
        data_addr.set_nametable_y(tmp_addr.get_nametable_y());
        data_addr.set_yfine(tmp_addr.get_yfine());
      }
    }
    if (scanline >= 0 && scanline < 240) {
      if (cycle > 0 && cycle <= 256) {
        int x = cycle - 1; //实际图像中的x和y
        int y = scanline;

        //这三个变量会用来确定颜色的优先级，背景的调色板id，精灵的调色板id，精灵是否在先
        U8 bkgcolor_in_palette = 0;
        U8 sprcolor_in_palette = 0;
        bool spr_behind_background = true;
        U16 bkg_palette_addr = 0;
        U16 spr_palette_addr = 0;

        if (reg_mask.showBackground) {
          U8 x_in_tile = (x + xfine) % 8; //根据偏移量，当前的x是tile中的第几个位置
          U8 y_in_tile = data_addr.get_yfine();
          if (x >= 8 || reg_mask.showLeftBackground) {
            //如果隐藏最左边八个像素的背景的话，那最左边八个像素的背景渲染就可以略掉
            //找出这个位置的命名表内容，找到对应的图案表的地址
            U16 nametable_addr = 0x2000 | (data_addr.data & 0x0fff);
            U8 tile_dx = bus.read(nametable_addr);
            // 读取图案表，获取这个像素点的颜色代码
            U16 patterntable_addr =
                tile_dx * 16 + y_in_tile; //每一个tile占据16个字节。然后根据y的fine滚动数值，来确定这个像素来对应tile的那个位置（tile中每一行就是一个字节）

            patterntable_addr += reg_ctrl.backgroundTableAddress;
            int low_bit = ((bus.read(patterntable_addr) >> (7 - x_in_tile)) & 1);
            int hi_bit = ((bus.read(patterntable_addr + 8) >> (7 - x_in_tile)) & 1);
            bkgcolor_in_palette = hi_bit << 1 + low_bit;
            // 读取属性表，得知这个像素点所在的tile对应的调色板id是什么
            U16 attrib_dx = ((data_addr.get_yscroll() >> 2) << 3) + ((data_addr.get_xscroll() >> 2) & 7);
            U16 attrib_addr = 0x23c0 +
                (data_addr.get_nametable_y().asInt() * 2 + data_addr.get_nametable_x().asInt()) * 0x400 +
                attrib_dx;
            U8 attr_dx = bus.read(attrib_addr);
            // y=16~32，x=16~32时，取attribute table的最高两位作为调色板索引。此时右移6位
            // y=16~32，x=0~15时，取attribute table的次高两位作为调色板索引。此时右移4位
            // y=0~15，x=16~32时，取attribute table的次低两位作为调色板索引。此时右移2位
            // y=0~15，x=0~15时，取attribute table的最低两位作为调色板索引。此时右移0位
            U8 attr_shift = ((data_addr.get_yscroll() & 2) << 1) + (data_addr.get_xscroll() & 2);
            U8 palette_dx = (attr_dx >> attr_shift) & 3;

            bkg_palette_addr = 0x3f00 + 4 * palette_dx + bkgcolor_in_palette;
          }
          // 如果已经到达了一个tile的最后一个像素，则真实像素的下一格就应该是下一个tile的第一个像素了
          if (x_in_tile == 7) {
            if (data_addr.get_xscroll() == 31) {
              data_addr.set_xscroll(0);
              data_addr.set_nametable_x(!data_addr.get_nametable_x()); //当已经到达这个命名表横轴上的最后一个位置时，则切换到下一个Horizental命名表
            } else {
              data_addr.set_xscroll(data_addr.get_xscroll() + 1);
            }
          }
        }
        if (reg_mask.showSprite) {
          if (x >= 8 || reg_mask.showLeftSprite) {
            for (int spr_it = 0; spr_it <= scanline_spr_cnt - 1; spr_it++) {
              U8 spr_dx = scanline_spr_dx[spr_it];
              OamSprite oam_1spr = OamSprite();
              //找出这个像素的的图案表的颜色代码
              if (reg_ctrl.spriteSize) {
                //渲染8*16的精灵

                oam_1spr = oamram.getSprite8x16(spr_dx);
                if (x - oam_1spr.positionX < 0 || x - oam_1spr.positionY >= 8) continue;
                U8 x_in_tile = (x - oam_1spr.positionX) & 0xff;
                U8 y_in_tile =
                    (y - 1 - oam_1spr.positionY) & 0xff; //Tips: 在第二个scanline，渲染的其实是第一个scanline中应该渲染的精灵，所以y轴的数值要减一
                if (oam_1spr.flipVertically) //x轴翻转
                  x_in_tile = 7 - x_in_tile;
                if (oam_1spr.flipHorizontally) //y轴翻转
                  y_in_tile = 15 - y_in_tile;
                //对于8*16的sprite，tile占据32个字节。然后根据y轴的数值，来确定这个像素来对应tile的那个位置（tile中每一行就是一个字节）
                U16 patterntable_addr;
                if (y_in_tile >= 8)
                  patterntable_addr = oam_1spr.patternTableAddress + 16 + (y_in_tile & 0x7);
                else
                  patterntable_addr = oam_1spr.patternTableAddress + (y_in_tile & 0x7);
                int low_bit = ((bus.read(patterntable_addr) >> (x_in_tile)) & 1);
                int hi_bit = ((bus.read(patterntable_addr + 8) >> (x_in_tile)) & 1);
                sprcolor_in_palette = (hi_bit << 1) & 0xff + low_bit;
              } else {
                //渲染8*8的精灵
                oam_1spr = oamram.getSprite8x8(spr_dx);
                if (x - oam_1spr.positionX < 0 || x - oam_1spr.positionX >= 8) continue;
                //找出这个像素的的图案表的颜色代码
                U8 x_in_tile = (x - oam_1spr.positionX) & 0xff;
                U8 y_in_tile =
                    (y - 1 - oam_1spr.positionY) & 0xff; //Tips: 在第二个scanline，渲染的其实是第一个scanline中应该渲染的精灵，所以y轴的数值要减一
                if (oam_1spr.flipVertically) //x轴翻转
                  x_in_tile = 7 - x_in_tile;
                if (oam_1spr.flipHorizontally) //y轴翻转
                  y_in_tile = 7 - y_in_tile;
                //对于8*8的sprite，tile占据16个字节。然后根据y轴的数值，来确定这个像素来对应tile的那个位置（tile中每一行就是一个字节）
                U16 patterntable_addr = oam_1spr.patternTableAddress + (y_in_tile & 0x7);

                patterntable_addr += reg_ctrl.spriteTableAddress;
                int low_bit = ((bus.read(patterntable_addr) >> (x_in_tile)) & 1);
                int hi_bit = ((bus.read(patterntable_addr + 8) >> (x_in_tile)) & 1);
                sprcolor_in_palette = (hi_bit << 1) & 0xff + low_bit;
              }
              //根据颜色代码来获取颜色。如果颜色代码为0的话，则这个像素不使用这个精灵的颜色，否则使用这个精灵的颜色
              if (sprcolor_in_palette == 0) continue;
              spr_palette_addr = 0x3f10 + 4 * oam_1spr.paletteId + sprcolor_in_palette;
              spr_behind_background = oam_1spr.behindBackground;
              //sprite 0 hit的触发条件是，当数值不为零的0号sprite与数值不为零的background在同一像素出现
              if (!reg_sta.spriteZeroHit && reg_mask.showBackground && spr_dx == 0 && bkgcolor_in_palette != 0) {
                reg_sta.spriteZeroHit = true;
              }
              break;
            }
          }
        }
        //根据背景色和精灵色，综合确定这个像素的颜色是什么
        U16 palette_addr;
        if (bkgcolor_in_palette == 0 && sprcolor_in_palette == 0)
          palette_addr = 0x3f00;
        else if (bkgcolor_in_palette != 0 && sprcolor_in_palette == 0)
          palette_addr = bkg_palette_addr;
        else if (bkgcolor_in_palette == 0 && sprcolor_in_palette != 0)
          palette_addr = spr_palette_addr;
        else {
          if (spr_behind_background)
            palette_addr = bkg_palette_addr;
          else
            palette_addr = spr_palette_addr;
        }
        frame_data.setPixel(x, y, nesSysPalettes.readColor(bus.read(palette_addr) & 0x3f));
      }
      if (cycle == 257 && reg_mask.showBackground) {
        U8 y_in_tile = data_addr.get_yfine();
        if (y_in_tile == 7) {
          data_addr.set_yfine(0);
          if (data_addr.get_yscroll() == 29) {
            data_addr.set_yscroll(0);
            data_addr.set_nametable_y(!data_addr.get_nametable_y());
          } else if (data_addr.get_yscroll() == 31) {
            //如果y超出了边界（30），例如把属性表中的数据当做tile读取的情况，则y到底后直接置为0，不切换命名表
            data_addr.set_yscroll(0);
          } else {
            data_addr.set_yscroll(data_addr.get_yscroll() + 1);
          }
        } else {
          data_addr.set_yfine(y_in_tile + 1);
        }
      }
      if (cycle == 258 && reg_mask.showBackground && reg_mask.showSprite) {
        data_addr.set_xscroll(tmp_addr.get_xscroll());
        data_addr.set_nametable_x(tmp_addr.get_nametable_x());
      }
      if (cycle == 340) {
        //获取下一条扫描线上需要渲染哪些精灵
        //先初始化下一条扫描线上需要渲染的精灵列表
        scanline_spr_cnt = 0;
        bool spr_overflow = false;
        //再获取这一条扫描线上需要获取的精灵列表，按照优先级排列前八个精灵。如果超过八个，则置sprite overflow为true
        U8 spr_length = reg_ctrl.spriteSize ? 16 : 8;
        for (U8 spr_it = 0; spr_it <= 63; spr_it++) {
          if (oamram.data[spr_it * 4] > scanline - spr_length && oamram.data[spr_it * 4] <= scanline) {
            if (scanline_spr_cnt == 8) {
              //qDebug() << "Sprite overflow, frame_dx = " << frame_dx << ", scanline = " << scanline << ", spr_it = " << spr_it << endl;
              spr_overflow = true;
              break;
            } else {
              scanline_spr_dx[scanline_spr_cnt] = spr_it;
              scanline_spr_cnt++;
            }
          }
        }
        reg_sta.spriteOverflow = spr_overflow;
      }
    }
    if (scanline == 240 && cycle == 0) {
      frame_finished++;
    }
    //垂直消隐阶段
    if (scanline >= 241) {
      if (scanline == 241 && cycle == 1) {
        //进入垂直消隐阶段时，调用CPU的NMI中断
        reg_sta.vBlank = true;
        if (reg_ctrl.generateNmi) {}
        // Cpu.nmi();
        //TODO
      }
    }
    //scanline和cycle递增
    if (scanline == -1 && cycle >= 340 - (!even_frame && reg_mask.showBackground && reg_mask.showSprite).asInt()) {
      // 渲染奇数像素时，会把第-1条扫描线的第340个周期直接过掉
      cycle = 0;
      scanline = 0;
    } else {
      cycle++;
      if (cycle == 341) {
        cycle = 0;
        scanline++;
        if (scanline >= 261) {
          even_frame = !even_frame;
          scanline = -1;
          frame_dx++;
          //qDebug() << "frame_dx = " << frame_dx << endl;
        }
      }
    }
  }

  @override
  set regController(U8 val) {
    reg_ctrl.data = val;
    tmp_addr.set_nametable(val & 0x3);
  }

  @override
  set regMask(U8 val) {
    reg_mask.data = val;
  }

  @override
  set regOamAddress(U8 val) {
    reg_oamaddr = val;
  }

  @override
  set regScroll(U8 scroll) {
    if (address_latch) {
      //输入值的高五位为x轴滚动，低三位为x轴的精细坐标
      tmp_addr.set_xscroll((scroll >> 3) & 0x1f);
      xfine = scroll & 0x7;
      address_latch = false;
    } else {
      tmp_addr.set_yscroll((scroll >> 3) & 0x1f);
      tmp_addr.set_yfine(scroll & 0x7);
      address_latch = true;
    }
  }

  @override
  U8 get regStatus {
    U8 data_ret = reg_sta.data;
    reg_sta.vBlank = false;
    address_latch = true;
    return data_ret;
  }

  @override
  void reset() {
    reg_ctrl.data = 0;
    reg_mask.data = 0;
    reg_sta.data = 0;

    address_latch = true;
    xfine = 0;
    tmp_addr.data = 0;
    data_addr.data = 0;
    data_buffer = 0;

    scanline = -1;
    cycle = 0;
    scanline_spr_cnt = 0;
    for (int i = 0; i < 256; i++) {
      oamram.data[i] = 0;
    }
    even_frame = true;

    frame_data.pixels.setAllZero();
  }

  @override
  set regAddress(U8 addr) {
    if (address_latch) {
      tmp_addr.set_hi6(addr & 0x3f);
      address_latch = false;
    } else {
      tmp_addr.set_low8(addr);
      data_addr.data = tmp_addr.data;
      address_latch = true;
    }
  }

  // PPU 寄存器
  PpuCtrl reg_ctrl = PpuCtrl();
  PpuMask reg_mask = PpuMask();
  PpuStatus reg_sta = PpuStatus();
  U8 reg_oamaddr = 0;
  bool address_latch = false;
  U8 xfine = 0;
  Reg tmp_addr = Reg();
  Reg data_addr = Reg();
  U8 data_buffer = 0;

  // PPU临时变量
  int scanline = 0; //第几条扫描线
  int cycle = 0; //这条扫描线的第几个周期
  Uint8List scanline_spr_dx = Uint8List(8);
  U8 scanline_spr_cnt = 0; //下一条扫描线上需要渲染的精灵个数

  OAM oamram = OAM(); //
  bool even_frame = false; //是不是偶数像素
  int frame_dx = 0;
  int frame_finished = -1;

  FrameBuffer frame_data = FrameBuffer(width: 256, height: 240);

  @override
  FrameBuffer get frameBuffer => frame_data;
}
