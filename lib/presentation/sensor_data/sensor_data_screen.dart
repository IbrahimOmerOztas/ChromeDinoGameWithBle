import 'package:dinogame/domain/entites/ble_sample_entity.dart';
import 'package:dinogame/presentation/bluetooth/bluetooth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SensorDataScreen extends StatelessWidget {
  SensorDataScreen({super.key});

  final BluetoothController controller = Get.find<BluetoothController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Bağlı Cihaz Bilgisi
            buildDeviceInfo(),

            // Ana Veri Gösterimi
            Expanded(child: _buildSensorDisplay()),

            // Kontrol Butonları (Kalibrasyon Dahil)
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Sensör Verileri',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      actions: [
        Obx(() {
          // Hem dinleme hem kalibrasyon sırasında yükleme ikonu göster
          if (controller.isListeningSensor.value ||
              controller.isCalibrating.value) {
            return Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.yellow),
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget buildDeviceInfo() {
    return Obx(() {
      final isCalibrating = controller.isCalibrating.value;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          border: Border.all(
            color: isCalibrating
                ? Colors.yellow
                : (controller.isConnected ? Colors.green : Colors.grey),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: (isCalibrating ? Colors.yellow : Colors.green)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCalibrating
                    ? Icons.published_with_changes
                    : Icons.bluetooth_connected,
                color: isCalibrating ? Colors.yellow : Colors.green,
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.connectedDevice.value != null)
                  Text(
                    controller.connectedDevice.value!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                const SizedBox(height: 5),
                Text(
                  isCalibrating ? "Kalibre Ediliyor..." : "Bağlı",
                  style: TextStyle(
                    color: isCalibrating ? Colors.yellow : Colors.green,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (controller.connectedDevice.value != null)
              Text(
                "${controller.connectedDevice.value!.rssi} dBm",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSensorDisplay() {
    return Obx(() {
      final data = controller.sensorData.value;
      final isListening = controller.isListeningSensor.value;
      final isCalibrating = controller.isCalibrating.value;

      if (controller.hasError) {
        return _buildErrorState(controller.errorMessage.value ?? "Hata");
      }

      if (isCalibrating) {
        return _buildWaitingState(
          "Sıfır Noktası Belirleniyor...",
          "Cihazı düz bir zeminde sabit tutun.",
        );
      }

      if (!isListening && data == null) {
        return _buildIdleState();
      }

      if (isListening && data == null) {
        return _buildWaitingState(
          "Veri Bekleniyor...",
          "Bluetooth üzerinden paketler aranıyor.",
        );
      }

      return _buildDataDisplay(data!);
    });
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 24),
          const Text(
            'Sensör Uyku Modunda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Önce kalibrasyon yapmanız\nve ardından başlatmanız önerilir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.yellow),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDisplay(BleSampleEntity data) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "MERKEZE GÖRE KONUM",
            style: TextStyle(
              color: Colors.grey,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildCoordinateCard("X EKSENİ", data.x, Colors.blue),
              const SizedBox(width: 16),
              _buildCoordinateCard("Y EKSENİ", data.y, Colors.purple),
            ],
          ),
          const SizedBox(height: 40),
          // Görsel bir gösterge (Opsiyonel)
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Transform.translate(
                offset: Offset(
                  data.x * 2,
                  data.y * 2,
                ), // Veriye göre hareket eden nokta
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateCard(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: Colors.red)),
          TextButton(
            onPressed: controller.retryConnection,
            child: const Text("Tekrar Dene"),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Obx(() {
      final isListening = controller.isListeningSensor.value;
      final isCalibrating = controller.isCalibrating.value;
      final isConnected = controller.isConnected;

      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // KALİBRASYON BUTONU
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected && !isListening && !isCalibrating
                        ? controller.calibrate
                        : null,
                    icon: const Icon(Icons.compass_calibration),
                    label: const Text('Kalibre Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // BAŞLAT/DURDUR BUTONU
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isConnected && !isCalibrating
                        ? controller.toggleSensorListening
                        : null,
                    icon: Icon(isListening ? Icons.pause : Icons.play_arrow),
                    label: Text(isListening ? 'Durdur' : 'Başlat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isListening ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // KES BUTONU
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: isConnected
                    ? () async {
                        await controller.disconnect();
                        Get.back();
                      }
                    : null,
                icon: const Icon(Icons.bluetooth_disabled, color: Colors.grey),
                label: const Text(
                  'Bağlantıyı Kes',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
