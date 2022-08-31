import 'package:flutter/material.dart';

import 'nesbox_controller.dart';
import 'screen/game.dart';

class FicoApp extends StatelessWidget {
  final NesBoxController nesController;
  const FicoApp(this.nesController, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: GameScreen(nesController)),
    );
  }
}
