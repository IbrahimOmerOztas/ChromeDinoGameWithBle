import 'package:dinogame/core/ble/ble_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';

abstract class BleDataSource {
  //streams

  Stream<List<ScanResult>> get scanResultStream;
  Stream<BluetoothAdapterState> get adapterStateStream;
  Stream<BluetoothConnectionState> get connectionStateStream;

  //Methods
  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(BluetoothDevice device);
  Future<void> disconnect();
  Future<void> disposeElements();

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
  Future<void> connect(BluetoothDevice device) async {
    try {
      await _bleService.connectToDevice(device);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _bleService.connectionStateStream;

  @override
  Future<void> disconnect() async {
    try {
      await _bleService.disconnectFromDevice();
    } catch (e) {
      rethrow;
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
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await _bleService.stopScan();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> disposeElements() async {
    await _bleService.disposeElements();
  }
}
