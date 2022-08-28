import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nes_emulator/nes.dart';

import '../nesbox_controller.dart';
import 'frame_canvas.dart';

class DebugInfoWidget extends HookWidget {
  const DebugInfoWidget({
    Key? key,
    required this.boxController,
  }) : super(key: key);

  final NesBoxController boxController;

  Nes get nes => boxController.nes;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: AspectRatio(aspectRatio: 1, child: FrameCanvas(frame: nes.cartridge.firstTileFrame))),
                const SizedBox(width: 8),
                Expanded(child: AspectRatio(aspectRatio: 1, child: FrameCanvas(frame: nes.cartridge.secondTileFrame))),
              ],
            )),
            Text(nes.board.cpu.totalCycles.toString()),
          ],
        ));
  }
}
