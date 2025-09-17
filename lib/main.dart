import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'screens/enhanced_attendance_screen.dart';
import 'screens/demo_campus_setup_screen.dart';
import 'screens/student_qr_scanner_screen.dart';
import 'services/mongodb_campus_service.dart';
import 'services/attendance_code_service.dart';
import 'utils/student_location_validator.dart';

// Simple providers for demo
class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userRole;

  bool get isLoggedIn => _isLoggedIn;
  String? get userRole => _userRole;

  Future<bool> login(String email, String password) async {
    // Simulate login delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Demo credentials
    if ((email == 'student@demo.com' && password == 'password123') ||
        (email == 'teacher@demo.com' && password == 'password123') ||
        (email == 'admin@demo.com' && password == 'password123')) {
      _isLoggedIn = true;
      _userRole = email.split('@')[0];
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _userRole = null;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  await SharedPreferences.getInstance();
  
  // Initialize MongoDB campus sync
  try {
    await MongoDBCampusService.startMongoDBSync();
    print('MongoDB campus sync initialized successfully');
  } catch (e) {
    print('MongoDB campus sync initialization failed: $e');
    print('Please ensure backend server is running on port 5000');
  }
  
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'Attendance Manager',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              
              // App Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.school,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Attendance Manager',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart WiFi & Location Based Attendance',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 24),
              
              // Demo Credentials
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Credentials:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Student: student@demo.com / password123'),
                    const Text('Teacher: teacher@demo.com / password123'),
                    const Text('Admin: admin@demo.com / password123'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _errorMessage = null;
    });

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!success) {
      setState(() {
        _errorMessage = 'Invalid email or password. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Role-based navigation
        if (authProvider.userRole == 'teacher') {
          return _buildTeacherInterface();
        } else if (authProvider.userRole == 'admin') {
          return _buildAdminInterface();
        } else {
          return _buildStudentInterface();
        }
      },
    );
  }

  Widget _buildStudentInterface() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          StudentDashboardScreen(),
          StudentAttendanceScreen(),
          StudentQRScannerScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'My Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Mark Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherInterface() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TeacherDashboardScreen(),
          TeacherAttendanceScreen(),
          QRGeneratorScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Classes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'Generate QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminInterface() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AdminDashboardScreen(),
          AdminReportsScreen(),
          AdminSettingsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin Panel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Student Dashboard
