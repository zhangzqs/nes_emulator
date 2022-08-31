import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nes_emulator/controller/controller.dart';
import 'package:nes_emulator/framebuffer.dart';
import 'package:nes_emulator_gui/nesbox_controller.dart';

import '../widget/debug_info.dart';
import '../widget/frame_canvas.dart';

class GameScreen extends StatelessWidget {
  final NesBoxController nesController;
  GameScreen(this.nesController);
  @override
  Widget build(BuildContext context) {
    final view = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
            flex: 2,
            child: StreamBuilder(
              stream: nesController.frameStream,
              builder: (BuildContext context, AsyncSnapshot<FrameBuffer> snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }
                return FrameCanvas(frame: snapshot.data!);
              },
            )),
        Expanded(
          flex: 1,
          child: DebugInfoWidget(
            frame1: nesController.tileFrame1,
            frame2: nesController.tileFrame2,
          ),
        ),
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
          nesController.controller1.release(key);
        } else if (key is KeyDownEvent) {
          nesController.controller1.press(key);
        }
      },
    );
  }
}
