import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AttendanceCodeService {
  static const String _baseUrl = 'http://localhost:5000/api';
  final Dio _dio = Dio();

  // Generate a secure 6-digit alphanumeric code
  String generateSecureCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Generate QR code for attendance
  Future<AttendanceCodeResult> generateAttendanceCode({
    required int durationMinutes,
    String? classId,
    String? subject,
  }) async {
    try {
      // Call backend to generate code
      final response = await _dio.post(
        '$_baseUrl/attendance/generate-code/demo',
        data: {
          'duration': durationMinutes,
          'classId': classId ?? 'demo_class',
          'subject': subject ?? 'Demo Class',
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 201) {
        final responseData = response.data['data'];
        final code = responseData['code'];
        final expiresAt = DateTime.parse(responseData['expiresAt']);
        
        // Create QR code data
        final qrData = {
          'code': code,
          'expiresAt': expiresAt.millisecondsSinceEpoch,
          'duration': durationMinutes,
          'classId': classId ?? 'demo_class',
          'subject': subject ?? 'Demo Class',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        // Generate QR code image
        final qrCodeImage = QrImageView(
          data: jsonEncode(qrData),
          version: QrVersions.auto,
          size: 300.0,
          backgroundColor: Colors.white,
        );

        return AttendanceCodeResult(
          success: true,
          code: code,
          qrCodeImage: qrCodeImage,
          expiresAt: expiresAt,
          durationMinutes: durationMinutes,
          sessionId: responseData['_id'] ?? responseData['id'],
        );
      } else {
        String errorMessage = 'Failed to generate attendance code';
        if (response.data != null) {
          if (response.data['message'] != null) {
            errorMessage = response.data['message'];
          }
          if (response.data['errors'] != null && response.data['errors'].isNotEmpty) {
            final errors = response.data['errors'] as List;
            errorMessage = errors.map((e) => e['msg'] ?? e.toString()).join(', ');
          }
        }
        return AttendanceCodeResult(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      print('Error generating attendance code: $e');
      return AttendanceCodeResult(
        success: false,
        error: 'Error generating attendance code: $e',
      );
    }
  }

  // Start countdown for QR code
  Future<AttendanceValidationResult> startCountdown({
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/attendance/start-countdown/demo',
        data: {
          'code': code,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        return AttendanceValidationResult(
          success: true,
          message: response.data['message'] ?? 'Countdown started successfully',
          data: response.data['data'],
        );
      } else {
        return AttendanceValidationResult(
          success: false,
          error: response.data['message'] ?? 'Failed to start countdown',
        );
      }
    } catch (e) {
      print('Error starting countdown: $e');
      return AttendanceValidationResult(
        success: false,
        error: 'Error starting countdown: $e',
      );
    }
  }

  // Validate attendance code
  Future<AttendanceValidationResult> validateAttendanceCode({
    required String code,
    required String studentId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/attendance/validate-code/demo',
        data: {
          'code': code,
          'studentId': studentId,
          'location': (latitude != null && longitude != null)
              ? {
                  'latitude': latitude,
                  'longitude': longitude,
                }
              : null,
          'timestamp': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        return AttendanceValidationResult(
          success: true,
          message: response.data['message'] ?? 'Attendance marked successfully',
          data: response.data['data'],
        );
      } else {
        return AttendanceValidationResult(
          success: false,
          error: response.data['message'] ?? 'Failed to validate attendance code',
        );
      }
    } catch (e) {
      print('Error validating attendance code: $e');
      return AttendanceValidationResult(
        success: false,
        error: 'Error validating attendance code: $e',
      );
    }
  }

  // Get active attendance codes
  Future<List<AttendanceCode>> getActiveCodes() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/attendance/codes/active',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> codesJson = response.data['data'] ?? [];
        return codesJson.map((json) => AttendanceCode.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting active codes: $e');
      return [];
    }
  }
}

class AttendanceCodeResult {
  final bool success;
  final String? code;
  final QrImageView? qrCodeImage;
  final DateTime? expiresAt;
  final int? durationMinutes;
  final String? sessionId;
  final String? error;

  AttendanceCodeResult({
    required this.success,
    this.code,
    this.qrCodeImage,
    this.expiresAt,
    this.durationMinutes,
    this.sessionId,
    this.error,
  });
}

class AttendanceValidationResult {
  final bool success;
  final String? message;
  final String? error;
  final dynamic data;

  AttendanceValidationResult({
    required this.success,
    this.message,
    this.error,
    this.data,
  });
}

class AttendanceCode {
  final String id;
  final String code;
  final DateTime expiresAt;
  final int durationMinutes;
  final String classId;
  final String subject;
  final bool isActive;
  final DateTime createdAt;

  AttendanceCode({
    required this.id,
    required this.code,
    required this.expiresAt,
    required this.durationMinutes,
    required this.classId,
    required this.subject,
    required this.isActive,
    required this.createdAt,
  });

  factory AttendanceCode.fromJson(Map<String, dynamic> json) {
    return AttendanceCode(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      expiresAt: DateTime.parse(json['expiresAt']),
      durationMinutes: json['duration'] ?? 60,
      classId: json['classId']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'expiresAt': expiresAt.toIso8601String(),
      'duration': durationMinutes,
      'classId': classId,
      'subject': subject,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
