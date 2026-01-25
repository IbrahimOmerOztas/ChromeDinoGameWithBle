import 'package:dinogame/presentation/bluetooth/bluetooth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:get/state_manager.dart';

class BluetoothScreen extends StatelessWidget {
  BluetoothScreen({super.key});
  final BluetoothController controller = Get.find<BluetoothController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("bluetooth"),
        actions: [
          IconButton(
            onPressed: controller.startScan,
            icon: Icon(Icons.bluetooth, color: Colors.blue),
          ),
        ],
      ),
      body: Center(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }
          final devices = controller.devices;
          if (devices.isEmpty) {
            return Center(child: Text("Cihaz Bulunamadı"));
          }
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: GestureDetector(
                  onTap: () {
                    controller.connect(device);
                  },
                  child: Card(
                    child: Text(
                      device.device.platformName.isNotEmpty
                          ? device.device.platformName
                          : "İsimsiz cihaz",
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
