import 'package:dinogame/data/data_sources/ble_data_source.dart';
import 'package:dinogame/domain/repositories/ble_repositories.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: BleRepositories)
class BleRepositoriesImpl extends BleRepositories {
  final BleDataSource _bleDataSource;

  BleRepositoriesImpl(this._bleDataSource);

  @override
  void disposeElements() {
    _bleDataSource.disposeElements();
  }

  @override
  Future<void> startScan() async {
    await _bleDataSource.startScan();
  }

  @override
  Future<void> stopScan() async {
    await _bleDataSource.stopScan();
  }

  @override
  Stream<List<ScanResult>> get scanResults => _bleDataSource.scanResults;

  @override
  Future<void> connect(BluetoothDevice device) async {
    await _bleDataSource.connect(device);
  }

  @override
  Stream<BluetoothConnectionState> get connectionState =>
      _bleDataSource.connectionState;

  @override
  Future<void> disconnect() async {
    await _bleDataSource.disconnect();
  }

  @override
  Future<void> discoverServices() async {
    await _bleDataSource.discoverServices();
  }

  @override
  Stream<List<BluetoothService>> get services => _bleDataSource.services;
}
