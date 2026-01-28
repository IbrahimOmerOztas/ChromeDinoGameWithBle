import 'package:dinogame/presentation/bluetooth/deneme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DenemeScreen extends StatelessWidget {
  DenemeScreen({super.key});
  final DenemeController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bluetooth Cihazları"), centerTitle: true),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          onPressed: controller.toggleScan,
          backgroundColor: controller.isScanning ? Colors.red : Colors.blue,
        ),
      ),
      body: Center(
        child: Obx(() {
          final devices = controller.devices;

          if (controller.isScanning) {
            return CircularProgressIndicator();
          }
          if (devices.isEmpty) {
            return Text("device yoookk");
          }

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              Text(devices[index].name);
            },
          );
        }),
      ),
    );
  }
}
