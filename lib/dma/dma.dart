import '../bus_adapter.dart';
import '../common.dart';

class DmaController {
  final BusAdapter sourceBus;
  final BusAdapter targetBus;
  DmaController({required this.sourceBus, required this.targetBus});

  // 开始传送
  void transfer(U16 sourceAddress, U16 size, U16 targetAddress) {
    for (int i = 0; i < size; i++) {
      final val = sourceBus.read(sourceAddress + i);
      targetBus.write(targetAddress + i, val);
    }
  }

  // 按页面传送(一页256字节)
  void transferPage(U8 sourcePage, U8 targetPage) => transfer(sourcePage << 8, 0x100, targetPage << 8);
}
