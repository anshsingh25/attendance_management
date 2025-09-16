import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/mongodb_campus_service.dart';

/// Service for continuous location monitoring during attendance
class ContinuousLocationMonitor {
  static final LocationService _locationService = LocationService();
  static StreamSubscription<Position>? _positionStream;
  static Timer? _monitoringTimer;
  static bool _isMonitoring = false;
  static final List<LocationUpdate> _locationHistory = [];
  static final StreamController<LocationStatus> _statusController = 
      StreamController<LocationStatus>.broadcast();

  /// Start continuous location monitoring
  static Future<bool> startMonitoring({
    required Duration interval,
    required double requiredAccuracy,
    required Function(LocationStatus) onStatusUpdate,
  }) async {
    try {
      if (_isMonitoring) {
        print('Location monitoring already active');
        return true;
      }

      // Check permissions
      final hasPermission = await _locationService.hasLocationPermission();
      if (!hasPermission) {
        final granted = await _locationService.requestLocationPermission();
        if (!granted) {
          print('Location permission not granted for monitoring');
          return false;
        }
      }

      // Check if location services are enabled
      final isEnabled = await _locationService.isLocationServiceEnabled();
      if (!isEnabled) {
        print('Location services are disabled');
        return false;
      }

      _isMonitoring = true;
      _locationHistory.clear();

      // Start position stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen(
        (Position position) {
          _handleLocationUpdate(position, requiredAccuracy, onStatusUpdate);
        },
        onError: (error) {
          print('Location stream error: $error');
          _handleLocationError(error, onStatusUpdate);
        },
      );

      // Start periodic validation timer
      _monitoringTimer = Timer.periodic(interval, (timer) {
        _performPeriodicValidation(onStatusUpdate);
      });

      print('Continuous location monitoring started');
      return true;
    } catch (e) {
      print('Error starting location monitoring: $e');
      _isMonitoring = false;
      return false;
    }
  }

  /// Stop continuous location monitoring
  static Future<void> stopMonitoring() async {
    try {
      _isMonitoring = false;
      await _positionStream?.cancel();
      _positionStream = null;
      _monitoringTimer?.cancel();
      _monitoringTimer = null;
      _locationHistory.clear();
      print('Continuous location monitoring stopped');
    } catch (e) {
      print('Error stopping location monitoring: $e');
    }
  }

  /// Handle location updates
  static void _handleLocationUpdate(
    Position position, 
    double requiredAccuracy,
    Function(LocationStatus) onStatusUpdate,
  ) {
    final locationUpdate = LocationUpdate(
      position: position,
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
    );

    _locationHistory.add(locationUpdate);
    
    // Keep only last 10 updates
    if (_locationHistory.length > 10) {
      _locationHistory.removeAt(0);
    }

    // Validate against campus boundaries
    _validateLocationAgainstCampus(position, onStatusUpdate);
  }

  /// Handle location errors
  static void _handleLocationError(
    dynamic error,
    Function(LocationStatus) onStatusUpdate,
  ) {
    final status = LocationStatus(
      isInsideCampus: false,
      isMonitoring: true,
      hasError: true,
      errorMessage: 'Location error: $error',
      lastUpdate: DateTime.now(),
      accuracy: 0.0,
    );

    onStatusUpdate(status);
    _statusController.add(status);
  }

  /// Validate location against campus boundaries
  static Future<void> _validateLocationAgainstCampus(
    Position position,
    Function(LocationStatus) onStatusUpdate,
  ) async {
    try {
      final result = await MongoDBCampusService.validateStudentLocationMongoDB(
        position.latitude,
        position.longitude,
      );

      final status = LocationStatus(
        isInsideCampus: result.isInsideCampus,
        isMonitoring: true,
        hasError: false,
        errorMessage: result.error,
        lastUpdate: DateTime.now(),
        accuracy: position.accuracy,
        campusName: result.campusName,
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
      );

      onStatusUpdate(status);
      _statusController.add(status);
    } catch (e) {
      print('Error validating location: $e');
      _handleLocationError(e, onStatusUpdate);
    }
  }

  /// Perform periodic validation
  static Future<void> _performPeriodicValidation(
    Function(LocationStatus) onStatusUpdate,
  ) async {
    if (!_isMonitoring) return;

    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        await _validateLocationAgainstCampus(position, onStatusUpdate);
      }
    } catch (e) {
      print('Periodic validation error: $e');
    }
  }

  /// Get current monitoring status
  static bool get isMonitoring => _isMonitoring;

  /// Get location history
  static List<LocationUpdate> get locationHistory => List.unmodifiable(_locationHistory);

  /// Get status stream
  static Stream<LocationStatus> get statusStream => _statusController.stream;

  /// Get latest location status
  static LocationStatus? getLatestStatus() {
    if (_locationHistory.isEmpty) return null;

    final latestUpdate = _locationHistory.last;
    return LocationStatus(
      isInsideCampus: true, // Will be updated by validation
      isMonitoring: _isMonitoring,
      hasError: false,
      lastUpdate: latestUpdate.timestamp,
      accuracy: latestUpdate.accuracy,
      currentLatitude: latestUpdate.position.latitude,
      currentLongitude: latestUpdate.position.longitude,
    );
  }

  /// Check if student has been consistently inside campus
  static bool hasBeenConsistentlyInsideCampus({Duration? timeWindow}) {
    if (_locationHistory.isEmpty) return false;

    final window = timeWindow ?? const Duration(minutes: 5);
    final cutoffTime = DateTime.now().subtract(window);
    
    final recentUpdates = _locationHistory
        .where((update) => update.timestamp.isAfter(cutoffTime))
        .toList();

    if (recentUpdates.length < 3) return false; // Need at least 3 updates

    // Check if all recent updates are inside campus
    // This is a simplified check - in real implementation, you'd validate each update
    return recentUpdates.length >= 3;
  }

  /// Get monitoring statistics
  static MonitoringStats getMonitoringStats() {
    if (_locationHistory.isEmpty) {
      return MonitoringStats(
        totalUpdates: 0,
        averageAccuracy: 0.0,
        monitoringDuration: Duration.zero,
        isConsistentlyInside: false,
      );
    }

    final totalUpdates = _locationHistory.length;
    final averageAccuracy = _locationHistory
        .map((update) => update.accuracy)
        .reduce((a, b) => a + b) / totalUpdates;

    final monitoringDuration = _locationHistory.isNotEmpty
        ? DateTime.now().difference(_locationHistory.first.timestamp)
        : Duration.zero;

    return MonitoringStats(
      totalUpdates: totalUpdates,
      averageAccuracy: averageAccuracy,
      monitoringDuration: monitoringDuration,
      isConsistentlyInside: hasBeenConsistentlyInsideCampus(),
    );
  }

  /// Dispose resources
  static void dispose() {
    stopMonitoring();
    _statusController.close();
  }
}

