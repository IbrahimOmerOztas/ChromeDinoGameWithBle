import 'dart:async';

import 'package:dinogame/domain/entites/ble_sample_entity.dart';
import 'package:dinogame/presentation/bluetooth/bluetooth_controller.dart';
import 'package:dinogame/presentation/game/obstacle_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SensorDataScreen extends StatefulWidget {
  const SensorDataScreen({super.key});

  @override
  State<SensorDataScreen> createState() => _SensorDataScreenState();
}

class _SensorDataScreenState extends State<SensorDataScreen> {
  final BluetoothController controller = Get.find<BluetoothController>();

  // Oyun durumu
  bool isGameMode = false;
  bool isGameOver = false;
  int currentScore = 0;

  ObstacleGame? _game;
  StreamSubscription? _sensorSubscription;

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.compass_calibration, color: Colors.yellow, size: 28),
            SizedBox(width: 12),
            Text(
              'Kalibrasyon Gerekli',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Oyuna başlamadan önce cihazı kalibre etmeniz gerekmektedir.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.yellow, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cihazı düz bir zeminde sabit tutun ve Kalibre Et butonuna basın.',
                      style: TextStyle(color: Colors.yellow, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          Obx(() {
            final isCalibrating = controller.isCalibrating.value;
            return ElevatedButton(
              onPressed: isCalibrating
                  ? null
                  : () async {
                      await controller.calibrate();
                      if (!controller.hasError && mounted) {
                        Navigator.pop(context);
                        _startGame();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
                foregroundColor: Colors.black,
              ),
              child: isCalibrating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.black),
                      ),
                    )
                  : const Text('Kalibre Et'),
            );
          }),
        ],
      ),
    );
  }

  void _startGame() {
    setState(() {
      isGameMode = true;
      isGameOver = false;
      currentScore = 0;
    });

    _game = ObstacleGame(
      onGameOver: () {
        setState(() {
          isGameOver = true;
        });
      },
      onScoreUpdate: (score) {
        setState(() {
          currentScore = score;
        });
      },
    );

    // Sensör verilerini dinle ve oyuna ilet
    controller.startListeningSensorData();
    _sensorSubscription = controller.sensorData.listen((data) {
      if (data != null && _game != null) {
        _game!.updatePlayerPosition(data.y);
      }
    });
  }

  void _exitGame() {
    _sensorSubscription?.cancel();
    controller.stopListeningSensorData();
    setState(() {
      isGameMode = false;
      isGameOver = false;
      currentScore = 0;
      _game = null;
    });
  }

  void _restartGame() {
    _game?.restart();
    setState(() {
      isGameOver = false;
      currentScore = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isGameMode) {
      return _buildGameScreen();
    }
    return _buildSensorScreen();
  }

  Widget _buildGameScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            // Oyun
            if (_game != null)
              GameWidget(game: _game!),

            // Üst bilgi çubuğu
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Geri butonu
                    IconButton(
                      onPressed: _exitGame,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    // Skor
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.yellow, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$currentScore',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pause butonu
                    IconButton(
                      onPressed: () {
                        _game?.togglePause();
                        setState(() {});
                      },
                      icon: Icon(
                        _game?.isPaused == true ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Game Over ekranı
            if (isGameOver)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sentiment_dissatisfied,
                        size: 80,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'OYUN BİTTİ!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Skor: $currentScore',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _restartGame,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tekrar Oyna'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _exitGame,
                            icon: const Icon(Icons.exit_to_app),
                            label: const Text('Çıkış'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorScreen() {
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
            // OYUN BAŞLAT BUTONU
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isConnected && !isListening && !isCalibrating
                    ? _showCalibrationDialog
                    : null,
                icon: const Icon(Icons.gamepad),
                label: const Text('Oyunu Başlat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
