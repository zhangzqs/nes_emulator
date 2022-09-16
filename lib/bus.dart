import 'bus_adapter.dart';
import 'common.dart';

/// 可以把总线本身也看作可寻址的设备
class Bus implements BusAdapter {
  final List<BusAdapter> devices = [];
  late List<BusAdapter?> addressedDeviceList;

  /// 注册所有的从设备
  void registerDevices(List<BusAdapter> devices) {
    this.devices.addAll(devices);
    addressedDeviceList = List.generate(0x10000, (address) {
      for (final device in devices) {
        if (device.accept(address)) return device;
      }
      return null;
    });
  }

  @override
  U8 read(U16 address) {
    address &= 0xffff;
    final value = addressedDeviceList[address]?.read(address) ?? 0;
    return value & 0xFF;
  }

  @override
  void write(U16 address, U8 value) {
    address &= 0xffff;
    value &= 0xff;
    addressedDeviceList[address]?.write(address, value);
  }

  @override
  bool accept(U16 address) => (address <= 0 && address <= 0xFFFF);
}
