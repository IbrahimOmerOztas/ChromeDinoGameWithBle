import 'dart:async';
import 'dart:convert';

import 'package:dinogame/core/errors/exception.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';

class BleService {
  //bu ble cihazlarının varlığını dinleyen stream yapisi
  final StreamController<List<ScanResult>> _scanResultController =
      StreamController.broadcast();
  Stream<List<ScanResult>> get scanResultStream => _scanResultController.stream;

  //adapterState durumunu dinleyen stream yapisi
  final StreamController<BluetoothAdapterState> _adapterStateController =
      StreamController.broadcast();
  Stream<BluetoothAdapterState> get adapterStateStream =>
      _adapterStateController.stream;

  //connectionState durumunu dinleyen stream yapısı
  final StreamController<BluetoothConnectionState> _connectionStateController =
      StreamController.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  final StreamController<String> _charDataController =
      StreamController.broadcast();
  Stream<String> get charDataStream => _charDataController.stream;

  //internals
  BluetoothDevice? connectedDevice;
  List<BluetoothService>? services;
  BluetoothAdapterState? adapterState;
  BluetoothCharacteristic? notifyChar;

  StreamSubscription<BluetoothAdapterState>? adapterSub;
  StreamSubscription<BluetoothConnectionState>? connSub;
  StreamSubscription<List<ScanResult>>? scanSub;
  StreamSubscription<List<int>>? charSub;

  List<BluetoothService>? get currentServices => services;

  @postConstruct
  void init() => _listenAdapter();

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      if (adapterState == BluetoothAdapterState.off) {
        throw BleException("Bluetooth kapali");
      }
      await stopScan();
      scanSub = FlutterBluePlus.scanResults.listen((results) {
        final filteredResults = results
            .where((r) => r.device.platformName.toLowerCase().contains("denge"))
            .toList();

        _scanResultController.add(filteredResults);
      });

      await FlutterBluePlus.startScan(timeout: timeout);

      //await Future.delayed(timeout);
    } catch (e) {
      throw BleException("tarama sirasinda bir hata olustu => $e");
    }
  }

  Future<void> stopScan() async {
    scanSub?.cancel();
    FlutterBluePlus.stopScan();
  }

  Future<void> _listenAdapter() async {
    adapterSub?.cancel();
    adapterSub = FlutterBluePlus.adapterState.listen((adapter) {
      _adapterStateController.add(adapter);
      adapterState = adapter;
    });
  }

  //------------------------connection----------------------

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await disconnectFromDevice();
      await listenToDeviceConnection(device);

      await device.connect(
        license: License.free,
        autoConnect: false,
        timeout: const Duration(seconds: 5),
      );

      connectedDevice = device;

      await discoverService();
    } catch (e) {
      throw BleException("Bağlanti sırasinda hata oluştu => $e");
    }
  }

  Future<void> listenToDeviceConnection(BluetoothDevice device) async {
    connSub?.cancel();

    connSub = device.connectionState.listen((connectionState) {
      _connectionStateController.add(connectionState);
      if (connectionState == BluetoothConnectionState.disconnected) {
        connectedDevice = null;
      }
    });
  }

  Future<void> disconnectFromDevice() async {
    connSub?.cancel();
    if (connectedDevice != null) {
      await connectedDevice?.disconnect();
      connectedDevice = null;
    }
  }

  //----------------------discover Services---------------------

  Future<void> discoverService() async {
    try {
      if (connectedDevice == null) {
        throw BleException("cihaz bağlantısı bulunamadi.");
      }
      final servs = await connectedDevice?.discoverServices();
      if (servs == null) {
        throw BleException("servis bulunamadi");
      }

      services = servs;
    } catch (e) {
      throw BleException("Serviceler keşfedilirken bir hata oluştu => $e");
    }
  }

  //----------------subscribe characteristic------------

  Future<void> subscribeToCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    try {
      if (services == null || services!.isEmpty) {
        throw BleException("Önce servicelerin alınması gerekiyor.");
      }

      final service = services!.firstWhere(
        (s) => s.uuid == Guid(serviceUuid),
        orElse: () =>
            throw BleException("İlgili service bulunamadı: $serviceUuid"),
      );

      final charr = service.characteristics.firstWhere(
        (c) => c.uuid == Guid(characteristicUuid),
        orElse: () => throw BleException(
          "İlgili characteristic bulunamadı: $characteristicUuid",
        ),
      );
      notifyChar = charr;

      if (notifyChar == null) {
        throw BleException("characteristics yok");
      }

      await notifyChar!.setNotifyValue(true);

      charSub?.cancel();
      charSub = notifyChar!.onValueReceived.listen(
        (data) {
          try {
            const asciiDecoder = AsciiDecoder();
            final value = asciiDecoder.convert(data);
            _charDataController.add(value);
          } catch (e) {
            _charDataController.addError("Veri çözümlenemedi: $e");
          }
        },
        onError: (error) {
          _charDataController.addError("Veri alınırken hata: $error");
        },
      );
    } catch (e) {
      throw BleException("Characteristic subscribe hatası: $e");
    }
  }

  /// Characteristic subscription'ı durdur
  Future<void> unsubscribeFromCharacteristic() async {
    try {
      charSub?.cancel();
      charSub = null;
      if (notifyChar != null) {
        await notifyChar!.setNotifyValue(false);
        notifyChar = null;
      }
    } catch (e) {
      throw BleException("Unsubscribe hatası: $e");
    }
  }

  //--------------------Calibration----------------

  Future<void> disposeElements() async {
    connSub?.cancel();
    adapterSub?.cancel();
    scanSub?.cancel();
    charSub?.cancel();

    _connectionStateController.close();
    _adapterStateController.close();
    _scanResultController.close();
    _charDataController.close();
  }
}
