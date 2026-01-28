import 'package:dinogame/presentation/bluetooth/ble_state.dart';
import 'package:dinogame/presentation/bluetooth/bluetooth_controller.dart';
import 'package:dinogame/presentation/bluetooth/widgets/device_card.dart';
import 'package:dinogame/presentation/bluetooth/widgets/scanning_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BluetoothScreen extends StatelessWidget {
  BluetoothScreen({super.key});

  final BluetoothController controller = Get.find<BluetoothController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.startScan();
        },
        child: Obx(() => _buildBody()),
      ),
      floatingActionButton: Obx(
        () => ScanningButton(
          isScanning: controller.isScanning,
          onPressed: controller.toggleScan,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: const Text(
        'Bluetooth Cihazları',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        Obx(() {
          if (controller.isConnected) {
            return IconButton(
              onPressed: controller.disconnect,
              icon: const Icon(
                Icons.bluetooth_disabled,
                color: Colors.red,
              ),
              tooltip: 'Bağlantıyı Kes',
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildBody() {
    final state = controller.bleState.value;

    // Bağlı cihaz varsa en üstte göster
    final connectedDevice = controller.connectedDevice.value;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Status Header
        SliverToBoxAdapter(
          child: _buildStatusHeader(state),
        ),

        // Bağlı Cihaz
        if (connectedDevice != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'BAĞLI CİHAZ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  DeviceCard(
                    device: connectedDevice,
                    isConnected: true,
                    onConnect: null,
                  ),
                ],
              ),
            ),
          ),

        // Error State
        if (state == BleState.error)
          SliverToBoxAdapter(
            child: _buildErrorWidget(),
          ),

        // Diğer Cihazlar Başlık
        if (controller.devices.isNotEmpty && state != BleState.error)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'BULUNAN CİHAZLAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

        // Device List veya Empty State
        if (state == BleState.error)
          const SliverToBoxAdapter(child: SizedBox.shrink())
        else if (controller.devices.isEmpty && state != BleState.scanning)
          SliverFillRemaining(
            child: _buildEmptyState(),
          )
        else
          _buildDeviceList(),
      ],
    );
  }

  Widget _buildStatusHeader(BleState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getStatusGradient(state),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getStatusGradient(state).first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatusIcon(state),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(state),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusSubtitle(state),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BleState state) {
    IconData icon;
    switch (state) {
      case BleState.scanning:
        icon = Icons.bluetooth_searching;
        break;
      case BleState.connecting:
        icon = Icons.bluetooth;
        break;
      case BleState.connected:
        icon = Icons.bluetooth_connected;
        break;
      case BleState.error:
        icon = Icons.bluetooth_disabled;
        break;
      case BleState.idle:
      default:
        icon = Icons.bluetooth;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: state == BleState.scanning
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            )
          : Icon(icon, color: Colors.white, size: 28),
    );
  }

  List<Color> _getStatusGradient(BleState state) {
    switch (state) {
      case BleState.scanning:
        return [Colors.blue.shade400, Colors.blue.shade700];
      case BleState.connecting:
        return [Colors.orange.shade400, Colors.orange.shade700];
      case BleState.connected:
        return [Colors.green.shade400, Colors.green.shade700];
      case BleState.error:
        return [Colors.red.shade400, Colors.red.shade700];
      case BleState.idle:
      default:
        return [Colors.blueGrey.shade400, Colors.blueGrey.shade700];
    }
  }

  String _getStatusTitle(BleState state) {
    switch (state) {
      case BleState.scanning:
        return 'Taranıyor...';
      case BleState.connecting:
        return 'Bağlanıyor...';
      case BleState.connected:
        return 'Bağlı';
      case BleState.error:
        return 'Hata!';
      case BleState.idle:
      default:
        return 'Hazır';
    }
  }

  String _getStatusSubtitle(BleState state) {
    switch (state) {
      case BleState.scanning:
        return '${controller.devices.length} cihaz bulundu';
      case BleState.connecting:
        return 'Lütfen bekleyin...';
      case BleState.connected:
        return controller.connectedDevice.value?.name ?? 'Cihaza bağlı';
      case BleState.error:
        return controller.errorMessage.value ?? 'Bir hata oluştu';
      case BleState.idle:
      default:
        return 'Tarama başlatmak için butona basın';
    }
  }

  Widget _buildEmptyState() {
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
            child: Icon(
              Icons.bluetooth_searching,
              size: 50,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cihaz Bulunamadı',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yakındaki Bluetooth cihazlarını\nbulmak için tarama başlatın',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 80), // FAB için boşluk
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.errorMessage.value ?? 'Bir hata oluştu',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          TextButton(
            onPressed: controller.retryConnection,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    final devices = controller.devices;
    final connectedDeviceId = controller.connectedDevice.value?.id;

    // Bağlı cihazı listeden çıkar
    final otherDevices =
        devices.where((d) => d.id != connectedDeviceId).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final device = otherDevices[index];
          final isConnecting = controller.isConnecting &&
              controller.connectedDevice.value?.id == device.id;

          return DeviceCard(
            device: device,
            isConnecting: isConnecting,
            isConnected: false,
            onConnect: () => controller.connect(device),
          );
        },
        childCount: otherDevices.length,
      ),
    );
  }
}
