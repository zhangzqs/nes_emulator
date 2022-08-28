import 'device.dart';

/// 可以把总线本身也看作可寻址的设备
class Bus implements AddressableDevice {
  final List<AddressableDevice> devices = [];

  /// 注册所有的从设备
  void registerDevice(AddressableDevice device) => devices.add(device);

  AddressableDevice? _findDeviceByAddress(U16 address) {
    for (final device in devices) {
      if (device.accept(address)) return device;
    }
    return null;
  }

  @override
  U8 read(U16 address) => _findDeviceByAddress(address)?.read(address) ?? 0;

  @override
  void write(U16 address, U8 value) => _findDeviceByAddress(address)?.write(address, value);

  @override
  bool accept(U16 address) => (address <= 0xFFFF);
}