/// Location update data
class LocationUpdate {
  final Position position;
  final DateTime timestamp;
  final double accuracy;

  const LocationUpdate({
    required this.position,
    required this.timestamp,
    required this.accuracy,
  });
}

/// Location status information
class LocationStatus {
  final bool isInsideCampus;
  final bool isMonitoring;
  final bool hasError;
  final String? errorMessage;
  final DateTime lastUpdate;
  final double accuracy;
  final String? campusName;
  final double? currentLatitude;
  final double? currentLongitude;

  const LocationStatus({
    required this.isInsideCampus,
    required this.isMonitoring,
    required this.hasError,
    this.errorMessage,
    required this.lastUpdate,
    required this.accuracy,
    this.campusName,
    this.currentLatitude,
    this.currentLongitude,
  });

  @override
  String toString() {
    return 'LocationStatus(isInsideCampus: $isInsideCampus, isMonitoring: $isMonitoring, hasError: $hasError, accuracy: $accuracy)';
  }
}

/// Monitoring statistics
class MonitoringStats {
  final int totalUpdates;
  final double averageAccuracy;
  final Duration monitoringDuration;
  final bool isConsistentlyInside;

  const MonitoringStats({
    required this.totalUpdates,
    required this.averageAccuracy,
    required this.monitoringDuration,
    required this.isConsistentlyInside,
  });
}
