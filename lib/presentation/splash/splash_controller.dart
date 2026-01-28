import 'package:dinogame/presentation/routing/app_routes.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/state_manager.dart';

class SplashController extends GetxController {
  @override
  void onInit() async {
    super.onInit();

    await Future.delayed(Duration(seconds: 2));

    Get.offAllNamed(AppRoutes.deneme);
  }
}
