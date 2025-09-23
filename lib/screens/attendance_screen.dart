import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    _loadActiveSessions();
  }

  Future<void> _loadActiveSessions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    if (authProvider.user != null && authProvider.isStudent) {
      await attendanceProvider.loadActiveSessions(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveSessions,
          ),
        ],
      ),
      body: Consumer2<AuthProvider, AttendanceProvider>(
        builder: (context, authProvider, attendanceProvider, child) {
          if (authProvider.user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authProvider.isStudent) {
            return _buildStudentView(attendanceProvider);
          } else if (authProvider.isTeacher) {
            return _buildTeacherView();
          } else {
            return _buildAdminView();
          }
        },
      ),
    );
  }

  Widget _buildStudentView(AttendanceProvider attendanceProvider) {
    if (attendanceProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadActiveSessions,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildAttendanceHeader(),
            
            const SizedBox(height: 20),
            
            // Active Sessions
            if (attendanceProvider.activeSessions.isNotEmpty) ...[
              Text(
                'Active Sessions',
                style: AppTheme.titleLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...attendanceProvider.activeSessions.map((session) => 
                _buildSessionCard(session, attendanceProvider)
              ).toList(),
            ] else ...[
              _buildEmptyState(),
            ],
            
            const SizedBox(height: 20),
            
            // Attendance History
            _buildAttendanceHistory(),
            
            const SizedBox(height: 20),
            
            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Attendance',
                style: AppTheme.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Track your attendance and view records',
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Active Sessions',
            style: AppTheme.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no active attendance sessions at the moment.',
            style: AppTheme.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadActiveSessions,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Attendance',
          style: AppTheme.titleLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHistoryItem('Mathematics', 'Present', DateTime.now().subtract(const Duration(days: 1)), true),
                const Divider(),
                _buildHistoryItem('Physics', 'Present', DateTime.now().subtract(const Duration(days: 2)), true),
                const Divider(),
                _buildHistoryItem('Chemistry', 'Absent', DateTime.now().subtract(const Duration(days: 3)), false),
                const Divider(),
                _buildHistoryItem('English', 'Present', DateTime.now().subtract(const Duration(days: 4)), true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(String subject, String status, DateTime date, bool isPresent) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isPresent ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: AppTheme.titleMedium,
              ),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: AppTheme.labelSmall.copyWith(
              color: isPresent ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.titleLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.qr_code_scanner,
                title: 'Scan QR',
                subtitle: 'Mark attendance',
                onTap: () {
                  // Navigate to QR scanner
                  Navigator.pushNamed(context, '/qr-scanner');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'Analytics',
                subtitle: 'View statistics',
                onTap: () {
                  // Navigate to analytics
                  Navigator.pushNamed(context, '/analytics');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(session, AttendanceProvider attendanceProvider) {
    final remainingTime = attendanceProvider.getRemainingTime(session);
    final isActive = attendanceProvider.isSessionActive(session);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: AppTheme.titleLarge,
                      ),
                      if (session.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          session.description!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.successColor : AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'ENDED',
                    style: AppTheme.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Session Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.access_time,
                    label: 'Duration',
                    value: '${session.durationMinutes} min',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.timer,
                    label: 'Remaining',
                    value: attendanceProvider.formatRemainingTime(remainingTime),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Validation Requirements
            if (session.hasQrCode) ...[
              _buildRequirementItem(
                icon: Icons.qr_code,
                label: 'QR Code Required',
                isRequired: true,
              ),
              const SizedBox(height: 8),
            ],
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isActive ? () => _markAttendance(session, attendanceProvider) : null,
                icon: const Icon(Icons.check_circle),
                label: Text(isActive ? 'Mark Attendance' : 'Session Ended'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementItem({
    required IconData icon,
    required String label,
    required bool isRequired,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isRequired ? AppTheme.warningColor : AppTheme.successColor,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: isRequired ? AppTheme.warningColor : AppTheme.successColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherView() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: authProvider.getPersistentSessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final persistentSessions = snapshot.data ?? [];

            if (persistentSessions.isEmpty) {
              return _buildEmptyTeacherState();
            }

            return _buildPersistentSessionsView(persistentSessions);
          },
        );
      },
    );
  }

  Widget _buildEmptyTeacherState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Active QR Sessions',
            style: AppTheme.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a QR code to start an attendance session.',
            style: AppTheme.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to QR generator screen
              Navigator.pushNamed(context, '/qr-generator');
            },
            icon: const Icon(Icons.qr_code),
            label: const Text('Generate QR Code'),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistentSessionsView(List<Map<String, dynamic>> sessions) {
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.getPersistentSessions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _buildPersistentSessionCard(session);
        },
      ),
    );
  }

  Widget _buildPersistentSessionCard(Map<String, dynamic> session) {
    final classInfo = session['class'] as Map<String, dynamic>?;
    final qrCode = session['qrCode'] as Map<String, dynamic>?;
    final expiresAt = qrCode?['expiresAt'] != null 
        ? DateTime.parse(qrCode!['expiresAt']) 
        : null;
    final isActive = qrCode?['isActive'] == true;
    final isPersistent = qrCode?['persistent'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classInfo?['name'] ?? 'Unknown Class',
                        style: AppTheme.titleLarge,
                      ),
                      if (classInfo?['subject'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          classInfo!['subject'],
                          style: AppTheme.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? (isPersistent ? AppTheme.warningColor : AppTheme.successColor)
                        : AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive 
                        ? (isPersistent ? 'PERSISTENT' : 'ACTIVE')
                        : 'INACTIVE',
                    style: AppTheme.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Session Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.access_time,
                    label: 'Expires',
                    value: expiresAt != null ? _formatExpirationTime(expiresAt) : 'Unknown',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.qr_code,
                    label: 'Status',
                    value: isPersistent ? 'Persistent' : 'Normal',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isActive ? () => _viewQRCode(session) : null,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View QR'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isActive ? () => _endSession(session) : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('End Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatExpirationTime(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _viewQRCode(Map<String, dynamic> session) {
    // Show QR code in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - ${session['class']?['name'] ?? 'Unknown Class'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'QR Code Image Here',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Students can scan this QR code to mark attendance.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _endSession(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: Text(
          'Are you sure you want to end the attendance session for ${session['class']?['name'] ?? 'this class'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement end session functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session ended successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 24),
          Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Admin features coming soon...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAttendance(session, AttendanceProvider attendanceProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) return;

    // Show QR scanner for attendance
    Navigator.pushNamed(context, '/qr-scanner');
  }
}
