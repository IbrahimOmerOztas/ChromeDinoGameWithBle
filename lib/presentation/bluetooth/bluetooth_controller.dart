import 'dart:async';

import 'package:dinogame/domain/repositories/ble_repositories.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/state_manager.dart';
import 'package:injectable/injectable.dart';

@injectable
class BluetoothController extends GetxController {
  final BleRepositories _bleRepositories;

  var devices = <ScanResult>[].obs;

  /// Bağlantı durumu
  final connectionState = BluetoothConnectionState.disconnected.obs;
  final deviceServices = <BluetoothService>[].obs;

  StreamSubscription<List<ScanResult>>? _scansub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<BluetoothService>>? _servicesSub;
  final isLoading = false.obs;

  BluetoothController(this._bleRepositories);

  Future<void> startScan() async {
    isLoading.value = true;
    await _bleRepositories.startScan();
    _scansub = _bleRepositories.scanResults.listen((results) {
      devices.value = results; // reactive state
    });

    isLoading.value = false;
  }

  Future<void> stopScan() async {
    await _bleRepositories.stopScan();
    _scansub?.cancel();
  }

  void _listenConnectionState() {
    _connSub?.cancel();

    _connSub = _bleRepositories.connectionState.listen((state) {
      connectionState.value = state;

      if (state == BluetoothConnectionState.disconnected) {
        // İstersen burada UI / game logic tetikleyebilirsin
        print("BLE bağlantı koptu");
      }
    });
  }

  void _listenDeviceServices() {
    _servicesSub?.cancel();

    _servicesSub = _bleRepositories.services.listen((services) {
      deviceServices.value = services;
    });
  }

  Future<void> connect(ScanResult result) async {
    await _bleRepositories.connect(result.device);
    print("bağlantı kurulan cihaz: ${result.device.platformName}");
    _listenConnectionState();

    await discoverServices();
    await Future.delayed(Duration(seconds: 2));

    _listenDeviceServices(); // önce dinle
    await _bleRepositories.discoverServices();
    for (var service in deviceServices) {
      print("service uuid: ${service.uuid}");
    }
  }

  Future<void> disconnect() async {
    await _bleRepositories.disconnect();
    _connSub?.cancel();
    _connSub = null;
  }

  Future<void> discoverServices() async {
    await _bleRepositories.discoverServices();

    final services = await _bleRepositories.services.first;

    for (var service in services) {
      print("SERVICE UUID: ${service.uuid}");
    }
  }

  @override
  void onClose() {
    _scansub?.cancel();
    _connSub?.cancel();
    _bleRepositories.disconnect();
    super.onClose();
  }
}
