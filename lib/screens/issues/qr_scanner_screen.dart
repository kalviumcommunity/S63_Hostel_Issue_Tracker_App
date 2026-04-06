import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        try {
          // Parse JSON from QR: {"block": "A", "room": "101"}
          final data = jsonDecode(barcode.rawValue!);
          if (data is Map<String, dynamic> && data.containsKey('block')) {
            _isScanned = true;
            Navigator.pop(context, data);
            return;
          }
        } catch (e) {
          // Invalid QR format, ignore and keep scanning
          debugPrint('Invalid QR format: ${barcode.rawValue}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Room QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6C63FF), width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, 
                color: Color(0xFF6C63FF), size: 100),
            ),
          ),
          
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Align the QR code inside the frame',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // MOCK SCAN RESULT: Mocking Block A, Room 101
                      final mockData = {'block': 'A', 'room': '101'};
                      Navigator.pop(context, mockData);
                    },
                    icon: const Icon(Icons.bug_report_rounded),
                    label: const Text('DEBUG: Simulate Scan (Room 101)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
