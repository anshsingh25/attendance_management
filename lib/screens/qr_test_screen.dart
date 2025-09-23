import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';

class QRTestScreen extends StatefulWidget {
  const QRTestScreen({super.key});

  @override
  State<QRTestScreen> createState() => _QRTestScreenState();
}

class _QRTestScreenState extends State<QRTestScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String qrData = 'Test QR Code - ${DateTime.now().millisecondsSinceEpoch}';
  bool isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Platform-specific content
            if (Platform.isMacOS) ...[
              _buildQRGenerator(),
            ] else if (Platform.isIOS) ...[
              _buildQRScanner(),
            ] else ...[
              _buildUniversalView(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQRGenerator() {
    return Expanded(
      child: Column(
        children: [
          const Text(
            'QR Code Generator (macOS)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'QR Data: $qrData',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                qrData = 'Test QR Code - ${DateTime.now().millisecondsSinceEpoch}';
              });
            },
            child: const Text('Generate New QR Code'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Instructions:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '1. This QR code is generated on macOS\n'
            '2. Use your iPhone to scan this QR code\n'
            '3. The iPhone app will show the scanned data',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanner() {
    return Expanded(
      child: Column(
        children: [
          const Text(
            'QR Code Scanner (iPhone)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 3,
            child: isScanning
                ? QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.red,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 300,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Tap "Start Scanning" to begin'),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isScanning = !isScanning;
                  });
                },
                child: Text(isScanning ? 'Stop Scanning' : 'Start Scanning'),
              ),
              ElevatedButton(
                onPressed: () {
                  controller?.toggleFlash();
                },
                child: const Text('Toggle Flash'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Instructions:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '1. Start scanning to activate camera\n'
            '2. Point camera at QR code from macOS\n'
            '3. App will automatically detect and show data',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUniversalView() {
    return Expanded(
      child: Column(
        children: [
          const Text(
            'Universal QR Test',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                qrData = 'Test QR Code - ${DateTime.now().millisecondsSinceEpoch}';
              });
            },
            child: const Text('Generate New QR Code'),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        setState(() {
          qrData = scanData.code!;
          isScanning = false;
        });
        
        // Show scanned data
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('QR Code Scanned!'),
            content: Text('Scanned Data: $qrData'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
