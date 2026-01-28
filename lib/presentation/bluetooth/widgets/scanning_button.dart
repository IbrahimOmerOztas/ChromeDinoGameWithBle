import 'package:flutter/material.dart';

/// Animasyonlu tarama butonu
class ScanningButton extends StatefulWidget {
  /// Tarama devam ediyor mu
  final bool isScanning;

  /// Buton tıklama callback'i
  final VoidCallback? onPressed;

  const ScanningButton({
    super.key,
    required this.isScanning,
    this.onPressed,
  });

  @override
  State<ScanningButton> createState() => _ScanningButtonState();
}

class _ScanningButtonState extends State<ScanningButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ScanningButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: widget.isScanning
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: FloatingActionButton.extended(
        onPressed: widget.onPressed,
        backgroundColor: widget.isScanning ? Colors.red : Colors.blue,
        icon: RotationTransition(
          turns: _controller,
          child: Icon(
            widget.isScanning ? Icons.stop : Icons.bluetooth_searching,
            color: Colors.white,
          ),
        ),
        label: Text(
          widget.isScanning ? 'Durdur' : 'Tara',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
