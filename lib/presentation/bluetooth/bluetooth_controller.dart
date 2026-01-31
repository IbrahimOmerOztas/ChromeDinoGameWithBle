import 'dart:async';

import 'package:dinogame/core/errors/exception.dart';
import 'package:dinogame/domain/entites/ble_device_entity.dart';
import 'package:dinogame/domain/repositories/ble_repositories.dart';
import 'package:dinogame/presentation/bluetooth/ble_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:injectable/injectable.dart';

@injectable
class BluetoothController extends GetxController {
  final BleRepositories _bleRepositories;

  // ============== Observable States ==============

  /// Taranan cihazlar listesi
  final devices = <BleDeviceEntity>[].obs;

  /// Genel BLE durumu (idle, scanning, connecting, connected, error)
  final bleState = BleState.idle.obs;

  /// Bağlantı durumu (flutter_blue_plus)
  final connectionState = BluetoothConnectionState.disconnected.obs;

  /// Bağlı cihazın servisleri
  final deviceServices = <BluetoothService>[].obs;

  /// Bağlı cihaz bilgisi
  final connectedDevice = Rxn<BleDeviceEntity>();

  /// Hata mesajı
  final errorMessage = Rxn<String>();

  /// Sensör verisi
  final sensorData = Rxn<String>();

  /// Sensör verisini dinliyor mu
  final isListeningSensor = false.obs;

  // ============== Nordic UART UUIDs ==============

  /// Nordic UART Service (NUS) ana servis UUID'si
  static const String serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";

  /// Veri okuma (Notify) için kullanılan TX Karakteristik UUID'si
  static const String charUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  // ============== Internal Subscriptions ==============

  StreamSubscription<List<BleDeviceEntity>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<String>? _sensorSub;

  // ============== Computed Getters ==============

  bool get isScanning => bleState.value == BleState.scanning;
  bool get isConnected => bleState.value == BleState.connected;
  bool get isConnecting => bleState.value == BleState.connecting;
  bool get hasError => bleState.value == BleState.error;

  BluetoothController(this._bleRepositories);

  // ============== Scan Methods ==============

  Future<void> toggleScan() async {
    if (isScanning) {
      await stopScan();
    } else {
      await startScan();
    }
  }

  Future<void> startScan() async {
    try {
      _clearError();
      bleState.value = BleState.scanning;

      await _bleRepositories.startScan();

      _scanSub?.cancel();
      _scanSub = _bleRepositories.scanDevices.listen(
        (deviceEntities) {
          devices.assignAll(deviceEntities);
        },
        onError: (error) {
          _setError("Tarama sırasında hata: $error");
        },
      );
    } on BleException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError("Tarama başlatılamadı: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await _bleRepositories.stopScan();
      _scanSub?.cancel();
      _scanSub = null;

      if (bleState.value == BleState.scanning) {
        bleState.value = BleState.idle;
      }
    } on BleException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError("Tarama durdurulamadı: $e");
    }
  }

  // ============== Connection Methods ==============

  Future<void> connect(BleDeviceEntity entity) async {
    try {
      _clearError();
      bleState.value = BleState.connecting;

      await stopScan();
      _listenConnectionState();

      await _bleRepositories.connect(entity.id);

      connectedDevice.value = entity;
      bleState.value = BleState.connected;

      //await _discoverServices();
    } on BleException catch (e) {
      connectedDevice.value = null;
      _setError(e.message);
    } catch (e) {
      connectedDevice.value = null;
      _setError("Bağlantı kurulamadı: $e");
    }
  }

  Future<void> disconnect() async {
    try {
      // Önce sensör dinlemeyi durdur
      await stopListeningSensorData();

      await _bleRepositories.disconnect();
      _connSub?.cancel();
      _connSub = null;

      connectedDevice.value = null;
      deviceServices.clear();
      bleState.value = BleState.idle;
    } on BleException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError("Bağlantı kesilemedi: $e");
    }
  }

  Future<void> retryConnection() async {
    final device = connectedDevice.value;
    if (device != null) {
      await connect(device);
    } else {
      _clearError();
      bleState.value = BleState.idle;
    }
  }

  // ============== Sensor Data Methods ==============

  /// Sensör verisini dinlemeye başla
  Future<void> startListeningSensorData() async {
    try {
      if (!isConnected) {
        _setError("Önce bir cihaza bağlanmalısınız");
        return;
      }

      _clearError();
      isListeningSensor.value = true;

      await _bleRepositories.subscribeToSensorData(
        serviceUuid: serviceUuid,
        characteristicUuid: charUuid,
      );

      _sensorSub?.cancel();
      _sensorSub = _bleRepositories.sensorDataStream.listen(
        (data) {
          sensorData.value = data;
        },
        onError: (error) {
          _setError("Sensör verisi hatası: $error");
        },
      );
    } on BleException catch (e) {
      isListeningSensor.value = false;
      _setError(e.message);
    } catch (e) {
      isListeningSensor.value = false;
      _setError("Sensör verisi alınamadı: $e");
    }
  }

  /// Sensör verisini dinlemeyi durdur
  Future<void> stopListeningSensorData() async {
    try {
      _sensorSub?.cancel();
      _sensorSub = null;
      sensorData.value = null;
      isListeningSensor.value = false;

      await _bleRepositories.unsubscribeFromSensorData();
    } on BleException catch (e) {
      _setError(e.message);
    } catch (e) {
      // Hata olsa bile state'i sıfırla
      isListeningSensor.value = false;
    }
  }

  /// Sensör verisini toggle et
  Future<void> toggleSensorListening() async {
    if (isListeningSensor.value) {
      await stopListeningSensorData();
    } else {
      await startListeningSensorData();
    }
  }

  // ============== Private Methods ==============

  void _listenConnectionState() {
    _connSub?.cancel();

    _connSub = _bleRepositories.connectionState.listen((state) {
      connectionState.value = state;

      if (state == BluetoothConnectionState.disconnected) {
        if (bleState.value == BleState.connected) {
          connectedDevice.value = null;
          isListeningSensor.value = false;
          sensorData.value = null;
          bleState.value = BleState.idle;
        }
      }
    });
  }

  /*Future<void> _discoverServices() async {
    try {
      final services = _bleRepositories.discoverServices;
      deviceServices.assignAll(services);
    } catch (e) {
      deviceServices.clear();
    }
  }*/

  void _setError(String message) {
    errorMessage.value = message;
    bleState.value = BleState.error;
  }

  void _clearError() {
    errorMessage.value = null;
  }

  // ============== Lifecycle ==============

  @override
  void onClose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _sensorSub?.cancel();
    _bleRepositories.disconnect();
    super.onClose();
  }
}
