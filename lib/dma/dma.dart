import '../bus_adapter.dart';
import '../common.dart';

class DmaController {
  final Readable source;
  final Writable target;
  DmaController({required this.source, required this.target});

  // 开始传送
  void transfer(U16 sourceAddress, U16 size, U16 targetAddress) {
    for (int i = 0; i < size; i++) {
      final val = source.read(sourceAddress + i);
      target.write(targetAddress + i, val);
    }
  }

  // 按页面传送(一页256字节)
  void transferPage(U8 sourcePage, U8 targetPage) => transfer(sourcePage << 8, 0x100, targetPage << 8);
}
