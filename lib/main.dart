import 'package:dinogame/core/di/injection.dart';
import 'package:dinogame/presentation/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeConfiguration();

  runApp(const MyApp());
}

Future<void> initializeConfiguration() async {
  await configureDependencies();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      initialRoute: AppRoutes.initial,
      getPages: AppRoutes.pages,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
    );
  }
}
