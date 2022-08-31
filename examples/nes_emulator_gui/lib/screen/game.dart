import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nes_emulator/controller/controller.dart';

import '../nesbox_controller.dart';
import '../widget/frame_canvas.dart';

class GameScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final boxController = useNesBoxController();
    final snapshot = useStream(boxController.frameStream);

    useEffect(() {
      boxController.loadGame();
    }, []);

    if (!snapshot.hasData) return const SizedBox();

    final view = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: FrameCanvas(frame: snapshot.data!)),
        // const Expanded(flex: 1, child: DebugInfoWidget()),
      ],
    );
    return KeyboardListener(
      focusNode: FocusNode(),
      child: view,
      onKeyEvent: (event) {
        print('按键事件: ${event.logicalKey}');

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
          boxController.controller1.release(key);
        } else if (key is KeyDownEvent) {
          boxController.controller1.press(key);
        }
      },
    );
  }
}
