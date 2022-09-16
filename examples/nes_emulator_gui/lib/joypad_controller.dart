import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nes_emulator/components.dart';

extension KeyExt on Widget {
  Widget ext(JoyPadController controller) {
    return KeyboardListener(
      focusNode: FocusNode(),
      child: this,
      onKeyEvent: (event) {
        final key = {
          LogicalKeyboardKey.keyW: JoyPadKey.up,
          LogicalKeyboardKey.keyS: JoyPadKey.down,
          LogicalKeyboardKey.keyA: JoyPadKey.left,
          LogicalKeyboardKey.keyD: JoyPadKey.right,
          LogicalKeyboardKey.keyG: JoyPadKey.select,
          LogicalKeyboardKey.keyH: JoyPadKey.start,
          LogicalKeyboardKey.keyJ: JoyPadKey.b,
          LogicalKeyboardKey.keyK: JoyPadKey.a,
        }[event.logicalKey];

        if (key == null) return;
        if (event is KeyUpEvent) {
          controller.release(key);
        } else {
          controller.press(key);
        }
      },
    );
  }
}
