import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      final status = await Geolocator.checkPermission();
      print('Current location permission status: $status');
      return status == LocationPermission.always || status == LocationPermission.whileInUse;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Geolocator.requestPermission();
      print('Location permission status: $status');
      return status == LocationPermission.always || status == LocationPermission.whileInUse;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      print('Getting current position...');
      
      // Check if location services are enabled
      final isEnabled = await isLocationServiceEnabled();
      print('Location services enabled: $isEnabled');
      
      if (!isEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permissions
      final hasPermission = await hasLocationPermission();
      print('Has location permission: $hasPermission');
      
      if (!hasPermission) {
        print('Requesting location permission...');
        final granted = await requestLocationPermission();
        print('Permission granted: $granted');
        
        if (!granted) {
          throw Exception('Location permission not granted');
        }
      }

      // Get current position with high accuracy
      print('Requesting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print('Position obtained: ${position.latitude}, ${position.longitude}');
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

  // ==================== GEOFENCING FUNCTIONALITY ====================

  // Check if point is inside a polygon (campus boundary)
  bool isPointInPolygon(double latitude, double longitude, List<GeoPoint> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > latitude) != (polygon[j].latitude > latitude)) &&
          (longitude < (polygon[j].longitude - polygon[i].longitude) * 
           (latitude - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + 
           polygon[i].longitude)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  // Check if point is inside a circular boundary
  bool isPointInCircle(double latitude, double longitude, GeoPoint center, double radiusMeters) {
    final distance = calculateDistance(latitude, longitude, center.latitude, center.longitude);
    return distance <= radiusMeters;
  }

  // Validate if user is within campus boundaries
  Future<CampusGeofenceResult> validateCampusGeofence(CampusBoundary campus) async {
    try {
      // Check if location services are enabled
      if (!await isLocationServiceEnabled()) {
        return CampusGeofenceResult(
          isInsideCampus: false,
          error: 'Location services are disabled. Please enable location services to mark attendance.',
          campusName: campus.name,
        );
      }

      // Check permissions
      if (!await hasLocationPermission()) {
        return CampusGeofenceResult(
          isInsideCampus: false,
          error: 'Location permission not granted. Please allow location access to mark attendance.',
          campusName: campus.name,
        );
      }

      // Get current position
      final position = await getCurrentPosition();
      if (position == null) {
        return CampusGeofenceResult(
          isInsideCampus: false,
          error: 'Unable to get current location. Please try again.',
          campusName: campus.name,
        );
      }

      bool isInside = false;
      String boundaryType = '';

      // Check based on boundary type
      switch (campus.boundaryType) {
        case CampusBoundaryType.circle:
          isInside = isPointInCircle(
            position.latitude,
            position.longitude,
            campus.center,
            campus.radius,
          );
          boundaryType = 'circular';
          break;

        case CampusBoundaryType.polygon:
          isInside = isPointInPolygon(
            position.latitude,
            position.longitude,
            campus.polygonPoints,
          );
          boundaryType = 'polygon';
          break;

        case CampusBoundaryType.rectangle:
          isInside = isPointInRectangle(
            position.latitude,
            position.longitude,
            campus.bounds,
          );
          boundaryType = 'rectangular';
          break;
      }

      if (isInside) {
        return CampusGeofenceResult(
          isInsideCampus: true,
          currentLatitude: position.latitude,
          currentLongitude: position.longitude,
          campusName: campus.name,
          boundaryType: boundaryType,
          accuracy: position.accuracy,
        );
      } else {
        // Calculate distance to campus center for user feedback
        final distanceToCenter = calculateDistance(
          position.latitude,
          position.longitude,
          campus.center.latitude,
          campus.center.longitude,
        );

        return CampusGeofenceResult(
          isInsideCampus: false,
          currentLatitude: position.latitude,
          currentLongitude: position.longitude,
          campusName: campus.name,
          boundaryType: boundaryType,
          distanceToCenter: distanceToCenter,
          error: 'You are outside the ${campus.name} campus area. Please move to the campus to mark attendance.',
        );
      }
    } catch (e) {
      return CampusGeofenceResult(
        isInsideCampus: false,
        error: 'Geofence validation failed: $e',
        campusName: campus.name,
      );
    }
  }

  // Check if point is inside a rectangle
  bool isPointInRectangle(double latitude, double longitude, GeoBounds bounds) {
    return latitude >= bounds.southwest.latitude &&
           latitude <= bounds.northeast.latitude &&
           longitude >= bounds.southwest.longitude &&
           longitude <= bounds.northeast.longitude;
  }

  // Get distance to nearest campus boundary
  Future<double?> getDistanceToNearestBoundary(CampusBoundary campus) async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      switch (campus.boundaryType) {
        case CampusBoundaryType.circle:
          final distanceToCenter = calculateDistance(
            position.latitude,
            position.longitude,
            campus.center.latitude,
            campus.center.longitude,
          );
          return (distanceToCenter - campus.radius).abs();

        case CampusBoundaryType.polygon:
          // Calculate distance to nearest polygon edge
          return _calculateDistanceToPolygonEdge(
            position.latitude,
            position.longitude,
            campus.polygonPoints,
          );

        case CampusBoundaryType.rectangle:
          return _calculateDistanceToRectangleEdge(
            position.latitude,
            position.longitude,
            campus.bounds,
          );
      }
    } catch (e) {
      print('Error calculating distance to boundary: $e');
      return null;
    }
  }

  // Calculate distance to nearest polygon edge
  double _calculateDistanceToPolygonEdge(double lat, double lng, List<GeoPoint> polygon) {
    double minDistance = double.infinity;

    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      final distance = _distanceToLineSegment(
        lat, lng,
        polygon[i].latitude, polygon[i].longitude,
        polygon[j].latitude, polygon[j].longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  // Calculate distance to nearest rectangle edge
  double _calculateDistanceToRectangleEdge(double lat, double lng, GeoBounds bounds) {
    final distances = [
      (lat - bounds.southwest.latitude).abs(),
      (lat - bounds.northeast.latitude).abs(),
      (lng - bounds.southwest.longitude).abs(),
      (lng - bounds.northeast.longitude).abs(),
    ];
    return distances.reduce(math.min);
  }

  // Calculate distance from point to line segment
  double _distanceToLineSegment(double px, double py, double x1, double y1, double x2, double y2) {
    final A = px - x1;
    final B = py - y1;
    final C = x2 - x1;
    final D = y2 - y1;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) return math.sqrt(A * A + B * B);

    var param = dot / lenSq;

    double xx, yy;

    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }

    final dx = px - xx;
    final dy = py - yy;
    return math.sqrt(dx * dx + dy * dy);
  }

  // Monitor geofence status changes
  Stream<CampusGeofenceStatus> monitorCampusGeofence(CampusBoundary campus) async* {
    await for (final position in getLocationStream()) {
      final result = await validateCampusGeofence(campus);
      yield CampusGeofenceStatus(
        isInside: result.isInsideCampus,
        position: position,
        campusName: campus.name,
        timestamp: DateTime.now(),
      );
    }
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

// ==================== GEOFENCING DATA MODELS ====================

enum CampusBoundaryType {
  circle,
  polygon,
  rectangle,
}

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    try {
      return GeoPoint(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      print('Error parsing GeoPoint from JSON: $e');
      print('JSON data: $json');
      return const GeoPoint(latitude: 0.0, longitude: 0.0);
    }
  }
}

