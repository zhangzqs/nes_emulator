import 'package:nes_emulator/util.dart';

enum Color {
  red,
  green,
  blue,
}

enum MaskFlag {
  isGreyScale, // 0: normal color, 1: produce a greyscale display
  leftmost8pxlBackground, // 1: Show background in leftmost 8 pixels of screen, 0: Hide
  leftmost8pxlSprite, // 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
  showBackground, // 1: Show background
  showSprite, // 1: Show sprites
  emphasiseRed, // red on PAL/Dendy
  emphasiseGreen, // green on PAL/Dendy
  emphasiseBlue, // blue on PAL/Dendy
}

class MaskRegister {
  FlagBits<MaskFlag> bits = FlagBits(0);

  MaskRegister();

  List<Color> emphasise() {
    return [
      if (bits[MaskFlag.emphasiseRed]) Color.red,
      if (bits[MaskFlag.emphasiseGreen]) Color.green,
      if (bits[MaskFlag.emphasiseBlue]) Color.blue,
    ];
  }
}
