import '../config/api_config.dart';
import '../models/user.dart';
import '../models/attendance_session.dart';
import '../models/api_response.dart';

class DemoService {
  static final DemoService _instance = DemoService._internal();
  factory DemoService() => _instance;
  DemoService._internal();

  // Simulate login
  Future<ApiResponse<LoginResponse>> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check demo credentials
    if (ApiConfig.demoCredentials.containsKey(email) && 
        ApiConfig.demoCredentials[email] == password) {
      
      final userData = ApiConfig.demoUsers[email]!;
      final user = User.fromJson(userData);
      
      // Generate mock tokens
      final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      final refreshToken = 'demo_refresh_token_${DateTime.now().millisecondsSinceEpoch}';
      
      final loginResponse = LoginResponse(
        token: token,
        refreshToken: refreshToken,
        user: user,
      );

      return ApiResponse.success(
        message: 'Login successful',
        data: loginResponse,
      );
    } else {
      return ApiResponse.error(
        message: 'Invalid email or password',
        statusCode: 401,
      );
    }
  }

  // Simulate getting active sessions
  Future<List<AttendanceSession>> getActiveSessions(String studentId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return demo active sessions
    return ApiConfig.demoActiveSessions
        .map((sessionData) => AttendanceSession.fromJson(sessionData))
        .toList();
  }

  // Simulate getting session by ID
  Future<AttendanceSession?> getSession(String sessionId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Find session in demo data
    for (final sessionData in ApiConfig.demoActiveSessions) {
      if (sessionData['id'] == sessionId) {
        return AttendanceSession.fromJson(sessionData);
      }
    }
    return null;
  }

  // Simulate submitting attendance
  Future<Map<String, dynamic>> submitAttendance(Map<String, dynamic> data) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate successful submission
    return {
      'success': true,
      'message': 'Attendance submitted successfully',
      'data': {
        'attendanceId': 'attendance_${DateTime.now().millisecondsSinceEpoch}',
        'sessionId': data['sessionId'],
        'studentId': data['studentId'],
        'timestamp': DateTime.now().toIso8601String(),
        'validated': true,
      },
    };
  }

  // Simulate logout
  Future<void> logout() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // No actual logout needed for demo
  }

  // Simulate token refresh
  Future<bool> refreshToken(String refreshToken) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Always return true for demo
    return true;
  }
}
