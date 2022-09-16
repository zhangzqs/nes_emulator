import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nes_emulator_gui/page.dart';

import 'nesbox_controller.dart';

class NesApp extends StatelessWidget {
  const NesApp({Key? key}) : super(key: key);

  Future<NesBoxController> loadGame() async {
    final boxController = NesBoxController();
    final gameData = await rootBundle.load('roms/Super_mario_brothers.nes');
    await boxController.loadGame(gameData.buffer.asUint8List());
    return boxController;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nes emulator',
      home: FutureBuilder<NesBoxController>(
        future: loadGame(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GamePage(snapshot.data!);
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NesApp());
}
