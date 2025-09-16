import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../models/attendance_session.dart';
import '../utils/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = false;
  String? _lastScannedCode;

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
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Position the QR code within the frame',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Make sure the code is clearly visible',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
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
            child: Column(
              children: [
                // Flashlight Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: _toggleFlashlight,
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Manual Entry Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Enter Code Manually'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Loading Overlay
          if (_isScanning)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
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
    
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      _showErrorDialog('User not found. Please login again.');
      return;
    }

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
      // Validate QR code format
      if (!_isValidQRCode(qrCode)) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Invalid QR code format. Please scan a valid attendance QR code.');
        return;
      }

      // Extract session ID from QR code
      final sessionId = _extractSessionId(qrCode);
      if (sessionId == null || sessionId.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Could not extract session ID from QR code.');
        return;
      }

      // Get session details - we'll create a mock session for now
      final session = AttendanceSession(
        id: sessionId,
        classroomId: 'classroom-123',
        teacherId: 'teacher-123',
        title: 'Test Session',
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        endTime: DateTime.now().add(const Duration(minutes: 20)),
        durationMinutes: 30,
        status: SessionStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Validate QR code
      final qrValidation = attendanceProvider.validateQRCode(qrCode, session);
      if (!qrValidation.isValid) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog(qrValidation.error ?? 'Invalid QR code.');
        return;
      }

      // Submit attendance
      final success = await attendanceProvider.submitAttendance(
        sessionId: sessionId,
        studentId: authProvider.user!.id,
        qrCodeData: qrCode,
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        _showSuccessDialog('Attendance marked successfully!');
      } else {
        _showErrorDialog(attendanceProvider.submissionError ?? 'Failed to mark attendance.');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('An error occurred: $e');
    }
  }

  bool _isValidQRCode(String qrCode) {
    try {
      // Basic validation - check if it's JSON and contains required fields
      final data = qrCode.split(',');
      return data.length >= 3; // At least sessionId, classroomId, teacherId
    } catch (e) {
      return false;
    }
  }

  String? _extractSessionId(String qrCode) {
    try {
      // Simple extraction - in a real app, you'd parse JSON
      final parts = qrCode.split(',');
      if (parts.isNotEmpty) {
        return parts[0].trim();
      }
    } catch (e) {
      print('Error extracting session ID: $e');
    }
    return null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isScanning = true;
                _lastScannedCode = null;
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
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
