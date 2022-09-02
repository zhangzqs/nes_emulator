import 'package:flutter/material.dart';
import 'package:nes_emulator/framebuffer.dart';

import 'frame_canvas.dart';

class DebugInfoWidget extends StatelessWidget {
  final TileFrame? frame1, frame2;
  final Widget? palettesView;
  final Widget? fpsView;
  const DebugInfoWidget({Key? key, this.frame1, this.frame2, this.palettesView, this.fpsView}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (palettesView != null)
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 8,
                        child: palettesView,
                      ),
                    ),
                ],
              ),
              if (fpsView != null) fpsView!,
            ],
          ),
        ));
  }
}
