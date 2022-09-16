import 'dart:io';
import 'dart:isolate';

void main() {
  print("main isolate start");
  create_isolate();
  print("main isolate end");
}

// 创建一个新的 isolate
create_isolate() async {
  ReceivePort rp = new ReceivePort();
  SendPort port1 = rp.sendPort;

  Isolate newIsolate = await Isolate.spawn(doWork, port1);

  SendPort? port2;
  rp.listen((message) {
    print("main isolate message: $message");
    if (message[0] == 0) {
      port2 = message[1];
    } else {
      port2?.send([1, "这条信息是 main isolate 发送的"]);
    }
  });
}

// 处理耗时任务
void doWork(SendPort port1) {
  print("new isolate start");
  ReceivePort rp2 = new ReceivePort();
  SendPort port2 = rp2.sendPort;

  rp2.listen((message) {
    print("doWork message: $message");
  });

  // 将新isolate中创建的SendPort发送到主isolate中用于通信
  port1.send([0, port2]);
  // 模拟耗时5秒
  sleep(Duration(seconds: 5));
  port1.send([1, "doWork 任务完成"]);

  print("new isolate end");
}