class GeoBounds {
  final GeoPoint southwest;
  final GeoPoint northeast;

  const GeoBounds({
    required this.southwest,
    required this.northeast,
  });

  Map<String, dynamic> toJson() => {
    'southwest': southwest.toJson(),
    'northeast': northeast.toJson(),
  };

  factory GeoBounds.fromJson(Map<String, dynamic> json) {
    try {
      return GeoBounds(
        southwest: GeoPoint.fromJson(json['southwest'] as Map<String, dynamic>? ?? {}),
        northeast: GeoPoint.fromJson(json['northeast'] as Map<String, dynamic>? ?? {}),
      );
    } catch (e) {
      print('Error parsing GeoBounds from JSON: $e');
      print('JSON data: $json');
      return const GeoBounds(
        southwest: GeoPoint(latitude: 0.0, longitude: 0.0),
        northeast: GeoPoint(latitude: 0.0, longitude: 0.0),
      );
    }
  }
}

class CampusBoundary {
  final String id;
  final String name;
  final String description;
  final CampusBoundaryType boundaryType;
  final GeoPoint center;
  final double radius; // For circular boundaries (in meters)
  final List<GeoPoint> polygonPoints; // For polygon boundaries
  final GeoBounds bounds; // For rectangular boundaries
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CampusBoundary({
    required this.id,
    required this.name,
    required this.description,
    required this.boundaryType,
    required this.center,
    required this.radius,
    required this.polygonPoints,
    required this.bounds,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'boundaryType': boundaryType.name,
    'center': center.toJson(),
    'radius': radius,
    'polygonPoints': polygonPoints.map((p) => p.toJson()).toList(),
    'bounds': bounds.toJson(),
    'isActive': isActive,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CampusBoundary.fromJson(Map<String, dynamic> json) => CampusBoundary(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    boundaryType: CampusBoundaryType.values.firstWhere(
      (e) => e.name == json['boundaryType'],
      orElse: () => CampusBoundaryType.circle,
    ),
    center: GeoPoint.fromJson(json['center']),
    radius: json['radius']?.toDouble() ?? 0.0,
    polygonPoints: (json['polygonPoints'] as List<dynamic>?)
        ?.map((p) => GeoPoint.fromJson(p))
        .toList() ?? [],
    bounds: GeoBounds.fromJson(json['bounds']),
    isActive: json['isActive'] ?? true,
    createdBy: json['createdBy'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  CampusBoundary copyWith({
    String? id,
    String? name,
    String? description,
    CampusBoundaryType? boundaryType,
    GeoPoint? center,
    double? radius,
    List<GeoPoint>? polygonPoints,
    GeoBounds? bounds,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampusBoundary(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      boundaryType: boundaryType ?? this.boundaryType,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      polygonPoints: polygonPoints ?? this.polygonPoints,
      bounds: bounds ?? this.bounds,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CampusGeofenceResult {
  final bool isInsideCampus;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? campusName;
  final String? boundaryType;
  final double? distanceToCenter;
  final double? accuracy;
  final String? error;

  const CampusGeofenceResult({
    required this.isInsideCampus,
    this.currentLatitude,
    this.currentLongitude,
    this.campusName,
    this.boundaryType,
    this.distanceToCenter,
    this.accuracy,
    this.error,
  });
}

class CampusGeofenceStatus {
  final bool isInside;
  final Position position;
  final String campusName;
  final DateTime timestamp;

  const CampusGeofenceStatus({
    required this.isInside,
    required this.position,
    required this.campusName,
    required this.timestamp,
  });
}
