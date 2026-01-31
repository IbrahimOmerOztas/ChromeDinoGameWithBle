import 'package:dinogame/presentation/bluetooth/bluetooth_binding.dart';
import 'package:dinogame/presentation/bluetooth/bluetooth_screen.dart';
import 'package:dinogame/presentation/sensor_data/sensor_data_screen.dart';
import 'package:dinogame/presentation/splash/splash_binding.dart';
import 'package:dinogame/presentation/splash/splash_screen.dart';
import 'package:get/get.dart';

abstract class AppRoutes {
  static const String initial = splash;
  static const String splash = "/splash";
  static const String bluetooth = "/bluetooth";
  static const String sensorData = "/sensor-data";

  static final pages = <GetPage>[
    GetPage(
      name: splash,
      page: () => SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: bluetooth,
      page: () => BluetoothScreen(),
      binding: BluetoothBinding(),
    ),
    GetPage(
      name: sensorData,
      page: () => SensorDataScreen(),
      // BluetoothController zaten bind edilmiş olacak
    ),
  ];
}
