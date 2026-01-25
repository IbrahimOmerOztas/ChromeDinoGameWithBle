import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart'; // Hata verirse build_runner çalıştırınca düzelir

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // Default: init
  preferRelativeImports: true, // Importları clean tutar
  asExtension: true, // Extension metodu olarak kullanır
)
Future<void> configureDependencies() async => getIt.init();
