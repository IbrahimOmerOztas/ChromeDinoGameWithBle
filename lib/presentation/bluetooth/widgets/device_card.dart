import 'package:dinogame/domain/entites/ble_device_entity.dart';
import 'package:dinogame/presentation/bluetooth/widgets/signal_indicator.dart';
import 'package:flutter/material.dart';

/// BLE cihaz kartı widget'ı
class DeviceCard extends StatelessWidget {
  /// Cihaz entity
  final BleDeviceEntity device;

  /// Bağlanma callback'i
  final VoidCallback? onConnect;

  /// Kart seçili mi (bağlanıyor durumu için)
  final bool isConnecting;

  /// Zaten bağlı mı
  final bool isConnected;

  const DeviceCard({
    super.key,
    required this.device,
    this.onConnect,
    this.isConnecting = false,
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        elevation: isConnecting ? 8 : 2,
        borderRadius: BorderRadius.circular(16),
        color: _getBackgroundColor(theme),
        child: InkWell(
          onTap: isConnecting || isConnected ? null : onConnect,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Bluetooth Icon
                _buildDeviceIcon(),
                const SizedBox(width: 16),

                // Device Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isConnected ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.id,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isConnected
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Signal & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (device.rssi != 0)
                      SignalIndicator(
                        rssi: device.rssi,
                        size: 20,
                      ),
                    const SizedBox(height: 4),
                    _buildStatusChip(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.white.withOpacity(0.2)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isConnecting
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.blue),
              ),
            )
          : Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: isConnected ? Colors.white : Colors.blue,
              size: 24,
            ),
    );
  }

  Widget _buildStatusChip() {
    if (isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Bağlı',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (isConnecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Bağlanıyor...',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Bağlan',
        style: TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (isConnected) {
      return Colors.blue.shade600;
    }
    return theme.cardColor;
  }
}
