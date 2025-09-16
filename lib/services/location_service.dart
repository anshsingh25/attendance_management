import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      if (!await isLocationServiceEnabled()) {
        throw Exception('Location services are disabled');
      }

      // Check permissions
      if (!await hasLocationPermission()) {
        final granted = await requestLocationPermission();
        if (!granted) {
          throw Exception('Location permission not granted');
        }
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Calculate distance between two points in meters
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Check if current location is within specified radius
  Future<bool> isWithinRadius(
    double targetLatitude,
    double targetLongitude,
    double radiusInMeters,
  ) async {
    try {
      final position = await getCurrentPosition();
      if (position == null) {
        return false;
      }

      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        targetLatitude,
        targetLongitude,
      );

      return distance <= radiusInMeters;
    } catch (e) {
      print('Error checking location radius: $e');
      return false;
    }
  }

  // Validate location for attendance
  Future<LocationValidationResult> validateLocationForAttendance(
    double classroomLatitude,
    double classroomLongitude,
    double allowedRadius,
  ) async {
    try {
      // Check if location services are enabled
      if (!await isLocationServiceEnabled()) {
        return LocationValidationResult(
          isValid: false,
          error: 'Location services are disabled. Please enable location services.',
        );
      }

      // Check permissions
      if (!await hasLocationPermission()) {
        return LocationValidationResult(
          isValid: false,
          error: 'Location permission not granted. Please allow location access.',
        );
      }

      // Get current position
      final position = await getCurrentPosition();
      if (position == null) {
        return LocationValidationResult(
          isValid: false,
          error: 'Unable to get current location. Please try again.',
        );
      }

      // Calculate distance
      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        classroomLatitude,
        classroomLongitude,
      );

      // Check if within allowed radius
      final isWithinRadius = distance <= allowedRadius;

      return LocationValidationResult(
        isValid: isWithinRadius,
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        distance: distance,
        error: isWithinRadius ? null : 'You are ${distance.toStringAsFixed(0)} meters away from the classroom. Please move closer.',
      );
    } catch (e) {
      return LocationValidationResult(
        isValid: false,
        error: 'Location validation failed: $e',
      );
    }
  }

  // Get location info for logging
  Future<Map<String, dynamic>> getLocationInfo() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) {
        return {
          'latitude': null,
          'longitude': null,
          'accuracy': null,
          'altitude': null,
          'speed': null,
          'heading': null,
          'timestamp': DateTime.now().toIso8601String(),
          'error': 'Unable to get location',
        };
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': position.timestamp.toIso8601String(),
      };
    } catch (e) {
      return {
        'latitude': null,
        'longitude': null,
        'accuracy': null,
        'altitude': null,
        'speed': null,
        'heading': null,
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // Start location stream for real-time tracking
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}

class LocationValidationResult {
  final bool isValid;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? distance;
  final String? error;

  const LocationValidationResult({
    required this.isValid,
    this.currentLatitude,
    this.currentLongitude,
    this.distance,
    this.error,
  });
}
