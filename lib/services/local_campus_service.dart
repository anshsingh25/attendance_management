import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/campus_boundary.dart';
import '../services/location_service.dart';

/// Local campus service for demo purposes (when Firebase is not available)
class LocalCampusService {
  static const String _campusKey = 'local_campus_boundaries';

  /// Create a new campus boundary
  static Future<String?> createCampusBoundary(CampusBoundaryModel campus) async {
    try {
      await SharedPreferences.getInstance();
      final existingBoundaries = await getCampusBoundaries();
      
      // Add new boundary with generated ID
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final newCampus = CampusBoundaryModel(
        id: newId,
        name: campus.name,
        description: campus.description,
        boundaryType: campus.boundaryType,
        center: campus.center,
        radius: campus.radius,
        polygonPoints: campus.polygonPoints,
        bounds: campus.bounds,
        isActive: campus.isActive,
        createdBy: 'local_user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      existingBoundaries.add(newCampus);
      await _saveCampusBoundaries(existingBoundaries);
      
      return newId;
    } catch (e) {
      print('Error creating campus boundary: $e');
      return null;
    }
  }

  /// Get all campus boundaries
  static Future<List<CampusBoundaryModel>> getCampusBoundaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boundariesJson = prefs.getString(_campusKey);
      
      if (boundariesJson == null) {
        return [];
      }
      
      final List<dynamic> boundariesList = json.decode(boundariesJson);
      return boundariesList.map((json) => CampusBoundaryModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting campus boundaries: $e');
      return [];
    }
  }

  /// Get active campus boundaries for attendance validation
  static Future<List<CampusBoundaryModel>> getActiveCampusBoundaries() async {
    try {
      final allBoundaries = await getCampusBoundaries();
      return allBoundaries.where((boundary) => boundary.isActive).toList();
    } catch (e) {
      print('Error getting active campus boundaries: $e');
      return [];
    }
  }

  /// Validate user location against all active campus boundaries
  static Future<CampusGeofenceResult> validateUserLocation(
    double latitude, 
    double longitude
  ) async {
    try {
      final activeBoundaries = await getActiveCampusBoundaries();
      
      if (activeBoundaries.isEmpty) {
        return const CampusGeofenceResult(
          isInsideCampus: true,
          error: 'No campus boundaries defined. Attendance can be marked anywhere.',
        );
      }

      // Check against each boundary
      for (final boundary in activeBoundaries) {
        final isInside = _isPointInsideBoundary(latitude, longitude, boundary);
        if (isInside) {
          return CampusGeofenceResult(
            isInsideCampus: true,
            currentLatitude: latitude,
            currentLongitude: longitude,
            campusName: boundary.name,
            boundaryType: boundary.boundaryType,
            accuracy: 0.0, // Will be set by caller
          );
        }
      }

      // Not inside any boundary
      return CampusGeofenceResult(
        isInsideCampus: false,
        currentLatitude: latitude,
        currentLongitude: longitude,
        campusName: activeBoundaries.first.name,
        error: 'You are outside the ${activeBoundaries.first.name} campus area. Please move to the campus to mark attendance.',
      );
    } catch (e) {
      return CampusGeofenceResult(
        isInsideCampus: false,
        error: 'Campus validation failed: $e',
      );
    }
  }

  /// Check if a point is inside a campus boundary
  static bool _isPointInsideBoundary(double lat, double lng, CampusBoundaryModel boundary) {
    switch (boundary.boundaryType) {
      case 'circle':
        return _isPointInCircle(lat, lng, boundary.center, boundary.radius);
      case 'polygon':
        return _isPointInPolygon(lat, lng, boundary.polygonPoints);
      case 'rectangle':
        return _isPointInRectangle(lat, lng, boundary.bounds);
      default:
        return false;
    }
  }

  /// Check if point is inside a circle
  static bool _isPointInCircle(double lat, double lng, GeoPoint center, double radius) {
    final distance = _calculateDistance(lat, lng, center.latitude, center.longitude);
    return distance <= radius;
  }

  /// Check if point is inside a polygon
  static bool _isPointInPolygon(double lat, double lng, List<GeoPoint> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > lat) != (polygon[j].latitude > lat)) &&
          (lng < (polygon[j].longitude - polygon[i].longitude) * 
           (lat - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + 
           polygon[i].longitude)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  /// Check if point is inside a rectangle
  static bool _isPointInRectangle(double lat, double lng, GeoBounds bounds) {
    return lat >= bounds.southwest.latitude &&
           lat <= bounds.northeast.latitude &&
           lng >= bounds.southwest.longitude &&
           lng <= bounds.northeast.longitude;
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Save campus boundaries to local storage
  static Future<void> _saveCampusBoundaries(List<CampusBoundaryModel> boundaries) async {
    final prefs = await SharedPreferences.getInstance();
    final boundariesJson = json.encode(boundaries.map((b) => b.toJson()).toList());
    await prefs.setString(_campusKey, boundariesJson);
  }

  /// Create a demo campus boundary for testing
  static Future<String?> createDemoCampus() async {
    final demoCampus = CampusBoundaryModel(
      id: 'demo_campus',
      name: 'Demo University Campus',
      description: 'Demo campus for testing geofencing',
      boundaryType: 'circle',
      center: const GeoPoint(latitude: 12.9716, longitude: 77.5946), // Bangalore
      radius: 500.0, // 500 meters
      polygonPoints: const [],
      bounds: const GeoBounds(
        southwest: GeoPoint(latitude: 12.9671, longitude: 77.5901),
        northeast: GeoPoint(latitude: 12.9761, longitude: 77.5991),
      ),
      isActive: true,
      createdBy: 'demo_user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await createCampusBoundary(demoCampus);
  }
}
