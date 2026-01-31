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
            //_buildDeviceInfo(),
            buildDeviceInfo(),

            // Ana Veri Gösterimi
            Expanded(child: _buildSensorDisplay()),

            // Kontrol Butonları
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
          if (controller.isListeningSensor.value) {
            return Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.greenAccent),
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

  Widget _buildDeviceInfo() {
    return Obx(() {
      final device = controller.connectedDevice.value;

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: controller.isConnected ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: controller.isConnected
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                controller.isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: controller.isConnected ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device?.name ?? 'Bağlı Değil',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.isConnected ? 'Bağlı' : 'Bağlantı Yok',
                    style: TextStyle(
                      color: controller.isConnected
                          ? Colors.green[300]
                          : Colors.red[300],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Sinyal göstergesi
            if (device != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${device.rssi} dBm',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget buildDeviceInfo() {
    return Obx(() {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: controller.isListeningSensor.value
                ? Colors.yellow
                : Colors.grey,
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
                color: Colors.yellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bluetooth_connected, color: Colors.yellow),
            ),
            SizedBox(width: 15),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.connectedDevice.value != null)
                  Text(
                    controller.connectedDevice.value!.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                SizedBox(height: 5),
                if (controller.connectedDevice.value != null)
                  Text("Bağlı", style: TextStyle(color: Colors.yellow)),
              ],
            ),
            SizedBox(width: 30),
            Container(
              height: 30,
              width: 75,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${controller.connectedDevice.value!.rssi} dBm",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
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
      final error = controller.errorMessage.value;

      // Error durumu
      if (controller.hasError && error != null) {
        return _buildErrorState(error);
      }

      // Henüz dinleme başlamamış
      if (!isListening && data == null) {
        return _buildIdleState();
      }

      // Dinleniyor ama veri yok
      if (isListening && data == null) {
        return _buildWaitingState();
      }

      // Veri var
      return _buildDataDisplay(data!);
    });
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sensors, size: 50, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sensör Verisi Bekleniyor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veri almaya başlamak için\naşağıdaki butona basın',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Veri Bekleniyor...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sensörden veri alınıyor',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDisplay(String data) {
    // Veriyi parse et (örn: "X:123,Y:456,Z:789")
    final parts = data.split(',');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ana Veri Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'RAW DATA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ayrıştırılmış Veriler
          if (parts.length > 1)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: parts.length,
                itemBuilder: (context, index) {
                  return _buildDataCard(parts[index], index);
                },
              ),
            )
          else
            Expanded(child: Center(child: _buildLargeDataCard(data))),
        ],
      ),
    );
  }

  Widget _buildDataCard(String value, int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'VALUE ${index + 1}',
            style: TextStyle(
              color: color.shade300,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.trim(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLargeDataCard(String data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.data_usage, size: 48, color: Colors.blue.shade300),
          const SizedBox(height: 16),
          Text(
            data,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 50, color: Colors.red),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hata Oluştu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[300], fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.retryConnection,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Obx(() {
      final isListening = controller.isListeningSensor.value;
      final isConnected = controller.isConnected;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Start/Stop Butonu
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isConnected
                    ? controller.toggleSensorListening
                    : null,
                icon: Icon(isListening ? Icons.stop : Icons.play_arrow),
                label: Text(isListening ? 'Durdur' : 'Başlat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isListening ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Disconnect Butonu
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isConnected
                    ? () async {
                        await controller.disconnect();
                        Get.back();
                      }
                    : null,
                icon: const Icon(Icons.bluetooth_disabled),
                label: const Text('Kes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
