import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  final StreamController<List<ScanResult>> _scanResultController =
      StreamController.broadcast();
  Stream<List<ScanResult>> get scanResultStream => _scanResultController.stream;

  // cihaz bağlantı durumunu dinlemek için
  final StreamController<BluetoothConnectionState> _connectionStateController =
      StreamController.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  //Serviceleri keşfetmek için
  final StreamController<List<BluetoothService>> _services =
      StreamController.broadcast();
  Stream<List<BluetoothService>> get servicesStream => _services.stream;

  StreamSubscription? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  BluetoothDevice? _connectedDevice;

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    bool granted = await requestBluetoothPermissions();
    if (!granted) {
      print("Bluetooth izinleri verilmedi!");
      return;
    }
    await stopScan();

    //taramayi baslat
    FlutterBluePlus.startScan(timeout: timeout);

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      final filteredResults = results
          .where(
            (r) =>
                r.device.platformName.contains("denge") ||
                r.device.platformName.contains("Denge"),
          )
          .toList();
      _scanResultController.add(filteredResults);
    });

    Future.delayed(timeout, () async {
      await stopScan();
    });
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
  }

  // ---------------------------connect to Device-----------------------------

  Future<void> connectToDevice(BluetoothDevice device) async {
    await disconnect(); //bağlı cihaz varsa bağlantıyı koparıyor.
    await device.connect(
      license: License.free,
      timeout: const Duration(seconds: 10),
      autoConnect: false,
    );

    _connectedDevice = device;
    _connectionSubscription = device.connectionState.listen((state) {
      _connectionStateController.add(state);
    });
  }

  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }

  //-------------------"discover services"---------------------
  Future<void> discoverServices() async {
    if (_connectedDevice == null) return;

    List<BluetoothService> services = await _connectedDevice!
        .discoverServices();

    _services.add(services);
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();

    _scanResultController.close();
    _connectionStateController.close();
  }

  Future<bool> requestBluetoothPermissions() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.locationWhenInUse.request().isGranted) {
      return true;
    }
    return false;
  }
}

class BleSample {
  final double axisX;
  final double axisY;

  BleSample({required this.axisX, required this.axisY});
}
