import 'dart:async';

import 'package:dinogame/domain/entites/ble_device_entity.dart';
import 'package:dinogame/domain/repositories/ble_repositories.dart';
import 'package:dinogame/presentation/bluetooth/ble_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:injectable/injectable.dart';

@injectable
class DenemeController extends GetxController {
  final BleRepositories _bleRepositories;

  //---------------Obsorvable State----------------

  final devices = <BleDeviceEntity>[].obs; //ble device yapılarını görmek için
  final bleState = BleState.idle.obs;
  final connectionState = BluetoothConnectionState.disconnected.obs;
  final deviceServices = Rxn<List<BluetoothService>>();
  final connectedDevice = Rxn<BleDeviceEntity>();
  final errorMessage = Rxn<String>();

  //--------------internal Subscriptions------------
  StreamSubscription<List<BleDeviceEntity>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  //--------------computed Getters-------------
  bool get isScanning => bleState.value == BleState.scanning;
  bool get isConnected => bleState.value == BleState.connected;
  bool get isConnecting => bleState.value == BleState.connecting;
  bool get hasError => bleState.value == BleState.error;

  DenemeController(this._bleRepositories);

  //--------Scan Methods-------------

  Future<void> toggleScan() async {
    if (isScanning) {
      await stopScan();
    } else {
      await startScan();
    }
  }

  Future<void> startScan() async {
    try {
      _scanSub?.cancel();
      bleState.value = BleState.idle;
      _scanSub = _bleRepositories.scanDevices.listen((results) {
        devices.assignAll(results);
      });
      bleState.value = BleState.scanning;
      await _bleRepositories.startScan();
      bleState.value = BleState.idle;
    } catch (e) {
      bleState.value = BleState.idle;
      _setError(e.toString());
    }
  }

  Future<void> stopScan() async {
    try {
      _scanSub?.cancel();
      await _bleRepositories.stopScan();
      _scanSub = null;

      if (bleState.value == BleState.scanning) {
        bleState.value = BleState.idle;
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setError(String error) {
    errorMessage.value = error;
    bleState.value = BleState.error;
  }

  void _clearError() {
    errorMessage.value = null;
  }

  @override
  void onClose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _bleRepositories.disconnect();

    super.onClose();
  }
}
