import 'package:dinogame/core/errors/exception.dart';
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

  // ============== Scan ==============

  @override
  Future<void> startScan() async {
    try {
      await _bleDataSource.startScan();
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("Repository tarama hatası: $e");
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await _bleDataSource.stopScan();
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("Repository tarama durdurma hatası: $e");
    }
  }

  @override
  Stream<List<BleDeviceEntity>> get scanDevices =>
      _bleDataSource.scanResultStream.map(
        (results) => results
            .map((r) => BleDeviceModel.fromScanResult(r).toEntity())
            .toList(),
      );

  // ============== Connection ==============

  @override
  Future<void> connect(String id) async {
    try {
      final device = BluetoothDevice.fromId(id);
      await _bleDataSource.connect(device);
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("Repository bağlantı hatası: $e");
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _bleDataSource.disconnect();
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("Repository disconnect hatası: $e");
    }
  }

  @override
  Stream<BluetoothConnectionState> get connectionState =>
      _bleDataSource.connectionStateStream;

  // ============== Services ==============

  @override
  List<BluetoothService> get discoverServices => _bleDataSource.services;

  // ============== Sensor Data ==============

  @override
  Future<void> subscribeToSensorData({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    try {
      await _bleDataSource.subscribeToCharacteristic(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("Repository subscribe hatası: $e");
    }
  }

  @override
  Future<void> unsubscribeFromSensorData() async {
    try {
      await _bleDataSource.unsubscribeFromCharacteristic();
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("Repository unsubscribe hatası: $e");
    }
  }

  @override
  Stream<String> get sensorDataStream => _bleDataSource.sensorDataStream;

  // ============== Cleanup ==============

  @override
  void disposeElements() {
    _bleDataSource.disposeElements();
  }
}
