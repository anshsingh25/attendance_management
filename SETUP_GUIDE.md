# Attendance Management System - Setup Guide

## 🚀 Quick Start

### 1. Prerequisites
- Flutter SDK 3.9.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode
- Git

### 2. Installation Steps

```bash
# Clone the repository
git clone <repository-url>
cd attendence_app

# Install dependencies
flutter pub get

# Generate JSON serialization files
flutter packages pub run build_runner build

# Run the app
flutter run
```

### 3. Demo Credentials

The app includes demo credentials for testing:

| Role | Email | Password |
|------|-------|----------|
| Student | student@demo.com | password123 |
| Teacher | teacher@demo.com | password123 |
| Admin | admin@demo.com | password123 |

## 🔧 Configuration

### API Configuration

1. **Update API URL** in `lib/main.dart`:
   ```dart
   final dio = Dio(BaseOptions(
     baseUrl: 'https://your-api-url.com/api', // Replace with your API URL
     connectTimeout: const Duration(seconds: 30),
     receiveTimeout: const Duration(seconds: 30),
   ));
   ```

2. **Configure Demo Service** (for testing without backend):
   - The app currently uses `DemoService` for testing
   - Replace with actual API calls in production

### Permissions Setup

#### Android Permissions
The app automatically requests the following permissions:
- Location (for geofencing)
- Camera (for QR scanning)
- WiFi (for network validation)
- Notifications (for push notifications)

#### iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes for attendance</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to validate attendance location</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to validate attendance location</string>
```

## 🏗️ Backend API Requirements

### Authentication Endpoints

#### POST /auth/login
```json
{
  "email": "student@demo.com",
  "password": "password123"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "token": "jwt_token_here",
    "refreshToken": "refresh_token_here",
    "user": {
      "id": "user_id",
      "email": "student@demo.com",
      "name": "John Student",
      "role": "student",
      "studentId": "STU001",
      "department": "Computer Science",
      "course": "B.Tech",
      "semester": "3rd",
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z",
      "isActive": true
    }
  }
}
```

#### POST /auth/logout
Headers: `Authorization: Bearer <token>`

#### POST /auth/refresh
```json
{
  "refreshToken": "refresh_token_here"
}
```

### Attendance Endpoints

#### GET /attendance/sessions/active
Headers: `Authorization: Bearer <token>`
Query: `?studentId=student_id`

Response:
```json
{
  "success": true,
  "data": [
    {
      "id": "session_id",
      "classroomId": "classroom_id",
      "teacherId": "teacher_id",
      "title": "Data Structures Lecture",
      "description": "Introduction to linked lists",
      "startTime": "2024-01-15T10:00:00Z",
      "endTime": "2024-01-15T11:30:00Z",
      "durationMinutes": 90,
      "status": "active",
      "qrCodeData": "session_data",
      "qrCodeGeneratedAt": "2024-01-15T09:45:00Z",
      "createdAt": "2024-01-15T09:30:00Z",
      "updatedAt": "2024-01-15T09:45:00Z",
      "attendedStudentIds": [],
      "attendanceRecords": {}
    }
  ]
}
```

#### GET /attendance/sessions/{id}
Headers: `Authorization: Bearer <token>`

#### POST /attendance/submit
Headers: `Authorization: Bearer <token>`
```json
{
  "sessionId": "session_id",
  "studentId": "student_id",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "wifiSSID": "Classroom_WiFi",
  "qrCodeData": "qr_data",
  "deviceInfo": "device_info"
}
```

## 🧪 Testing Features

### 1. WiFi Validation Testing
- Connect to different WiFi networks
- Test with expected vs unexpected SSIDs
- Verify error messages for wrong networks

### 2. Location Validation Testing
- Test with different GPS coordinates
- Verify geofencing with radius validation
- Test location permission handling

### 3. QR Code Testing
- Generate test QR codes with session data
- Test QR code scanning functionality
- Verify QR code validation and expiration

### 4. Offline Testing
- Disable network connection
- Submit attendance while offline
- Re-enable network and verify sync

### 5. Notification Testing
- Test push notifications
- Verify notification permissions
- Test different notification types

## 🔒 Security Considerations

### 1. JWT Token Security
- Implement proper token expiration
- Use secure token storage
- Implement token refresh mechanism

### 2. Location Data Protection
- Encrypt location data in transit
- Implement proper data retention policies
- Ensure GDPR compliance

### 3. WiFi Security
- Validate WiFi SSID against whitelist
- Implement network security checks
- Prevent SSID spoofing attacks

### 4. QR Code Security
- Implement time-based expiration
- Use nonce for replay attack prevention
- Validate QR code integrity

## 📱 Platform-Specific Setup

### Android Setup

1. **Minimum SDK**: 21 (Android 5.0)
2. **Target SDK**: 34 (Android 14)
3. **Permissions**: Automatically configured in AndroidManifest.xml

### iOS Setup

1. **Minimum iOS**: 11.0
2. **Target iOS**: 17.0
3. **Permissions**: Add to Info.plist as shown above

## 🚀 Deployment

### Android Deployment

1. **Generate Signed APK**:
   ```bash
   flutter build apk --release
   ```

2. **Generate App Bundle**:
   ```bash
   flutter build appbundle --release
   ```

### iOS Deployment

1. **Build for iOS**:
   ```bash
   flutter build ios --release
   ```

2. **Archive in Xcode** for App Store submission

## 🔧 Troubleshooting

### Common Issues

1. **Build Runner Errors**:
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Permission Issues**:
   - Check AndroidManifest.xml for permissions
   - Verify iOS Info.plist configuration
   - Test permission requests on device

3. **Network Issues**:
   - Verify API endpoint configuration
   - Check network connectivity
   - Test with demo service first

4. **Location Issues**:
   - Enable location services on device
   - Grant location permissions
   - Test with mock location if needed

### Debug Mode

Run in debug mode for detailed logs:
```bash
flutter run --debug
```

### Logs

Check Flutter logs for debugging:
```bash
flutter logs
```

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the README.md file
3. Create an issue in the repository
4. Contact the development team

## 🔄 Updates

To update the app:
1. Pull latest changes: `git pull`
2. Update dependencies: `flutter pub get`
3. Regenerate files: `flutter packages pub run build_runner build`
4. Test the app: `flutter run`

---

**Note**: This setup guide covers the basic configuration. For production deployment, ensure proper security measures, backend integration, and thorough testing.
