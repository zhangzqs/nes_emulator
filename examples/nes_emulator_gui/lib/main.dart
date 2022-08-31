import 'package:flutter/material.dart';

import 'app.dart';
import 'nesbox_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boxController = NesBoxController();
  await boxController.loadGame();
  runApp(FicoApp(boxController));
}
