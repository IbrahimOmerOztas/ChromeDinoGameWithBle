import 'package:dinogame/domain/entites/ble_device_entity.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BleRepositories {
  // Scan
  Future<void> startScan();
  Future<void> stopScan();
  Stream<List<BleDeviceEntity>> get scanDevices;

  // Connection
  Future<void> connect(String id);
  Future<void> disconnect();
  Stream<BluetoothConnectionState> get connectionState;

  // Services
  List<BluetoothService> get discoverServices;

  // Sensor Data
  Future<void> subscribeToSensorData({
    required String serviceUuid,
    required String characteristicUuid,
  });
  Future<void> unsubscribeFromSensorData();
  Stream<String> get sensorDataStream;

  // Cleanup
  void disposeElements();
}
