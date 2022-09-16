import 'dart:io';
import 'dart:isolate';

import 'package:nes_emulator/cartridge/cartridge.dart';
import 'package:nes_emulator/cartridge/nes_file.dart';
import 'package:nes_emulator/framebuffer.dart';
import 'package:nes_emulator/nes.dart';

Future<void> create() async {
  final receivePort = ReceivePort();

  // 在创建isolate时，将
  final sendPort = receivePort.sendPort;

  late SendPort subSendPort;
  receivePort.listen((message) {
    // 子isolate向主isolate传递消息
    print('主isolate收到消息：$message');
    if (message is SendPort) {
      subSendPort = message;
    } else {}
  });

  await Isolate.spawn<SendPort>(doWork, sendPort);
}

void doWork(SendPort mainSendPort) {
  final receivePort = ReceivePort();

  // 需要将此sendPort传递给主isolate
  final sendPort = receivePort.sendPort;
  mainSendPort.send(sendPort);

  Nes nes = Nes(
    cartridge: Cartridge(NesFileReader(File('testfiles/nestest.nes').readAsBytesSync())),
    sampleRate: 44100,
    videoOutput: (FrameBuffer frame) {
      mainSendPort.send(frame);
    },
  );

  receivePort.listen((message) {
    // 主isolate向子isolate传递消息
    print('子isolate收到消息：$message');
  });

  while (true) {
    print('进入循环');
    nes.nextFrame();
    sleep(Duration(milliseconds: 16));
  }
}

Future<void> main() async {
  await create();
  print('程序结束');
  await Future.delayed(Duration(seconds: 10));
}
