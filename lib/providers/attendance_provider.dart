import 'package:flutter/foundation.dart';
import '../models/attendance_session.dart';
import '../services/attendance_service.dart';
import '../services/wifi_service.dart';
import '../services/location_service.dart';
import '../services/qr_service.dart';
import '../services/notification_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService;
  final WifiService _wifiService;
  final LocationService _locationService;
  final QRService _qrService;
  final NotificationService _notificationService;

  List<AttendanceSession> _activeSessions = [];
  AttendanceSession? _currentSession;
  bool _isLoading = false;
  String? _error;
  bool _isSubmitting = false;
  String? _submissionError;
  String? _submissionSuccess;

  AttendanceProvider(
    this._attendanceService,
    this._wifiService,
    this._locationService,
    this._qrService,
    this._notificationService,
  );

  // Getters
  List<AttendanceSession> get activeSessions => _activeSessions;
  AttendanceSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSubmitting => _isSubmitting;
  String? get submissionError => _submissionError;
  String? get submissionSuccess => _submissionSuccess;

  // Load active sessions for student
  Future<void> loadActiveSessions(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeSessions = await _attendanceService.getActiveSessions(studentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set current session
  void setCurrentSession(AttendanceSession session) {
    _currentSession = session;
    notifyListeners();
  }

  // Submit attendance
  Future<bool> submitAttendance({
    required String sessionId,
    required String studentId,
    String? qrCodeData,
    bool validateLocation = true,
    bool validateWifi = true,
  }) async {
    _isSubmitting = true;
    _submissionError = null;
    _submissionSuccess = null;
    notifyListeners();

    try {
      final result = await _attendanceService.submitAttendance(
        sessionId: sessionId,
        studentId: studentId,
        qrCodeData: qrCodeData,
        validateLocation: validateLocation,
        validateWifi: validateWifi,
      );

      if (result.success) {
        _submissionSuccess = result.message ?? 'Attendance submitted successfully';
        
        // Show success notification
        await _notificationService.showAttendanceSuccess(
          title: 'Attendance Submitted',
          body: _submissionSuccess!,
        );

        // Remove session from active sessions if it's completed
        if (result.data != null) {
          _activeSessions.removeWhere((session) => session.id == sessionId);
        }

        return true;
      } else {
        _submissionError = result.error ?? 'Failed to submit attendance';
        
        // Show error notification
        await _notificationService.showAttendanceError(
          title: 'Attendance Failed',
          body: _submissionError!,
        );

        return false;
      }
    } catch (e) {
      _submissionError = e.toString();
      
      // Show error notification
      await _notificationService.showAttendanceError(
        title: 'Attendance Error',
        body: _submissionError!,
      );

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
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
    try {
      return await _attendanceService.validateAttendanceRequirements(
        sessionId: sessionId,
        classroomId: classroomId,
        expectedWifiSSID: expectedWifiSSID,
        classroomLatitude: classroomLatitude,
        classroomLongitude: classroomLongitude,
        allowedRadius: allowedRadius,
      );
    } catch (e) {
      return AttendanceValidationResult(
        isValid: false,
        validationResults: {},
        errors: [e.toString()],
      );
    }
  }

  // Get current WiFi SSID
  Future<String?> getCurrentWifiSSID() async {
    return await _wifiService.getCurrentWifiSSID();
  }

  // Validate WiFi SSID
  Future<bool> validateWifiSSID(String expectedSSID) async {
    return await _wifiService.validateWifiSSID(expectedSSID);
  }

  // Get current location
  Future<LocationValidationResult> getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        return LocationValidationResult(
          isValid: true,
          currentLatitude: position.latitude,
          currentLongitude: position.longitude,
        );
      } else {
        return LocationValidationResult(
          isValid: false,
          error: 'Unable to get current location',
        );
      }
    } catch (e) {
      return LocationValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }

  // Validate QR code
  QRValidationResult validateQRCode(String qrCodeData, AttendanceSession session) {
    return _qrService.validateQRCode(qrCodeData, session);
  }

  // Clear submission messages
  void clearSubmissionMessages() {
    _submissionError = null;
    _submissionSuccess = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh sessions
  Future<void> refreshSessions(String studentId) async {
    await loadActiveSessions(studentId);
  }

  // Start watching WiFi SSID to auto-mark for active sessions
  Stream<String?>? _ssidStream;
  void startWifiAutoMarking({required String classId, required String expectedSsid}) {
    _ssidStream ??= _wifiService.watchSsid();
    _ssidStream!.listen((ssid) async {
      if (ssid == null) return;
      try {
        if (ssid.toLowerCase() == expectedSsid.toLowerCase()) {
          final location = await _locationService.getCurrentPosition();
          final result = await _attendanceService.autoMarkViaWifi(
            classId: classId,
            wifiSSID: ssid,
            latitude: location?.latitude,
            longitude: location?.longitude,
          );

          if (result.success) {
            await _notificationService.showAttendanceSuccess(
              title: 'Attendance Auto-Marked',
              body: 'You are connected to classroom WiFi. Attendance marked.',
            );
          }
        }
      } catch (_) {}
    });
  }

  // Convenience: fetch class SSID and start auto-marking
  Future<void> enableWifiAutoMarkingForClass(String classId) async {
    try {
      final ssid = await _attendanceService.getClassWifiSsid(classId);
      if (ssid != null && ssid.isNotEmpty) {
        startWifiAutoMarking(classId: classId, expectedSsid: ssid);
      }
    } catch (_) {}
  }

  // Check if session is active
  bool isSessionActive(AttendanceSession session) {
    final now = DateTime.now();
    return session.isActive && 
           now.isAfter(session.startTime) && 
           now.isBefore(session.endTime);
  }

  // Get remaining time for session
  Duration getRemainingTime(AttendanceSession session) {
    if (!isSessionActive(session)) {
      return Duration.zero;
    }
    return session.endTime.difference(DateTime.now());
  }

  // Format remaining time
  String formatRemainingTime(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
