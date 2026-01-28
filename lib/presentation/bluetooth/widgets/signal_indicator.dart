import 'package:flutter/material.dart';

/// RSSI sinyal gücü göstergesi widget'ı
class SignalIndicator extends StatelessWidget {
  /// RSSI değeri (genelde -100 ile 0 arasında)
  final int rssi;

  /// Icon boyutu
  final double size;

  const SignalIndicator({
    super.key,
    required this.rssi,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getSignalIcon(),
          color: _getSignalColor(),
          size: size,
        ),
        const SizedBox(width: 4),
        Text(
          '$rssi dBm',
          style: TextStyle(
            fontSize: size * 0.5,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// RSSI değerine göre sinyal ikonu
  IconData _getSignalIcon() {
    if (rssi >= -50) {
      return Icons.signal_cellular_4_bar;
    } else if (rssi >= -60) {
      return Icons.network_cell;
    } else if (rssi >= -70) {
      return Icons.signal_cellular_alt_2_bar;
    } else {
      return Icons.signal_cellular_alt_1_bar;
    }
  }

  /// RSSI değerine göre sinyal rengi
  Color _getSignalColor() {
    if (rssi >= -50) {
      return Colors.green;
    } else if (rssi >= -60) {
      return Colors.lightGreen;
    } else if (rssi >= -70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Sinyal gücü açıklaması
  static String getSignalQuality(int rssi) {
    if (rssi >= -50) return 'Mükemmel';
    if (rssi >= -60) return 'İyi';
    if (rssi >= -70) return 'Orta';
    return 'Zayıf';
  }
}
