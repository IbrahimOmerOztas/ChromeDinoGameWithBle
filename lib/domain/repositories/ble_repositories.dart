import 'package:dinogame/domain/entites/ble_device_entity.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BleRepositories {
  Future<void> startScan();
  Future<void> stopScan();
  void disposeElements();
  Future<void> connect(String id);
  Future<void> disconnect();
  List<BluetoothService> get discoverServices;
  Stream<List<BleDeviceEntity>> get scanDevices;
  Stream<BluetoothConnectionState> get connectionState;
}
