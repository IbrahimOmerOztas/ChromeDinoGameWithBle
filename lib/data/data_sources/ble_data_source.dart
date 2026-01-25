import 'package:dinogame/core/ble/ble_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';

abstract class BleDataSource {
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

@Injectable(as: BleDataSource)
class BleDataSourceImpl implements BleDataSource {
  final BleService _bleService;

  BleDataSourceImpl(this._bleService);

  @override
  void disposeElements() {
    _bleService.dispose();
  }

  @override
  Future<void> startScan() async {
    await _bleService.startScan();
  }

  @override
  Future<void> stopScan() async {
    await _bleService.stopScan();
  }

  @override
  Stream<List<ScanResult>> get scanResults => _bleService.scanResultStream;

  @override
  Future<void> connect(BluetoothDevice device) async {
    await _bleService.connectToDevice(device);
  }

  @override
  Future<void> disconnect() async {
    await _bleService.disconnect();
  }

  @override
  Stream<BluetoothConnectionState> get connectionState =>
      _bleService.connectionStateStream;

  @override
  Future<void> discoverServices() async {
    await _bleService.discoverServices();
  }

  @override
  Stream<List<BluetoothService>> get services => _bleService.servicesStream;
}
