import 'package:dinogame/presentation/bluetooth/bluetooth_binding.dart';
import 'package:dinogame/presentation/bluetooth/bluetooth_screen.dart';
import 'package:dinogame/presentation/splash/splash_binding.dart';
import 'package:dinogame/presentation/splash/splash_screen.dart';
import 'package:get/get.dart';

abstract class AppRoutes {
  static final String initial = splash;
  static final String splash = "/splash";
  static final String bluetooth = "/bluetooth";

  static final pages = <GetPage>[
    GetPage(name: splash, page: () => SplashScreen(), binding: SplashBinding()),
    GetPage(
      name: bluetooth,
      page: () => BluetoothScreen(),
      binding: BluetoothBinding(),
    ),
  ];
}
