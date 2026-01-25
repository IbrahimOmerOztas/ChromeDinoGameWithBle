import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BleRepositories {
  Future<void> startScan();
  Future<void> stopScan();
  void disposeElements();
  Future<void> connect(BluetoothDevice device);
  Future<void> disconnect();
  Future<void> discoverServices();
  Stream<List<ScanResult>> get scanResults;
  Stream<BluetoothConnectionState> get connectionState;
  Stream<List<BluetoothService>> get services;
}
