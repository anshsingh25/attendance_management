class ApiConfig {
  // Update this URL to point to your backend API
  static const String baseUrl = 'http://localhost:5000/api';
  
  // Demo endpoints for testing (replace with actual backend)
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshEndpoint = '/auth/refresh';
  static const String activeSessionsEndpoint = '/qr/active-sessions';
  static const String submitAttendanceEndpoint = '/qr/validate';
  
  // Demo credentials for testing
  static const Map<String, String> demoCredentials = {
    'student@demo.com': 'password123',
    'teacher@demo.com': 'password123',
    'admin@demo.com': 'password123',
  };
  
  // Demo user data
  static const Map<String, Map<String, dynamic>> demoUsers = {
    'student@demo.com': {
      'id': 'student-123',
      'email': 'student@demo.com',
      'name': 'John Student',
      'role': 'student',
      'studentId': 'STU001',
      'department': 'Computer Science',
      'course': 'B.Tech',
      'semester': '3rd',
      'createdAt': '2024-01-01T00:00:00Z',
      'updatedAt': '2024-01-01T00:00:00Z',
      'isActive': true,
    },
    'teacher@demo.com': {
      'id': 'teacher-123',
      'email': 'teacher@demo.com',
      'name': 'Dr. Jane Teacher',
      'role': 'teacher',
      'department': 'Computer Science',
      'createdAt': '2024-01-01T00:00:00Z',
      'updatedAt': '2024-01-01T00:00:00Z',
      'isActive': true,
    },
    'admin@demo.com': {
      'id': 'admin-123',
      'email': 'admin@demo.com',
      'name': 'Admin User',
      'role': 'admin',
      'createdAt': '2024-01-01T00:00:00Z',
      'updatedAt': '2024-01-01T00:00:00Z',
      'isActive': true,
    },
  };
  
  // Demo active sessions
  static const List<Map<String, dynamic>> demoActiveSessions = [
    {
      'id': 'session-123',
      'classroomId': 'classroom-456',
      'teacherId': 'teacher-123',
      'title': 'Data Structures Lecture',
      'description': 'Introduction to linked lists and trees',
      'startTime': '2024-01-15T10:00:00Z',
      'endTime': '2024-01-15T11:30:00Z',
      'durationMinutes': 90,
      'status': 'active',
      'qrCodeData': 'session-123,classroom-456,teacher-123,1705312800000,1705316400000,nonce-123',
      'qrCodeGeneratedAt': '2024-01-15T09:45:00Z',
      'createdAt': '2024-01-15T09:30:00Z',
      'updatedAt': '2024-01-15T09:45:00Z',
      'attendedStudentIds': [],
      'attendanceRecords': {},
    },
    {
      'id': 'session-124',
      'classroomId': 'classroom-457',
      'teacherId': 'teacher-123',
      'title': 'Algorithms Lab',
      'description': 'Sorting algorithms implementation',
      'startTime': '2024-01-15T14:00:00Z',
      'endTime': '2024-01-15T16:00:00Z',
      'durationMinutes': 120,
      'status': 'active',
      'qrCodeData': 'session-124,classroom-457,teacher-123,1705327200000,1705334400000,nonce-124',
      'qrCodeGeneratedAt': '2024-01-15T13:45:00Z',
      'createdAt': '2024-01-15T13:30:00Z',
      'updatedAt': '2024-01-15T13:45:00Z',
      'attendedStudentIds': [],
      'attendanceRecords': {},
    },
  ];
}
