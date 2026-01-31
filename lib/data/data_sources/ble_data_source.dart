import 'package:dinogame/core/ble/ble_service.dart';
import 'package:dinogame/core/errors/exception.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';

abstract class BleDataSource {
  //streams
  Stream<List<ScanResult>> get scanResultStream;
  Stream<BluetoothAdapterState> get adapterStateStream;
  Stream<BluetoothConnectionState> get connectionStateStream;
  Stream<String> get sensorDataStream;

  //Methods
  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(BluetoothDevice device);
  Future<void> disconnect();
  Future<void> disposeElements();
  Future<void> subscribeToCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  });
  Future<void> unsubscribeFromCharacteristic();

  //cache Access
  List<BluetoothService> get services;
}

@Injectable(as: BleDataSource)
class BleDataSourceImpl implements BleDataSource {
  final BleService _bleService;

  BleDataSourceImpl(this._bleService);

  @override
  Stream<BluetoothAdapterState> get adapterStateStream =>
      _bleService.adapterStateStream;

  @override
  Stream<String> get sensorDataStream => _bleService.charDataStream;

  @override
  Future<void> connect(BluetoothDevice device) async {
    try {
      await _bleService.connectToDevice(device);
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("DataSource bağlantı hatası: $e");
    }
  }

  @override
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _bleService.connectionStateStream;

  @override
  Future<void> disconnect() async {
    try {
      await _bleService.disconnectFromDevice();
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("DataSource disconnect hatası: $e");
    }
  }

  @override
  Stream<List<ScanResult>> get scanResultStream => _bleService.scanResultStream;

  @override
  List<BluetoothService> get services => _bleService.currentServices ?? [];

  @override
  Future<void> startScan() async {
    try {
      await _bleService.startScan();
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("DataSource tarama hatası: $e");
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await _bleService.stopScan();
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("DataSource tarama durdurma hatası: $e");
    }
  }

  @override
  Future<void> disposeElements() async {
    try {
      await _bleService.disposeElements();
    } catch (e) {
      throw BleException("DataSource dispose hatası: $e");
    }
  }

  @override
  Future<void> subscribeToCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    try {
      await _bleService.subscribeToCharacteristic(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("DataSource subscribe hatası: $e");
    }
  }

  @override
  Future<void> unsubscribeFromCharacteristic() async {
    try {
      await _bleService.unsubscribeFromCharacteristic();
    } on BleException {
      rethrow;
    } catch (e) {
      throw BleException("DataSource unsubscribe hatası: $e");
    }
  }
}
