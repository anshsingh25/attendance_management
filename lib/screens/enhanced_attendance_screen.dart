import 'dart:async';
import 'package:flutter/material.dart';
import '../services/continuous_location_monitor.dart';

/// Enhanced attendance screen with continuous location monitoring
class EnhancedAttendanceScreen extends StatefulWidget {
  final String subject;
  final String room;
  final String sessionId;

  const EnhancedAttendanceScreen({
    super.key,
    required this.subject,
    required this.room,
    required this.sessionId,
  });

  @override
  State<EnhancedAttendanceScreen> createState() => _EnhancedAttendanceScreenState();
}

class _EnhancedAttendanceScreenState extends State<EnhancedAttendanceScreen> {
  bool _isMonitoring = false;
  bool _isInsideCampus = false;
  bool _hasError = false;
  String? _errorMessage;
  LocationStatus? _currentStatus;
  MonitoringStats? _monitoringStats;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }

  /// Start location monitoring
  Future<void> _startMonitoring() async {
    try {
      setState(() {
        _isMonitoring = true;
        _hasError = false;
        _errorMessage = null;
      });

      final success = await ContinuousLocationMonitor.startMonitoring(
        interval: const Duration(seconds: 10),
        requiredAccuracy: 50.0, // 50 meters accuracy required
        onStatusUpdate: _onLocationStatusUpdate,
      );

      if (!success) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to start location monitoring. Please check permissions.';
        });
      }

      // Start periodic status updates
      _statusUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _updateMonitoringStats();
      });

    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error starting monitoring: $e';
      });
    }
  }

  /// Stop location monitoring
  Future<void> _stopMonitoring() async {
    await ContinuousLocationMonitor.stopMonitoring();
    _statusUpdateTimer?.cancel();
    setState(() {
      _isMonitoring = false;
    });
  }

  /// Handle location status updates
  void _onLocationStatusUpdate(LocationStatus status) {
    setState(() {
      _currentStatus = status;
      _isInsideCampus = status.isInsideCampus;
      _hasError = status.hasError;
      _errorMessage = status.errorMessage;
    });
  }

  /// Update monitoring statistics
  void _updateMonitoringStats() {
    final stats = ContinuousLocationMonitor.getMonitoringStats();
    setState(() {
      _monitoringStats = stats;
    });
  }

  /// Mark attendance
  Future<void> _markAttendance() async {
    if (!_isInsideCampus) {
      _showErrorDialog('Cannot mark attendance', 
          'You must be inside the campus area to mark attendance.');
      return;
    }

    if (_monitoringStats == null || !_monitoringStats!.isConsistentlyInside) {
      _showErrorDialog('Cannot mark attendance', 
          'You must be consistently inside the campus for at least 5 minutes to mark attendance.');
      return;
    }

    try {
      // Show confirmation dialog
      final confirmed = await _showConfirmationDialog();
      if (!confirmed) return;

      // Mark attendance
      await _performAttendanceMarking();
      
    } catch (e) {
      _showErrorDialog('Attendance Error', 'Failed to mark attendance: $e');
    }
  }

  /// Show confirmation dialog
  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${widget.subject}'),
            Text('Room: ${widget.room}'),
            Text('Session: ${widget.sessionId}'),
            const SizedBox(height: 16),
            const Text('Are you sure you want to mark your attendance?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Attendance'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Perform attendance marking
  Future<void> _performAttendanceMarking() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Marking attendance...'),
          ],
        ),
      ),
    );

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success dialog
      _showSuccessDialog();
      
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      _showErrorDialog('Attendance Error', 'Failed to mark attendance: $e');
    }
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Attendance Marked'),
          ],
        ),
        content: const Text('Your attendance has been successfully marked!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Subject: ${widget.subject}'),
                    Text('Room: ${widget.room}'),
                    Text('Session ID: ${widget.sessionId}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Location Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isMonitoring ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isMonitoring ? 'MONITORING' : 'STOPPED',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildLocationStatus(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Monitoring Stats Card
            if (_monitoringStats != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monitoring Statistics',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Total Updates: ${_monitoringStats!.totalUpdates}'),
                      Text('Average Accuracy: ${_monitoringStats!.averageAccuracy.toStringAsFixed(1)}m'),
                      Text('Duration: ${_formatDuration(_monitoringStats!.monitoringDuration)}'),
                      Text('Consistently Inside: ${_monitoringStats!.isConsistentlyInside ? "Yes" : "No"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Current Location Info
            if (_currentStatus != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_currentStatus!.currentLatitude != null)
                        Text('Latitude: ${_currentStatus!.currentLatitude!.toStringAsFixed(6)}'),
                      if (_currentStatus!.currentLongitude != null)
                        Text('Longitude: ${_currentStatus!.currentLongitude!.toStringAsFixed(6)}'),
                      Text('Accuracy: ${_currentStatus!.accuracy.toStringAsFixed(1)}m'),
                      if (_currentStatus!.campusName != null)
                        Text('Campus: ${_currentStatus!.campusName}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Spacer(),

            // Mark Attendance Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isInsideCampus && _monitoringStats?.isConsistentlyInside == true
                    ? _markAttendance
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isInsideCampus ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isInsideCampus 
                      ? 'Mark Attendance' 
                      : 'Move to Campus Area',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Stop Monitoring Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
                child: Text(_isMonitoring ? 'Stop Monitoring' : 'Start Monitoring'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build location status widget
  Widget _buildLocationStatus() {
    if (_hasError) {
      return Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(_errorMessage ?? 'Unknown error')),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          _isInsideCampus ? Icons.check_circle : Icons.cancel,
          color: _isInsideCampus ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isInsideCampus 
                ? 'Inside Campus Area' 
                : 'Outside Campus Area',
            style: TextStyle(
              color: _isInsideCampus ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
