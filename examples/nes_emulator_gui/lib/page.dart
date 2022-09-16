import 'package:flutter/material.dart';
import 'package:nes_emulator/controller/controller.dart';
import 'package:nes_emulator/nes_emulator.dart';
import 'package:nes_emulator_gui/joypad_controller.dart';
import 'package:nes_emulator_gui/nesbox_controller.dart';

import 'joypad.dart';
import 'widget/frame_canvas.dart';

extension WithBorder on Widget {
  Widget withBorder() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.red,
        ),
      ),
      child: this,
    );
  }
}

class GamePage extends StatelessWidget {
  final NesBoxController controller;

  const GamePage(this.controller, {super.key});

  Widget buildKeyBtn(JoyPadKey key, Widget button) {
    return InkWell(
        onTapDown: (e) => controller.controller1.press(key),
        onTapUp: (e) => controller.controller1.release(key),
        child: AbsorbPointer(child: button));
  }

  Widget buildBody(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        SizedBox(
          width: size.width,
          height: size.width / (256 / 240),
          child: StreamBuilder(
            stream: controller.frameStream,
            builder: (BuildContext context, AsyncSnapshot<FrameBuffer> snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              return FrameCanvas(frame: snapshot.data!);
            },
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox.fromSize(
                size: Size.square(100),
                child: DirectionKeyWidget(
                  onStateUpdate: (key) {
                    [JoyPadKey.down, JoyPadKey.right, JoyPadKey.up, JoyPadKey.left]
                        .forEach(controller.controller1.release);

                    switch (key) {
                      case null:
                        break;
                      case DirectionKey.rightDown:
                        controller.controller1.press(JoyPadKey.right);
                        controller.controller1.press(JoyPadKey.down);
                        break;
                      case DirectionKey.down:
                        controller.controller1.press(JoyPadKey.down);
                        break;
                      case DirectionKey.leftDown:
                        controller.controller1.press(JoyPadKey.left);
                        controller.controller1.press(JoyPadKey.down);
                        break;
                      case DirectionKey.left:
                        controller.controller1.press(JoyPadKey.left);
                        break;
                      case DirectionKey.leftTop:
                        controller.controller1.press(JoyPadKey.left);
                        controller.controller1.press(JoyPadKey.up);
                        break;
                      case DirectionKey.top:
                        controller.controller1.press(JoyPadKey.up);
                        break;
                      case DirectionKey.rightTop:
                        controller.controller1.press(JoyPadKey.up);
                        controller.controller1.press(JoyPadKey.right);
                        break;
                      case DirectionKey.right:
                        controller.controller1.press(JoyPadKey.right);
                        break;
                    }
                  },
                ),
              ),
              Row(
                children: [
                  buildKeyBtn(JoyPadKey.select, TextButton(onPressed: () {}, child: Text('Select'))),
                  buildKeyBtn(JoyPadKey.start, TextButton(onPressed: () {}, child: Text('Start'))),
                ],
              ).withBorder(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildKeyBtn(
                    JoyPadKey.b,
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: RawMaterialButton(
                        onPressed: () {},
                        shape: const CircleBorder(),
                        fillColor: Colors.red.withAlpha(127),
                        child: const Text('B'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  buildKeyBtn(
                    JoyPadKey.a,
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: RawMaterialButton(
                        onPressed: () {},
                        shape: const CircleBorder(),
                        fillColor: Colors.red.withAlpha(127),
                        child: const Text('A'),
                      ),
                    ),
                  ),
                ],
              ).withBorder(),
            ],
          ).withBorder(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder(
          stream: controller.fpsStream,
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox();
            }
            return Text('FPS: ${snapshot.data}');
          },
        ),
      ),
      body: buildBody(context).ext(controller.controller1),
    );
  }
}
