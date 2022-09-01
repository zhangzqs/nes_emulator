// BusAdapter getDmaControllerAdapter({
//   required DmaController dmaController,
//   required int targetPage,
// }) {
//   return DmaControllerAdapter(this, dmaController, targetPage);
// }
part of 'cpu.dart';

/// 该控制器已集成到cpu内部
class DmaControllerAdapter implements BusAdapter {
  final CPU cpu;
  final DmaController dmaController;
  final U8 targetPage;
  DmaControllerAdapter(this.cpu, this.dmaController, this.targetPage);

  @override
  bool accept(U16 address) => address == 0x4014;

  @override
  U8 read(U16 address) => throw UnsupportedError('DMA controller cannot be read');

  @override
  void write(U16 address, U8 value) {
    // 启动DMA传输
    final page = value; // 页号
    // 开始拷贝
    dmaController.transferPage(page, targetPage);
    // 写入完毕需要更新剩余周期数, 之前的总周期若为奇数则等待513周期，偶数为514
    cpu._remainingCycles += 513 + (cpu.totalCycles % 2);
  }
}
