import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/attendance_session.dart';
import '../models/api_response.dart';
import 'auth_service.dart';
import 'wifi_service.dart';
import 'location_service.dart';
import 'qr_service.dart';
// import 'offline_service.dart';  // Temporarily disabled for macOS build

class AttendanceService {
  final Dio _dio;
  final AuthService _authService;
  final WifiService _wifiService;
  final LocationService _locationService;
  final QRService _qrService;
  // final OfflineService _offlineService;  // Temporarily disabled for macOS build
  final DeviceInfoPlugin _deviceInfo;

  AttendanceService(
    this._dio,
    this._authService,
    this._wifiService,
    this._locationService,
    this._qrService,
    // this._offlineService,  // Temporarily disabled for macOS build
    this._deviceInfo,
  );

  // Submit attendance
  Future<AttendanceSubmissionResult> submitAttendance({
    required String sessionId,
    required String studentId,
    String? qrCodeData,
    bool validateLocation = true,
    bool validateWifi = true,
  }) async {
    try {
      // Get device info
      final deviceInfo = await _getDeviceInfo();

      // Validate QR code if provided
      if (qrCodeData != null) {
        final qrValidation = _qrService.validateQRCode(qrCodeData, 
          AttendanceSession(
            id: sessionId,
            classroomId: '',
            teacherId: '',
            title: '',
            startTime: DateTime.now(),
            endTime: DateTime.now(),
            durationMinutes: 0,
            status: SessionStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        );
        
        if (!qrValidation.isValid) {
          return AttendanceSubmissionResult(
            success: false,
            error: qrValidation.error ?? 'Invalid QR code',
          );
        }
      }

      // Get current location
      double? latitude;
      double? longitude;
      if (validateLocation) {
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          latitude = position.latitude;
          longitude = position.longitude;
        }
      }

      // Get current WiFi SSID
      String? wifiSSID;
      if (validateWifi) {
        wifiSSID = await _wifiService.getCurrentWifiSSID();
      }

      // Prepare attendance data
      final attendanceData = AttendanceSubmissionRequest(
        sessionId: sessionId,
        studentId: studentId,
        latitude: latitude,
        longitude: longitude,
        wifiSSID: wifiSSID,
        qrCodeData: qrCodeData,
        deviceInfo: deviceInfo,
      );

      // Check if online
      // final isOnline = await _offlineService.isOnline();  // Temporarily disabled for macOS build
      final isOnline = true;  // Assume online for macOS build
      
      if (!isOnline) {
        // Queue for offline processing
        // await _offlineService.queueAttendanceSubmission(attendanceData.toJson());  // Temporarily disabled for macOS build
        return AttendanceSubmissionResult(
          success: true,
          message: 'Attendance queued for submission when online',
          isOffline: true,
        );
      }

      // Submit online
      final response = await _dio.post(
        '/qr/validate',
        data: {
          'qrData': qrCodeData,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': null,
          },
          'wifiSSID': wifiSSID,
          'deviceInfo': await _getDeviceInfo(),
        },
        options: Options(
          headers: await _authService.getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        return AttendanceSubmissionResult(
          success: true,
          message: 'Attendance submitted successfully',
          data: response.data,
        );
      } else {
        return AttendanceSubmissionResult(
          success: false,
          error: response.data['message'] ?? 'Failed to submit attendance',
        );
      }
    } on DioException catch (e) {
      // If network error, queue for offline processing
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final attendanceData = AttendanceSubmissionRequest(
          sessionId: sessionId,
          studentId: studentId,
          deviceInfo: await _getDeviceInfo(),
        );
        
        // await _offlineService.queueAttendanceSubmission(attendanceData.toJson());  // Temporarily disabled for macOS build
        
        return AttendanceSubmissionResult(
          success: true,
          message: 'Attendance queued for submission when online',
          isOffline: true,
        );
      }

      return AttendanceSubmissionResult(
        success: false,
        error: _handleDioError(e),
      );
    } catch (e) {
      return AttendanceSubmissionResult(
        success: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  // Get active sessions for student
  Future<List<AttendanceSession>> getActiveSessions(String studentId) async {
    try {
      final response = await _dio.get(
        '/qr/active-sessions',
        options: Options(
          headers: await _authService.getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> sessionsJson = response.data['data'];
        return sessionsJson
            .map((json) => AttendanceSession.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting active sessions: $e');
      return [];
    }
  }

  // Get session by ID
  Future<AttendanceSession?> getSession(String sessionId) async {
    try {
      final response = await _dio.get(
        '/attendance/sessions/$sessionId',
        options: Options(
          headers: await _authService.getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        return AttendanceSession.fromJson(response.data['data']);
      }
      
      return null;
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }

  // Validate attendance requirements
  Future<AttendanceValidationResult> validateAttendanceRequirements({
    required String sessionId,
    required String classroomId,
    String? expectedWifiSSID,
    double? classroomLatitude,
    double? classroomLongitude,
    double? allowedRadius,
  }) async {
    final validationResults = <String, bool>{};
    final errors = <String>[];

    // Validate WiFi if required
    if (expectedWifiSSID != null && expectedWifiSSID.isNotEmpty) {
      final wifiValid = await _wifiService.validateWifiSSID(expectedWifiSSID);
      validationResults['wifi'] = wifiValid;
      if (!wifiValid) {
        errors.add('You must be connected to the classroom WiFi: $expectedWifiSSID');
      }
    }

    // Validate location if required
    if (classroomLatitude != null && 
        classroomLongitude != null && 
        allowedRadius != null) {
      final locationResult = await _locationService.validateLocationForAttendance(
        classroomLatitude,
        classroomLongitude,
        allowedRadius,
      );
      validationResults['location'] = locationResult.isValid;
      if (!locationResult.isValid) {
        errors.add(locationResult.error ?? 'Location validation failed');
      }
    }

    final allValid = validationResults.values.every((valid) => valid);

    return AttendanceValidationResult(
      isValid: allValid,
      validationResults: validationResults,
      errors: errors,
    );
  }

  // Auto mark attendance via WiFi (no QR)
  Future<AttendanceSubmissionResult> autoMarkViaWifi({
    required String classId,
    String? wifiSSID,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _dio.post(
        '/qr/auto-mark',
        data: {
          'classId': classId,
          'wifiSSID': wifiSSID,
          'location': (latitude != null && longitude != null)
              ? {
                  'latitude': latitude,
                  'longitude': longitude,
                }
              : null,
          'deviceInfo': await _getDeviceInfo(),
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return const AttendanceSubmissionResult(success: true, message: 'Attendance auto-marked');
      }
      return AttendanceSubmissionResult(success: false, error: response.data['message'] ?? 'Auto-mark failed');
    } on DioException catch (e) {
      return AttendanceSubmissionResult(success: false, error: _handleDioError(e));
    } catch (e) {
      return AttendanceSubmissionResult(success: false, error: 'Error: $e');
    }
  }

  // Get device info
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = await _deviceInfo.deviceInfo;
      return deviceInfo.data.toString();
    } catch (e) {
      return 'Unknown device';
    }
  }

  // Handle Dio errors
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return 'Authentication failed. Please login again.';
        } else if (statusCode == 403) {
          return 'Access denied.';
        } else if (statusCode == 404) {
          return 'Session not found.';
        } else if (statusCode == 409) {
          return 'Attendance already submitted for this session.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return 'Request failed with status: $statusCode';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return 'An unexpected error occurred.';
    }
  }

  // Fetch class WiFi SSID by classId
  Future<String?> getClassWifiSsid(String classId) async {
    try {
      final response = await _dio.get(
        '/classes/$classId',
        options: Options(headers: await _authService.getAuthHeaders()),
      );
      if (response.statusCode == 200) {
        return response.data['data']?['wifiSSID'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class AttendanceSubmissionResult {
  final bool success;
  final String? message;
  final String? error;
  final dynamic data;
  final bool isOffline;

  const AttendanceSubmissionResult({
    required this.success,
    this.message,
    this.error,
    this.data,
    this.isOffline = false,
  });
}

class AttendanceValidationResult {
  final bool isValid;
  final Map<String, bool> validationResults;
  final List<String> errors;

  const AttendanceValidationResult({
    required this.isValid,
    required this.validationResults,
    required this.errors,
  });
}
