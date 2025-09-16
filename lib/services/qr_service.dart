import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_session.dart';

class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final _uuid = const Uuid();

  // Generate QR code data for attendance session
  String generateQRCodeData(AttendanceSession session) {
    final qrData = {
      'sessionId': session.id,
      'classroomId': session.classroomId,
      'teacherId': session.teacherId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiresAt': session.endTime.millisecondsSinceEpoch,
      'nonce': _uuid.v4(), // Add randomness to prevent replay attacks
    };

    return jsonEncode(qrData);
  }

  // Validate QR code data
  QRValidationResult validateQRCode(String qrCodeData, AttendanceSession session) {
    try {
      final data = jsonDecode(qrCodeData) as Map<String, dynamic>;
      
      // Check if session ID matches
      if (data['sessionId'] != session.id) {
        return QRValidationResult(
          isValid: false,
          error: 'Invalid session ID',
        );
      }

      // Check if classroom ID matches
      if (data['classroomId'] != session.classroomId) {
        return QRValidationResult(
          isValid: false,
          error: 'Invalid classroom ID',
        );
      }

      // Check if teacher ID matches
      if (data['teacherId'] != session.teacherId) {
        return QRValidationResult(
          isValid: false,
          error: 'Invalid teacher ID',
        );
      }

      // Check if QR code has expired
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(data['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        return QRValidationResult(
          isValid: false,
          error: 'QR code has expired',
        );
      }

      // Check if QR code is too old (prevent replay attacks)
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
      final age = DateTime.now().difference(timestamp);
      if (age.inMinutes > 5) { // QR code valid for 5 minutes
        return QRValidationResult(
          isValid: false,
          error: 'QR code is too old',
        );
      }

      return QRValidationResult(
        isValid: true,
        sessionId: data['sessionId'],
        classroomId: data['classroomId'],
        teacherId: data['teacherId'],
        timestamp: timestamp,
        expiresAt: expiresAt,
        nonce: data['nonce'],
      );
    } catch (e) {
      return QRValidationResult(
        isValid: false,
        error: 'Invalid QR code format: $e',
      );
    }
  }

  // Generate QR code widget
  QrImageView generateQRCodeWidget(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  // Create QR code scanner controller
  QRViewController createScannerController() {
    // This would typically be created in the widget
    // Return a placeholder for now
    throw UnimplementedError('QRViewController should be created in the widget');
  }

  // Validate QR code from scanner
  QRValidationResult validateScannedQRCode(
    String scannedData,
    AttendanceSession session,
  ) {
    return validateQRCode(scannedData, session);
  }

  // Generate QR code for testing
  String generateTestQRCode() {
    final testData = {
      'sessionId': 'test-session-123',
      'classroomId': 'test-classroom-456',
      'teacherId': 'test-teacher-789',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiresAt': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
      'nonce': _uuid.v4(),
    };

    return jsonEncode(testData);
  }

  // Check if QR code is for attendance
  bool isAttendanceQRCode(String qrCodeData) {
    try {
      final data = jsonDecode(qrCodeData) as Map<String, dynamic>;
      return data.containsKey('sessionId') && 
             data.containsKey('classroomId') && 
             data.containsKey('teacherId');
    } catch (e) {
      return false;
    }
  }

  // Extract session ID from QR code
  String? extractSessionId(String qrCodeData) {
    try {
      final data = jsonDecode(qrCodeData) as Map<String, dynamic>;
      return data['sessionId'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Extract classroom ID from QR code
  String? extractClassroomId(String qrCodeData) {
    try {
      final data = jsonDecode(qrCodeData) as Map<String, dynamic>;
      return data['classroomId'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Extract teacher ID from QR code
  String? extractTeacherId(String qrCodeData) {
    try {
      final data = jsonDecode(qrCodeData) as Map<String, dynamic>;
      return data['teacherId'] as String?;
    } catch (e) {
      return null;
    }
  }
}

class QRValidationResult {
  final bool isValid;
  final String? error;
  final String? sessionId;
  final String? classroomId;
  final String? teacherId;
  final DateTime? timestamp;
  final DateTime? expiresAt;
  final String? nonce;

  const QRValidationResult({
    required this.isValid,
    this.error,
    this.sessionId,
    this.classroomId,
    this.teacherId,
    this.timestamp,
    this.expiresAt,
    this.nonce,
  });
}
