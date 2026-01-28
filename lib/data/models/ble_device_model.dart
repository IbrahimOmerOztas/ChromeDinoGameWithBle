import 'package:dinogame/domain/entites/ble_device_entity.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDeviceModel {
  final String id;
  final String name;
  final int rssi;
  final bool isConnectable;

  const BleDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    required this.isConnectable,
  });

  factory BleDeviceModel.fromScanResult(ScanResult scanResult) {
    return BleDeviceModel(
      id: scanResult.device.remoteId.str,
      name: scanResult.device.platformName.isNotEmpty
          ? scanResult.device.platformName
          : "Unknown",
      rssi: scanResult.rssi,
      isConnectable: scanResult.advertisementData.connectable,
    );
  }

  BleDeviceEntity toEntity() {
    return BleDeviceEntity(
      id: id,
      name: name,
      rssi: rssi,
      isConnectable: isConnectable,
    );
  }
}
