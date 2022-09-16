import 'dart:math';

import 'package:flutter/material.dart';

// 方向键绘制
class DirectionalKeyPainter extends CustomPainter {
  final int? id;
  final Offset offset;
  DirectionalKeyPainter({
    this.id,
    this.offset = const Offset(0, 0),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 白色清屏
    final rect = const Offset(0.0, 0.0) & size;
    canvas.drawOval(
      rect,
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke,
    );

    for (int i = 0; i < 8; i++) {
      canvas.drawArc(
        rect,
        (pi / 4) * i + (pi / 8),
        (pi / 4),
        true,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke,
      );
    }

    if (id != null) {
      canvas.drawArc(
        rect,
        (pi / 4) * id! + (pi / 8),
        (pi / 4),
        true,
        Paint()..color = Colors.blue,
      );
    }
    drawSmallCircle(
      canvas,
      rect,
      rect.inflate(-20).translate(offset.dx, offset.dy),
    );
  }

  void drawSmallCircle(Canvas canvas, Rect parentRect, Rect selfRect) {
    // 限制位移
    selfRect = Rect.fromLTWH(
      min(
        max(parentRect.left, selfRect.left),
        parentRect.right - selfRect.width,
      ),
      min(
        max(parentRect.top, selfRect.top),
        parentRect.bottom - selfRect.height,
      ),
      selfRect.width,
      selfRect.height,
    );
    canvas.drawOval(
      selfRect,
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
        selfRect,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

enum DirectionKey { rightDown, down, leftDown, left, leftTop, top, rightTop, right }

class DirectionKeyWidget extends StatefulWidget {
  final void Function(DirectionKey? key)? onStateUpdate;

  const DirectionKeyWidget({
    Key? key,
    this.onStateUpdate,
  }) : super(key: key);

  @override
  State<DirectionKeyWidget> createState() => _DirectionKeyWidgetState();
}

class _DirectionKeyWidgetState extends State<DirectionKeyWidget> {
  final ValueNotifier<int?> idNotifier = ValueNotifier(null);
  Offset offset = const Offset(0, 0);

  @override
  void initState() {
    idNotifier.addListener(() {
      if (widget.onStateUpdate != null) {
        widget.onStateUpdate!(idNotifier.value == null ? null : DirectionKey.values[idNotifier.value! % 8]);
      }
    });
    super.initState();
  }

  void _updatePanLocation(Offset location, Size size) {
    final offset = location;

    // 坐标系平移至圆心
    final newOffset = offset.translate(-size.width / 2, -size.height / 2);
    var angle = newOffset.direction;

    // 这里也无需映射了，负数角度实际上平移2pi周期后就变正数了，
    // 不影响后面的三角函数计算结果
    // if (angle < 0) angle = angle + 2 * pi;

    // (pi / 4) * i + (pi / 8) < angle < (pi / 4) * (i+1) + (pi / 8)
    // i < (angle - (pi/8)) / (pi/4) < i+1
    // i = floor((angle - (pi/8)) / (pi/4))

    final newI = ((angle - (pi / 8)) / (pi / 4)).floor();
    setState(() {
      idNotifier.value = newI;
      this.offset = newOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.smallest;

        return GestureDetector(
          child: CustomPaint(
            painter: DirectionalKeyPainter(
              id: idNotifier.value,
              offset: offset,
            ),
          ),
          onPanStart: (details) {
            _updatePanLocation(details.localPosition, size);
          },
          onPanEnd: (d) {
            setState(() {
              offset = const Offset(0, 0);
              idNotifier.value = null;
            });
          },
          onPanUpdate: (DragUpdateDetails details) {
            _updatePanLocation(details.localPosition, size);
          },
        );
      },
    );
  }
}
