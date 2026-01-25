import 'package:dinogame/core/ble/ble_service.dart';
import 'package:injectable/injectable.dart';

@module
abstract class BleModule {
  @lazySingleton
  BleService get bleService => BleService();
}