class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
        child: Column(
              children: [
                // Welcome Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.school,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome Student!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mark your attendance easily',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Today's Classes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Classes",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildClassItem(context, 'Mathematics', 'Dr. Smith', '9:00 AM', 'Room 101', true),
                        _buildClassItem(context, 'Physics', 'Prof. Johnson', '10:30 AM', 'Room 102', false),
                        _buildClassItem(context, 'Chemistry', 'Dr. Brown', '2:00 PM', 'Room 103', false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Quick Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _navigateToQRScanner(context),
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Mark Attendance'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _navigateToAttendance(context),
                                icon: const Icon(Icons.assignment),
                                label: const Text('My Records'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _checkWiFiConnection(context),
                                icon: const Icon(Icons.wifi),
                                label: const Text('WiFi Status'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => StudentLocationValidator.showLocationValidationDialog(context),
                                icon: const Icon(Icons.location_on),
                                label: const Text('Location'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToEnhancedAttendance(context),
                            icon: const Icon(Icons.location_searching),
                            label: const Text('Enhanced Attendance (Continuous Monitoring)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Attendance Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Week Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryItem('Present', '4', Colors.green),
                            ),
                            Expanded(
                              child: _buildSummaryItem('Late', '1', Colors.orange),
                            ),
                            Expanded(
                              child: _buildSummaryItem('Absent', '0', Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassItem(BuildContext context, String subject, String teacher, String time, String room, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$teacher • $time',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  room,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _navigateToQRScanner(BuildContext context) {
    // Navigate to QR Scanner tab
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeState != null) {
      homeState._currentIndex = 2; // QR Scanner tab index
    }
  }

  void _navigateToAttendance(BuildContext context) {
    // Navigate to Attendance tab
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeState != null) {
      homeState._currentIndex = 1; // Attendance tab index
    }
  }

  void _navigateToEnhancedAttendance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedAttendanceScreen(
          subject: 'Demo Subject',
          room: 'Room 101',
          sessionId: 'DEMO_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }

  Future<void> _checkWiFiConnection(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Checking WiFi connection...'),
          ],
        ),
      ),
    );

    // Simulate WiFi check
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    // Mock WiFi validation result
    final currentSSID = 'Classroom_WiFi_101'; // Mock SSID

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.wifi,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('WiFi Connected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status: Connected'),
            const SizedBox(height: 8),
            Text('Current Network: $currentSSID'),
            const SizedBox(height: 8),
            const Text('Signal Strength: Strong'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkLocation(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Checking location...'),
          ],
        ),
      ),
    );

    // Simulate location check
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    // Mock location validation result
    final currentLocation = 'Room 101, Building A';
    final distance = '5 meters';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('In Classroom'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status: Inside classroom area'),
            const SizedBox(height: 8),
            Text('Current Location: $currentLocation'),
            const SizedBox(height: 8),
            Text('Distance from center: $distance'),
            const SizedBox(height: 8),
            const Text('Accuracy: High'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

}

// Teacher Dashboard
class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Welcome Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome Teacher!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your classes and attendance',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Today's Classes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Classes",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTeacherClassItem(context, 'Mathematics', 'Room 101', '9:00 AM', '25 students', true),
                        _buildTeacherClassItem(context, 'Physics', 'Room 102', '10:30 AM', '30 students', false),
                        _buildTeacherClassItem(context, 'Chemistry', 'Room 103', '2:00 PM', '28 students', false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Quick Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _navigateToQRGenerator(context),
                                icon: const Icon(Icons.qr_code),
                                label: const Text('Generate QR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _navigateToClasses(context),
                                icon: const Icon(Icons.class_),
                                label: const Text('View Classes'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _viewAttendanceReport(context),
                                icon: const Icon(Icons.analytics),
                                label: const Text('Reports'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _manageStudents(context),
                                icon: const Icon(Icons.people),
                                label: const Text('Students'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _manageCampus(context),
                                icon: const Icon(Icons.location_on),
                                label: const Text('Campus'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _checkWiFiConnection(context),
                                icon: const Icon(Icons.wifi),
                                label: const Text('WiFi Status'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Class Statistics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class Statistics',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem('Total Classes', '12', Colors.blue),
                            ),
                            Expanded(
                              child: _buildStatItem('Avg Attendance', '85%', Colors.green),
                            ),
                            Expanded(
                              child: _buildStatItem('Total Students', '83', Colors.orange),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherClassItem(BuildContext context, String subject, String room, String time, String students, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.blue : Colors.grey,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$room • $time',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  students,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _navigateToQRGenerator(BuildContext context) {
    // Navigate to QR Generator tab
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeState != null) {
      homeState._currentIndex = 2; // QR Generator tab index
    }
  }

  void _navigateToClasses(BuildContext context) {
    // Navigate to Classes tab
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeState != null) {
      homeState._currentIndex = 1; // Classes tab index
    }
  }

  void _viewAttendanceReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Report'),
        content: const Text('View detailed attendance reports for your classes.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _manageStudents(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Students'),
        content: const Text('Manage student enrollment and class assignments.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _manageCampus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DemoCampusSetupScreen(),
      ),
    );
  }

  Future<void> _checkWiFiConnection(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Checking WiFi connection...'),
          ],
        ),
      ),
    );

    // Simulate WiFi check
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    // Mock WiFi validation result
    final currentSSID = 'Classroom_WiFi_101'; // Mock SSID

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.wifi,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('WiFi Connected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status: Connected'),
            const SizedBox(height: 8),
            Text('Current Network: $currentSSID'),
            const SizedBox(height: 8),
            const Text('Signal Strength: Strong'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkLocation(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Checking location...'),
          ],
        ),
      ),
    );

    // Simulate location check
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    // Mock location validation result
    final currentLocation = 'Room 101, Building A';
    final distance = '5 meters';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('In Classroom'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status: Inside classroom area'),
            const SizedBox(height: 8),
            Text('Current Location: $currentLocation'),
            const SizedBox(height: 8),
            Text('Distance from center: $distance'),
            const SizedBox(height: 8),
            const Text('Accuracy: High'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

}

// Student Attendance Screen
class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<AttendanceRecord> _attendanceRecords = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  void _loadAttendanceData() {
    // Mock attendance data for student
    _attendanceRecords = [
      AttendanceRecord(
        id: '1',
        subject: 'Mathematics',
        teacher: 'Dr. Smith',
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: 'Present',
        location: 'Room 101',
        wifiSSID: 'Classroom_WiFi_101',
      ),
      AttendanceRecord(
        id: '2',
        subject: 'Physics',
        teacher: 'Prof. Johnson',
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Present',
        location: 'Room 102',
        wifiSSID: 'Classroom_WiFi_102',
      ),
      AttendanceRecord(
        id: '3',
        subject: 'Chemistry',
        teacher: 'Dr. Brown',
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: 'Late',
        location: 'Room 103',
        wifiSSID: 'Classroom_WiFi_103',
      ),
      AttendanceRecord(
        id: '4',
        subject: 'Biology',
        teacher: 'Dr. Wilson',
        date: DateTime.now().subtract(const Duration(days: 4)),
        status: 'Absent',
        location: 'Room 104',
        wifiSSID: 'Classroom_WiFi_104',
      ),
      AttendanceRecord(
        id: '5',
        subject: 'English',
        teacher: 'Ms. Davis',
        date: DateTime.now().subtract(const Duration(days: 5)),
        status: 'Present',
        location: 'Room 105',
        wifiSSID: 'Classroom_WiFi_105',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _getFilteredRecords();
    final stats = _calculateStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Records')),
              const PopupMenuItem(value: 'Present', child: Text('Present Only')),
              const PopupMenuItem(value: 'Late', child: Text('Late Only')),
              const PopupMenuItem(value: 'Absent', child: Text('Absent Only')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedFilter),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Classes',
                    stats['total'].toString(),
                    Icons.school,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Present',
                    stats['present'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Late',
                    stats['late'].toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Absent',
                    stats['absent'].toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Attendance Percentage
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'My Attendance Percentage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CircularProgressIndicator(
                      value: (stats['percentage'] ?? 0) / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPercentageColor(stats['percentage'] ?? 0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(stats['percentage'] ?? 0).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getPercentageColor(stats['percentage'] ?? 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Attendance Records
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Attendance History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Filter: $_selectedFilter',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filteredRecords.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No attendance records found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...filteredRecords.map((record) => 
                        _buildAttendanceRecordItem(record)
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceRecordItem(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(record.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(record.status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(record.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.teacher} • ${_formatDate(record.date)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.location} • ${record.wifiSSID}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(record.status),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              record.status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<AttendanceRecord> _getFilteredRecords() {
    if (_selectedFilter == 'All') {
      return _attendanceRecords;
    }
    return _attendanceRecords.where((record) => 
      record.status.toLowerCase() == _selectedFilter.toLowerCase()
    ).toList();
  }

  Map<String, double> _calculateStats() {
    final total = _attendanceRecords.length.toDouble();
    final present = _attendanceRecords.where((r) => r.status == 'Present').length.toDouble();
    final late = _attendanceRecords.where((r) => r.status == 'Late').length.toDouble();
    final absent = _attendanceRecords.where((r) => r.status == 'Absent').length.toDouble();
    
    final percentage = total > 0 ? ((present + late) / total) * 100 : 0.0;
    
    return {
      'total': total,
      'present': present,
      'late': late,
      'absent': absent,
      'percentage': percentage,
    };
  }
}

// Teacher Attendance Screen
class TeacherAttendanceScreen extends StatelessWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 24),
            Text(
              'Class Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Manage your classes and view attendance reports.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// QR Generator Screen
class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final AttendanceCodeService _attendanceCodeService = AttendanceCodeService();
  final TextEditingController _durationController = TextEditingController(text: '60');
  final TextEditingController _subjectController = TextEditingController(text: 'Demo Class');
  
  String? _generatedCode;
  QrImageView? _qrCodeImage;
  DateTime? _expiresAt;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isGenerating = false;
  bool _isCountdownActive = false;

  @override
  void dispose() {
    _durationController.dispose();
    _subjectController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _startCountdown() async {
    if (_generatedCode == null) return;
    
    try {
      // Call backend to start countdown
      final result = await _attendanceCodeService.startCountdown(code: _generatedCode!);
      
      if (result.success) {
        // Set expiration time when countdown actually starts
        final duration = int.tryParse(_durationController.text) ?? 60;
        _expiresAt = DateTime.now().add(Duration(minutes: duration));
        
        setState(() {
          _isCountdownActive = true;
          _remainingSeconds = duration * 60;
        });
        
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final now = DateTime.now();
          final remaining = _expiresAt!.difference(now).inSeconds;
          
          if (remaining <= 0) {
            setState(() {
              _remainingSeconds = 0;
              _isCountdownActive = false;
              _generatedCode = null;
              _qrCodeImage = null;
              _expiresAt = null;
            });
            timer.cancel();
          } else {
            setState(() {
              _remainingSeconds = remaining;
            });
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Countdown started! QR code will expire in ${_formatTime(_remainingSeconds)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start countdown: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting countdown: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountdownActive = false;
      _remainingSeconds = 0;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _generateQRCode() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
    });

    try {
      final duration = int.tryParse(_durationController.text) ?? 60;
      final subject = _subjectController.text.trim().isEmpty ? 'Demo Class' : _subjectController.text.trim();
      
      final result = await _attendanceCodeService.generateAttendanceCode(
        durationMinutes: duration,
        subject: subject,
      );

      if (result.success) {
        setState(() {
          _generatedCode = result.code;
          _qrCodeImage = result.qrCodeImage;
          // Don't set _expiresAt here - it will be set when countdown starts
          _expiresAt = null;
          _remainingSeconds = duration * 60;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Code generated successfully: ${result.code}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate QR code: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_generatedCode != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isGenerating ? null : () {
                setState(() {
                  _generatedCode = null;
                  _qrCodeImage = null;
                  _expiresAt = null;
                  _isCountdownActive = false;
                  _remainingSeconds = 0;
                });
                _countdownTimer?.cancel();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class Configuration',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject/Class Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                        suffixText: 'min',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Generate QR Button
            ElevatedButton.icon(
              onPressed: _isGenerating || _generatedCode != null ? null : _generateQRCode,
              icon: _isGenerating 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code),
              label: Text(_isGenerating ? 'Generating...' : 'Generate QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _generatedCode != null ? Colors.grey : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            if (_generatedCode != null) ...[
              const SizedBox(height: 24),
              
              // QR Code Display Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Generated QR Code',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // QR Code Image
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _qrCodeImage ?? const CircularProgressIndicator(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Generated Code Text
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.code, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              _generatedCode!,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Countdown Timer
                      if (_generatedCode != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isCountdownActive ? Colors.orange.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isCountdownActive ? Colors.orange.shade200 : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCountdownActive ? Icons.timer : Icons.timer_off,
                                color: _isCountdownActive ? Colors.orange : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isCountdownActive 
                                  ? 'Expires in: ${_formatTime(_remainingSeconds)}'
                                  : 'Countdown not started - QR code will not expire',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isCountdownActive ? Colors.orange.shade700 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Start Countdown Button
                      if (!_isCountdownActive && _generatedCode != null)
                        ElevatedButton.icon(
                          onPressed: _startCountdown,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Countdown'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      
                      // Stop Countdown Button
                      if (_isCountdownActive)
                        ElevatedButton.icon(
                          onPressed: _stopCountdown,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop Countdown'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Admin Dashboard
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Colors.purple,
            ),
            SizedBox(height: 24),
            Text(
              'Admin Panel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Manage system settings and view analytics.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Admin Reports Screen
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 80,
              color: Colors.purple,
            ),
            SizedBox(height: 24),
            Text(
              'Reports & Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'View detailed reports and analytics.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Admin Settings Screen
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 80,
              color: Colors.purple,
            ),
            SizedBox(height: 24),
            Text(
              'System Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Configure system settings and preferences.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceRecord> _attendanceRecords = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  void _loadAttendanceData() {
    // Mock attendance data
    _attendanceRecords = [
      AttendanceRecord(
        id: '1',
        subject: 'Mathematics',
        teacher: 'Dr. Smith',
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: 'Present',
        location: 'Room 101',
        wifiSSID: 'Classroom_WiFi_101',
      ),
      AttendanceRecord(
        id: '2',
        subject: 'Physics',
        teacher: 'Prof. Johnson',
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Present',
        location: 'Room 102',
        wifiSSID: 'Classroom_WiFi_102',
      ),
      AttendanceRecord(
        id: '3',
        subject: 'Chemistry',
        teacher: 'Dr. Brown',
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: 'Late',
        location: 'Room 103',
        wifiSSID: 'Classroom_WiFi_103',
      ),
      AttendanceRecord(
        id: '4',
        subject: 'Biology',
        teacher: 'Dr. Wilson',
        date: DateTime.now().subtract(const Duration(days: 4)),
        status: 'Absent',
        location: 'Room 104',
        wifiSSID: 'Classroom_WiFi_104',
      ),
      AttendanceRecord(
        id: '5',
        subject: 'English',
        teacher: 'Ms. Davis',
        date: DateTime.now().subtract(const Duration(days: 5)),
        status: 'Present',
        location: 'Room 105',
        wifiSSID: 'Classroom_WiFi_105',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _getFilteredRecords();
    final stats = _calculateStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Records')),
              const PopupMenuItem(value: 'Present', child: Text('Present Only')),
              const PopupMenuItem(value: 'Late', child: Text('Late Only')),
              const PopupMenuItem(value: 'Absent', child: Text('Absent Only')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedFilter),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Classes',
                    stats['total'].toString(),
                    Icons.school,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Present',
                    stats['present'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Late',
                    stats['late'].toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Absent',
                    stats['absent'].toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Attendance Percentage
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Attendance Percentage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CircularProgressIndicator(
                      value: (stats['percentage'] ?? 0) / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPercentageColor(stats['percentage'] ?? 0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(stats['percentage'] ?? 0).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getPercentageColor(stats['percentage'] ?? 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Attendance Records
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Attendance History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Filter: $_selectedFilter',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filteredRecords.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No attendance records found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...filteredRecords.map((record) => 
                        _buildAttendanceRecordItem(record)
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceRecordItem(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(record.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(record.status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(record.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.teacher} • ${_formatDate(record.date)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.location} • ${record.wifiSSID}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(record.status),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              record.status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<AttendanceRecord> _getFilteredRecords() {
    if (_selectedFilter == 'All') {
      return _attendanceRecords;
    }
    return _attendanceRecords.where((record) => 
      record.status.toLowerCase() == _selectedFilter.toLowerCase()
    ).toList();
  }

  Map<String, double> _calculateStats() {
    final total = _attendanceRecords.length.toDouble();
    final present = _attendanceRecords.where((r) => r.status == 'Present').length.toDouble();
    final late = _attendanceRecords.where((r) => r.status == 'Late').length.toDouble();
    final absent = _attendanceRecords.where((r) => r.status == 'Absent').length.toDouble();
    
    final percentage = total > 0 ? ((present + late) / total) * 100 : 0.0;
    
    return {
      'total': total,
      'present': present,
      'late': late,
      'absent': absent,
      'percentage': percentage,
    };
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = false;
  List<AttendanceRecord> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    _loadMockAttendanceData();
  }

  void _loadMockAttendanceData() {
    // Mock attendance data
    _attendanceHistory = [
      AttendanceRecord(
        id: '1',
        subject: 'Mathematics',
        teacher: 'Dr. Smith',
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: 'Present',
        location: 'Room 101',
        wifiSSID: 'Classroom_WiFi_101',
      ),
      AttendanceRecord(
        id: '2',
        subject: 'Physics',
        teacher: 'Prof. Johnson',
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Present',
        location: 'Room 102',
        wifiSSID: 'Classroom_WiFi_102',
      ),
      AttendanceRecord(
        id: '3',
        subject: 'Chemistry',
        teacher: 'Dr. Brown',
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: 'Late',
        location: 'Room 103',
        wifiSSID: 'Classroom_WiFi_103',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showAttendanceHistory(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // QR Scanner Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'QR Code Scanner',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan QR codes to mark your attendance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Scanner Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? null : _startQRScan,
                        icon: _isScanning 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_scanner),
                        label: Text(_isScanning ? 'Scanning...' : 'Start QR Scan'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    
                    // Demo QR Codes
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Demo QR Codes:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Demo QR Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simulateQRScan('MATH_101_${DateTime.now().millisecondsSinceEpoch}'),
                            child: const Text('Math Class'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simulateQRScan('PHYSICS_102_${DateTime.now().millisecondsSinceEpoch}'),
                            child: const Text('Physics Class'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simulateQRScan('CHEMISTRY_103_${DateTime.now().millisecondsSinceEpoch}'),
                            child: const Text('Chemistry Class'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simulateQRScan('INVALID_QR_CODE'),
                            child: const Text('Invalid QR'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent Attendance
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Attendance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_attendanceHistory.isEmpty)
                      const Center(
                        child: Text(
                          'No attendance records yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...(_attendanceHistory.take(3).map((record) => 
                        _buildAttendanceItem(record)
                      )),
                    if (_attendanceHistory.length > 3)
                      TextButton(
                        onPressed: _showAttendanceHistory,
                        child: const Text('View All Records'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceItem(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(record.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(record.status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(record.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${record.teacher} • ${_formatDate(record.date)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${record.location} • ${record.wifiSSID}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(record.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              record.status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _startQRScan() async {
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isScanning = false;
    });

    // Show camera permission dialog
    _showCameraPermissionDialog();
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission'),
        content: const Text(
          'This app needs camera permission to scan QR codes. '
          'In a real app, this would request camera permission and open the camera view.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateQRScan('MATH_101_${DateTime.now().millisecondsSinceEpoch}');
            },
            child: const Text('Use Demo QR'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateQRScan(String qrData) async {

    // Parse QR data
    final parts = qrData.split('_');
    if (parts.length < 3) {
      _showErrorDialog('Invalid QR Code', 'The scanned QR code is not valid for attendance marking.');
      return;
    }

    final subject = parts[0];
    final room = parts[1];
    final timestamp = parts[2];

    // Simulate validation
    await Future.delayed(const Duration(seconds: 1));

    // Check if it's a valid session
    if (qrData.startsWith('INVALID')) {
      _showErrorDialog('Invalid Session', 'This QR code is not valid for attendance marking.');
      return;
    }

    // Simulate WiFi and location validation
    final wifiValid = await _validateWiFi();
    final locationValid = await _validateLocation();
    final campusValid = await _validateCampusGeofence();

    if (!wifiValid) {
      _showErrorDialog('WiFi Validation Failed', 'You must be connected to the classroom WiFi to mark attendance.');
      return;
    }

    if (!locationValid) {
      _showErrorDialog('Location Validation Failed', 'You must be in the classroom to mark attendance.');
      return;
    }

    if (!campusValid) {
      _showCampusGeofenceErrorDialog();
      return;
    }

    // Mark attendance
    _markAttendance(subject, room, timestamp);
  }

  Future<bool> _validateWiFi() async {
    // Simulate WiFi validation
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Mock: always valid for demo
  }

  Future<bool> _validateLocation() async {
    try {
      final result = await StudentLocationValidator.validateStudentLocation();
      return result.success && result.isInsideCampus;
    } catch (e) {
      print('Location validation error: $e');
      return false;
    }
  }

  Future<bool> _validateCampusGeofence() async {
    try {
      final result = await StudentLocationValidator.validateStudentLocation();
      return result.success && result.isInsideCampus;
    } catch (e) {
      print('Campus geofence validation error: $e');
      return false;
    }
  }

  void _markAttendance(String subject, String room, String timestamp) {
    final now = DateTime.now();
    final isLate = now.hour > 9 || (now.hour == 9 && now.minute > 15); // Mock late condition

    final newRecord = AttendanceRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: _getSubjectName(subject),
      teacher: _getTeacherName(subject),
      date: now,
      status: isLate ? 'Late' : 'Present',
      location: 'Room $room',
      wifiSSID: 'Classroom_WiFi_$room',
    );

    setState(() {
      _attendanceHistory.insert(0, newRecord);
    });

    _showSuccessDialog(
      'Attendance Marked!',
      'Successfully marked attendance for ${newRecord.subject}',
      newRecord,
    );
  }

  String _getSubjectName(String code) {
    switch (code.toUpperCase()) {
      case 'MATH':
        return 'Mathematics';
      case 'PHYSICS':
        return 'Physics';
      case 'CHEMISTRY':
        return 'Chemistry';
      default:
        return code;
    }
  }

  String _getTeacherName(String subject) {
    switch (subject.toUpperCase()) {
      case 'MATH':
        return 'Dr. Smith';
      case 'PHYSICS':
        return 'Prof. Johnson';
      case 'CHEMISTRY':
        return 'Dr. Brown';
      default:
        return 'Unknown Teacher';
    }
  }

  void _showSuccessDialog(String title, String message, AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subject: ${record.subject}'),
                  Text('Teacher: ${record.teacher}'),
                  Text('Status: ${record.status}'),
                  Text('Time: ${_formatDate(record.date)}'),
                  Text('Location: ${record.location}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCampusGeofenceErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Outside Campus Area'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are not inside the campus area. To mark attendance, you must be within the designated campus boundaries.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'What you can do:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Move to the campus area'),
                  const Text('• Check your location services'),
                  const Text('• Contact your teacher if you\'re on campus'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _checkLocation(context);
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Check Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkLocation(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Checking location...'),
          ],
        ),
      ),
    );

    // Simulate location check
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    // Mock location validation result
    final currentLocation = 'Room 101, Building A';
    final distance = '5 meters';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('In Classroom'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status: Inside classroom area'),
            const SizedBox(height: 8),
            Text('Current Location: $currentLocation'),
            const SizedBox(height: 8),
            Text('Distance from center: $distance'),
            const SizedBox(height: 8),
            const Text('Accuracy: High'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _attendanceHistory.length,
            itemBuilder: (context, index) {
              final record = _attendanceHistory[index];
              return _buildAttendanceItem(record);
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class AttendanceRecord {
  final String id;
  final String subject;
  final String teacher;
  final DateTime date;
  final String status;
  final String location;
  final String wifiSSID;

  AttendanceRecord({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.date,
    required this.status,
    required this.location,
    required this.wifiSSID,
  });
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            authProvider.userRole?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${authProvider.userRole?.toUpperCase()} User',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome to Attendance Manager',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Settings Card
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        subtitle: const Text('Manage notification preferences'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showComingSoon(context, 'Notification Settings'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Privacy & Security'),
                        subtitle: const Text('Manage your privacy settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showComingSoon(context, 'Privacy Settings'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Help & Support'),
                        subtitle: const Text('Get help and contact support'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showComingSoon(context, 'Help & Support'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // App Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Version: 1.0.0'),
                        const Text('Build: Demo Version'),
                        const Text('Last Updated: Today'),
                        const SizedBox(height: 16),
                        const Text(
                          'This is a comprehensive attendance management system with WiFi validation, location tracking, QR code scanning, and offline support.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in the full version.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}