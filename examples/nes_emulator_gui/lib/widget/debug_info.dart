import 'package:flutter/material.dart';
import 'package:nes_emulator/framebuffer.dart';

import 'frame_canvas.dart';

class DebugInfoWidget extends StatelessWidget {
  final TileFrame? frame1, frame2;
  final Widget? palettesView;

  const DebugInfoWidget({Key? key, this.frame1, this.frame2, this.palettesView}) : super(key: key);

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
                  if (frame1 != null)
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: FrameCanvas(frame: frame1!),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (frame2 != null)
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: FrameCanvas(frame: frame2!),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (palettesView != null)
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: palettesView,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ));
  }
}
