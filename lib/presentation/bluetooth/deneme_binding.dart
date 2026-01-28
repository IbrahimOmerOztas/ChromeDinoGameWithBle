import 'package:dinogame/core/di/injection.dart';
import 'package:dinogame/presentation/bluetooth/deneme_controller.dart';
import 'package:get/instance_manager.dart';

class DenemeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DenemeController>(() => getIt<DenemeController>());
  }
}
