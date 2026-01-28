import 'package:dinogame/data/data_sources/ble_data_source.dart';
import 'package:dinogame/data/models/ble_device_model.dart';
import 'package:dinogame/domain/entites/ble_device_entity.dart';
import 'package:dinogame/domain/repositories/ble_repositories.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: BleRepositories)
class BleRepositoriesImpl implements BleRepositories {
  final BleDataSource _bleDataSource;

  BleRepositoriesImpl(this._bleDataSource);
  @override
  Future<void> connect(String id) async {
    try {
      final device = BluetoothDevice.fromId(id);
      await _bleDataSource.connect(device);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<BluetoothConnectionState> get connectionState =>
      _bleDataSource.connectionStateStream;
  @override
  Future<void> disconnect() async {
    try {
      await _bleDataSource.disconnect();
    } catch (e) {
      rethrow;
    }
  }

  @override
  List<BluetoothService> get discoverServices => _bleDataSource.services;

  @override
  void disposeElements() {
    _bleDataSource.disposeElements();
  }

  @override
  Future<void> startScan() async {
    try {
      await _bleDataSource.startScan();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await _bleDataSource.stopScan();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<BleDeviceEntity>> get scanDevices =>
      _bleDataSource.scanResultStream.map(
        (results) => results
            .map((r) => BleDeviceModel.fromScanResult(r).toEntity())
            .toList(),
      );
}
