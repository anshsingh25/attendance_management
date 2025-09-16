# Attendance Management System

A comprehensive Flutter-based attendance management system with WiFi validation, geolocation services, QR code scanning, and offline support.

## 🚀 Features

### Core Features
- **WiFi-Based Validation**: Students must be connected to the classroom WiFi to mark attendance
- **Location-Based Geofencing**: GPS validation ensures students are within classroom boundaries
- **QR Code Scanning**: Secure QR code generation and scanning for attendance sessions
- **Offline Support**: Queue attendance submissions when offline, sync when online
- **Real-time Notifications**: Push notifications for session reminders and status updates

### User Roles
- **Students**: Mark attendance, view session history, scan QR codes
- **Teachers**: Create sessions, manage classrooms, view attendance reports
- **Admins**: System administration, user management, analytics

### Security Features
- **JWT Authentication**: Secure token-based authentication
- **Input Validation**: Comprehensive validation for all user inputs
- **Device Information**: Track device details for audit purposes
- **Session Timeouts**: Automatic session expiration for security

### UI/UX Features
- **Material 3 Design**: Modern, beautiful interface
- **Dark Mode Support**: Automatic theme switching
- **Loading Animations**: Smooth user experience
- **Error Handling**: Comprehensive error messages and recovery

## 📱 Screenshots

*Screenshots will be added after testing*

## 🛠️ Technical Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Provider**: State management
- **Material 3**: UI design system

### Backend Integration
- **Dio**: HTTP client for API calls
- **JWT**: Authentication tokens
- **RESTful API**: Backend communication

### Local Storage
- **SQLite**: Offline data storage
- **SharedPreferences**: User preferences and settings

### Device Features
- **WiFi Info**: Network validation
- **Geolocator**: Location services
- **QR Code Scanner**: Camera-based scanning
- **Local Notifications**: Push notifications
- **Permission Handler**: Runtime permissions

## 📋 Prerequisites

- Flutter SDK (3.9.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode for mobile development
- Backend API server (Node.js, Python, etc.)

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd attendence_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate JSON serialization files**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure API endpoint**
   - Update the base URL in `lib/main.dart`
   - Replace `https://your-api-url.com/api` with your actual API endpoint

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### API Configuration
Update the API base URL in `lib/main.dart`:
```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://your-api-url.com/api', // Replace with your API URL
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
));
```

### Permissions
The app requires the following permissions:
- **Location**: For geofencing validation
- **Camera**: For QR code scanning
- **WiFi**: For network validation
- **Notifications**: For push notifications

### Backend API Endpoints
The app expects the following API endpoints:

#### Authentication
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout
- `POST /auth/refresh` - Token refresh

#### Attendance
- `GET /attendance/sessions/active` - Get active sessions
- `GET /attendance/sessions/{id}` - Get session details
- `POST /attendance/submit` - Submit attendance

## 🏗️ Project Structure

```
lib/
├── models/           # Data models
│   ├── user.dart
│   ├── classroom.dart
│   ├── attendance_session.dart
│   ├── offline_queue.dart
│   └── api_response.dart
├── services/         # Business logic services
│   ├── auth_service.dart
│   ├── wifi_service.dart
│   ├── location_service.dart
│   ├── qr_service.dart
│   ├── offline_service.dart
│   ├── attendance_service.dart
│   └── notification_service.dart
├── providers/        # State management
│   ├── auth_provider.dart
│   └── attendance_provider.dart
├── screens/          # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── attendance_screen.dart
│   ├── qr_scanner_screen.dart
│   └── profile_screen.dart
├── widgets/          # Reusable UI components
├── utils/            # Utility functions
│   └── app_theme.dart
└── main.dart         # App entry point
```

## 🔐 Security Considerations

### WiFi Validation
- Validates SSID to ensure students are in the correct classroom
- Prevents attendance marking from outside the classroom network

### Location Validation
- Uses GPS coordinates with configurable radius
- Prevents attendance marking from outside classroom boundaries
- Handles location permission gracefully

### QR Code Security
- Time-based expiration for QR codes
- Nonce-based replay attack prevention
- Session-specific validation

### Data Protection
- JWT tokens for secure authentication
- Local data encryption for sensitive information
- Secure API communication with HTTPS

## 📊 Offline Support

The app includes comprehensive offline support:

1. **Offline Queue**: Stores attendance submissions locally when offline
2. **Automatic Sync**: Syncs queued submissions when connection is restored
3. **Retry Logic**: Automatic retry with exponential backoff
4. **Data Persistence**: SQLite database for reliable local storage

## 🔔 Notifications

### Types of Notifications
- **Session Reminders**: Notify students about upcoming sessions
- **Attendance Success**: Confirm successful attendance submission
- **Attendance Errors**: Alert about validation failures
- **Offline Queue**: Notify about pending offline submissions

### Notification Channels
- **Attendance Reminders**: High priority for session notifications
- **Attendance Success**: Medium priority for confirmations
- **Attendance Errors**: High priority for error alerts
- **Offline Queue**: Medium priority for sync notifications

## 🧪 Testing

### Demo Credentials
The app includes demo credentials for testing:

- **Student**: `student@demo.com` / `password123`
- **Teacher**: `teacher@demo.com` / `password123`
- **Admin**: `admin@demo.com` / `password123`

### Testing Features
1. **WiFi Validation**: Connect to different WiFi networks to test validation
2. **Location Services**: Test geofencing with different GPS coordinates
3. **QR Code Scanning**: Generate and scan test QR codes
4. **Offline Mode**: Test offline functionality by disabling network

## 🚀 Deployment

### Android
1. Generate signed APK:
   ```bash
   flutter build apk --release
   ```

2. Generate App Bundle:
   ```bash
   flutter build appbundle --release
   ```

### iOS
1. Build for iOS:
   ```bash
   flutter build ios --release
   ```

2. Archive in Xcode for App Store submission

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔄 Version History

### v1.0.0
- Initial release
- WiFi and location validation
- QR code scanning
- Offline support
- Material 3 UI
- JWT authentication

## 🎯 Future Enhancements

- [ ] Biometric authentication
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Voice commands
- [ ] Integration with learning management systems
- [ ] Advanced reporting features
- [ ] Parent/guardian notifications
- [ ] Integration with school information systems

---

**Note**: This is a comprehensive attendance management system designed for educational institutions. Ensure proper testing and security review before production deployment.