import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../services/attendance_code_service.dart';

class StudentQRScannerScreen extends StatefulWidget {
  const StudentQRScannerScreen({super.key});

  @override
  State<StudentQRScannerScreen> createState() => _StudentQRScannerScreenState();
}

class _StudentQRScannerScreenState extends State<StudentQRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = false;
  String? _lastScannedCode;
  final AttendanceCodeService _attendanceCodeService = AttendanceCodeService();

  @override
  void initState() {
    super.initState();
    _isScanning = true;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // QR Scanner View
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Theme.of(context).colorScheme.primary,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 250,
            ),
          ),
          
          // Instructions
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Make sure the code is clearly visible',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Flashlight Toggle
                FloatingActionButton(
                  onPressed: _toggleFlashlight,
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                ),
                
                // Manual Entry
                FloatingActionButton(
                  onPressed: _showManualEntryDialog,
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  child: const Icon(
                    Icons.keyboard,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isScanning) return;
      
      setState(() {
        _isScanning = false;
      });
      
      if (scanData.code != null) {
        _handleQRCode(scanData.code!);
      }
    });
  }

  bool _isFlashOn = false;

  void _toggleFlashlight() async {
    if (controller != null) {
      await controller!.toggleFlash();
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    }
  }

  void _showManualEntryDialog() {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter QR Code Manually'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'QR Code Data',
            hintText: 'Paste or type the QR code data here',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (textController.text.isNotEmpty) {
                _handleQRCode(textController.text);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQRCode(String qrCode) async {
    if (qrCode == _lastScannedCode) return;
    
    _lastScannedCode = qrCode;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing QR code...'),
          ],
        ),
      ),
    );

    try {
      // Try to parse QR code data
      Map<String, dynamic>? qrData;
      try {
        qrData = jsonDecode(qrCode);
      } catch (e) {
        // If not JSON, treat as plain code
        qrData = {'code': qrCode};
      }

      String? code;
      if (qrData != null && qrData.containsKey('code')) {
        code = qrData['code'].toString();
      } else {
        // If no code field, use the entire string
        code = qrCode;
      }

      if (code == null || code.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Invalid QR code format. Please scan a valid attendance QR code.');
        return;
      }

      // Validate attendance code with backend
      final result = await _attendanceCodeService.validateAttendanceCode(
        code: code,
        studentId: 'demo_student_123', // Demo student ID
      );

      Navigator.pop(context); // Close loading dialog

      if (result.success) {
        _showSuccessDialog('Attendance marked successfully!');
      } else {
        _showErrorDialog(result.error ?? 'Failed to mark attendance.');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isScanning = true;
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isScanning = true;
              });
            },
            child: const Text('Scan Another'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
