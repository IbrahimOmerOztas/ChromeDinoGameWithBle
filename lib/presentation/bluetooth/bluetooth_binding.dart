import 'package:dinogame/core/di/injection.dart';
import 'package:dinogame/presentation/bluetooth/bluetooth_controller.dart';
import 'package:get/instance_manager.dart';

class BluetoothBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BluetoothController>(() => getIt<BluetoothController>());
  }
}
