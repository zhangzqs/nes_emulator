import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nes_emulator/controller/controller.dart';

import 'app.dart';
import 'nesbox_controller.dart';

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
          LogicalKeyboardKey.keyJ: JoyPadKey.a,
          LogicalKeyboardKey.keyK: JoyPadKey.b,
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boxController = NesBoxController();
  await boxController.loadGame();
  runApp(FicoApp(boxController).ext(boxController.controller1));
}
