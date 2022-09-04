import 'package:flutter/material.dart';
import 'package:nes_emulator/controller/controller.dart';
import 'package:nes_emulator/framebuffer.dart';
import 'package:nes_emulator_gui/nesbox_controller.dart';

import '../widget/debug_info.dart';
import '../widget/frame_canvas.dart';

class GameScreen extends StatelessWidget {
  final NesBoxController nesController;
  // final _sound = FlutterSoundPlayer();
  GameScreen(this.nesController);
  Widget buildKeyBtn(String keyName, JoyPadKey key) {
    return InkWell(
      onTapDown: (e) => nesController.controller1.press(key),
      onTapUp: (e) => nesController.controller1.release(key),
      child: AbsorbPointer(
        child: ElevatedButton(
          onPressed: () {},
          child: Text(keyName),
        ),
      ),
    );
  }

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
          child: Column(
            children: [
              DebugInfoWidget(
                frame1: nesController.tileFrame1,
                frame2: nesController.tileFrame2,
              ),
              StreamBuilder(
                stream: nesController.paletteStream,
                builder: (BuildContext context, AsyncSnapshot<FrameBuffer> snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }
                  return FrameCanvas(frame: snapshot.data!);
                },
              ),
              StreamBuilder(
                stream: nesController.fpsStream,
                builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }
                  return Text('FPS: ${snapshot.data}');
                },
              ),
              Column(
                children: [
                  Row(
                    children: [
                      buildKeyBtn('Up', JoyPadKey.up),
                      buildKeyBtn('Down', JoyPadKey.down),
                      buildKeyBtn('Left', JoyPadKey.left),
                      buildKeyBtn('Right', JoyPadKey.right),
                    ],
                  ),
                  Row(
                    children: [
                      buildKeyBtn('Start', JoyPadKey.start),
                      buildKeyBtn('Select', JoyPadKey.select),
                      buildKeyBtn('B', JoyPadKey.b),
                      buildKeyBtn('A', JoyPadKey.a),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    return view;
  }
}
