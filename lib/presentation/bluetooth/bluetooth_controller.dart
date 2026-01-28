import 'dart:async';

import 'package:dinogame/domain/entites/ble_device_entity.dart';
import 'package:dinogame/domain/repositories/ble_repositories.dart';
import 'package:dinogame/presentation/bluetooth/ble_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/state_manager.dart';
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

  // ============== Internal Subscriptions ==============

  StreamSubscription<List<BleDeviceEntity>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  // ============== Computed Getters ==============

  /// Tarama devam ediyor mu?
  bool get isScanning => bleState.value == BleState.scanning;

  /// Cihaza bağlı mı?
  bool get isConnected => bleState.value == BleState.connected;

  /// Bağlanma işlemi devam ediyor mu?
  bool get isConnecting => bleState.value == BleState.connecting;

  /// Hata var mı?
  bool get hasError => bleState.value == BleState.error;

  BluetoothController(this._bleRepositories);

  // ============== Scan Methods ==============

  /// Taramayı başlat/durdur toggle
  Future<void> toggleScan() async {
    if (isScanning) {
      await stopScan();
    } else {
      await startScan();
    }
  }

  /// Cihaz taramasını başlat
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
    } catch (e) {
      _setError("Tarama başlatılamadı: $e");
    }
  }

  /// Cihaz taramasını durdur
  Future<void> stopScan() async {
    await _bleRepositories.stopScan();
    _scanSub?.cancel();
    _scanSub = null;

    if (bleState.value == BleState.scanning) {
      bleState.value = BleState.idle;
    }
  }

  // ============== Connection Methods ==============

  /// Seçilen cihaza bağlan
  Future<void> connect(BleDeviceEntity entity) async {
    try {
      _clearError();
      bleState.value = BleState.connecting;

      // Taramayı durdur
      await stopScan();

      // Bağlantı state'ini dinlemeye başla
      _listenConnectionState();

      // Cihaza bağlan
      await _bleRepositories.connect(entity.id);

      // Başarılı bağlantı
      connectedDevice.value = entity;
      bleState.value = BleState.connected;

      // Servisleri keşfet
      await _discoverServices();
    } catch (e) {
      connectedDevice.value = null;
      _setError("Bağlantı kurulamadı: $e");
    }
  }

  /// Bağlantıyı kes
  Future<void> disconnect() async {
    try {
      await _bleRepositories.disconnect();
      _connSub?.cancel();
      _connSub = null;

      connectedDevice.value = null;
      deviceServices.clear();
      bleState.value = BleState.idle;
    } catch (e) {
      _setError("Bağlantı kesilemedi: $e");
    }
  }

  /// Bağlantıyı yeniden dene
  Future<void> retryConnection() async {
    final device = connectedDevice.value;
    if (device != null) {
      await connect(device);
    } else {
      _clearError();
      bleState.value = BleState.idle;
    }
  }

  // ============== Private Methods ==============

  void _listenConnectionState() {
    _connSub?.cancel();

    _connSub = _bleRepositories.connectionState.listen((state) {
      connectionState.value = state;

      if (state == BluetoothConnectionState.disconnected) {
        // Beklenmedik bağlantı kopması
        if (bleState.value == BleState.connected) {
          connectedDevice.value = null;
          bleState.value = BleState.idle;
        }
      }
    });
  }

  Future<void> _discoverServices() async {
    try {
      final services = _bleRepositories.discoverServices;
      deviceServices.assignAll(services);
    } catch (e) {
      // Service keşfi başarısız olsa bile bağlantı devam edebilir
      deviceServices.clear();
    }
  }

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
    _bleRepositories.disconnect();
    super.onClose();
  }
}
