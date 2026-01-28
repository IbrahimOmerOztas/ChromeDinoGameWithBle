class BleDeviceEntity {
  final String id;
  final String name;
  final int rssi;
  final bool isConnectable;

  const BleDeviceEntity({
    required this.id,
    required this.name,
    required this.rssi,
    required this.isConnectable,
  });
}
