import 'dart:async';

import 'package:dinogame/core/errors/exception.dart';
import 'package:dinogame/data/data_sources/ble_data_source.dart';
import 'package:dinogame/data/models/ble_device_model.dart';
import 'package:dinogame/domain/entites/ble_calibration_entity.dart';
import 'package:dinogame/domain/entites/ble_device_entity.dart';
import 'package:dinogame/domain/entites/ble_sample_entity.dart';
import 'package:dinogame/domain/repositories/ble_repositories.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: BleRepositories)
class BleRepositoriesImpl implements BleRepositories {
  final BleDataSource _bleDataSource;

  BleRepositoriesImpl(this._bleDataSource);

  final StreamController<BleSampleEntity> _bleSampleEntityController =
      StreamController.broadcast();
  bool _isCalibrating = false;
  final List<BleSampleEntity> _calibrationBuffer = [];
  BleCalibrationEntity _currentCalibration = BleCalibrationEntity();
  BleCalibrationEntity get currentCalibration => _currentCalibration;

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
  Stream<BleSampleEntity> get sensorDataStream {
    return _bleDataSource.sensorDataStream.map((rawString) {
      final sample = _parseRawString(rawString);

      if (_isCalibrating) {
        _calibrationBuffer.add(sample);
      }

      return BleSampleEntity(
        x: sample.x - _currentCalibration.offsetX,
        y: sample.y - _currentCalibration.offsetY,
      );
    }); // raw veri BleSample entity formatına dönüştürülmesi gerekiyor.
  }

  BleSampleEntity _parseRawString(String raw) {
    final parts = raw.split(':');
    if (parts.length == 2) {
      return BleSampleEntity(
        x: double.tryParse(parts[0]) ?? 0.0,
        y: double.tryParse(parts[1]) ?? 0.0,
      );
    }
    return BleSampleEntity(x: 0, y: 0);
  }

  void _calculateAndSetOffsets() {
    if (_calibrationBuffer.isEmpty) return;
    final avgX =
        _calibrationBuffer.map((e) => e.x).reduce((a, b) => a + b) /
        _calibrationBuffer.length;
    final avgY =
        _calibrationBuffer.map((e) => e.y).reduce((a, b) => a + b) /
        _calibrationBuffer.length;
    _currentCalibration = BleCalibrationEntity(offsetX: avgX, offsetY: avgY);
  }

  // ============== Cleanup ==============

  @override
  void disposeElements() {
    _bleDataSource.disposeElements();
  }

  @override
  Future<void> startCalibration({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    try {
      _calibrationBuffer.clear();
      _isCalibrating = true;
      await _bleDataSource.subscribeToCharacteristic(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );

      await Future.delayed(Duration(seconds: 3)); // 3 saniye boyunca çalışacak
      _calculateAndSetOffsets();
      _isCalibrating = false;
      await _bleDataSource.unsubscribeFromCharacteristic();
    } catch (e) {
      _isCalibrating = false;
      rethrow;
    }
  }
}
