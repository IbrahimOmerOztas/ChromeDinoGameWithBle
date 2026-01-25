// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../data/data_sources/ble_data_source.dart' as _i790;
import '../../data/repositories/ble_repositories_impl.dart' as _i217;
import '../../domain/repositories/ble_repositories.dart' as _i383;
import '../../presentation/bluetooth/bluetooth_controller.dart' as _i991;
import '../ble/ble_service.dart' as _i227;
import 'ble_module.dart' as _i178;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final bleModule = _$BleModule();
    gh.lazySingleton<_i227.BleService>(() => bleModule.bleService);
    gh.factory<_i790.BleDataSource>(
      () => _i790.BleDataSourceImpl(gh<_i227.BleService>()),
    );
    gh.factory<_i383.BleRepositories>(
      () => _i217.BleRepositoriesImpl(gh<_i790.BleDataSource>()),
    );
    gh.factory<_i991.BluetoothController>(
      () => _i991.BluetoothController(gh<_i383.BleRepositories>()),
    );
    return this;
  }
}

class _$BleModule extends _i178.BleModule {}
