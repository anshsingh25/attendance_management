import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/campus_boundary.dart';
import '../services/location_service.dart';

/// Real-time campus synchronization service
class RealtimeCampusSync {
  static const String _baseUrl = 'http://localhost:5000/api'; // Your backend URL
  static const String _campusKey = 'realtime_campus_boundaries';
  static Timer? _syncTimer;
  static StreamController<List<CampusBoundaryModel>> _campusStreamController = 
      StreamController<List<CampusBoundaryModel>>.broadcast();

  /// Start real-time campus synchronization
  static Future<void> startRealtimeSync() async {
    try {
      // Initial sync
      await _syncCampusBoundaries();
      
      // Start periodic sync every 30 seconds
      _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _syncCampusBoundaries();
      });
      
      print('Real-time campus sync started');
    } catch (e) {
      print('Error starting real-time sync: $e');
    }
  }

  /// Stop real-time synchronization
  static void stopRealtimeSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('Real-time campus sync stopped');
  }

  /// Sync campus boundaries from server
  static Future<void> _syncCampusBoundaries() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/campus/boundaries'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<CampusBoundaryModel> boundaries = data
            .map((json) => CampusBoundaryModel.fromJson(json))
            .toList();

        // Save to local storage
        await _saveCampusBoundaries(boundaries);
        
        // Emit to stream
        _campusStreamController.add(boundaries);
        
        print('Campus boundaries synced: ${boundaries.length} boundaries');
      } else {
        print('Failed to sync campus boundaries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error syncing campus boundaries: $e');
    }
  }

  /// Get real-time campus boundaries stream
  static Stream<List<CampusBoundaryModel>> get campusBoundariesStream => 
      _campusStreamController.stream;

  /// Get current campus boundaries
  static Future<List<CampusBoundaryModel>> getCurrentCampusBoundaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boundariesJson = prefs.getString(_campusKey);
      
      if (boundariesJson == null) {
        return [];
      }
      
      final List<dynamic> boundariesList = json.decode(boundariesJson);
      return boundariesList.map((json) => CampusBoundaryModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting current campus boundaries: $e');
      return [];
    }
  }

  /// Save campus boundaries to local storage
  static Future<void> _saveCampusBoundaries(List<CampusBoundaryModel> boundaries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boundariesJson = json.encode(boundaries.map((b) => b.toJson()).toList());
      await prefs.setString(_campusKey, boundariesJson);
    } catch (e) {
      print('Error saving campus boundaries: $e');
    }
  }

  /// Validate student location against real-time campus boundaries
  static Future<CampusGeofenceResult> validateStudentLocationRealtime(
    double latitude, 
    double longitude
  ) async {
    try {
      final boundaries = await getCurrentCampusBoundaries();
      final activeBoundaries = boundaries.where((b) => b.isActive).toList();
      
      if (activeBoundaries.isEmpty) {
        return const CampusGeofenceResult(
          isInsideCampus: true,
          error: 'No active campus boundaries found. Attendance can be marked anywhere.',
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
            accuracy: 0.0,
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
        error: 'Real-time campus validation failed: $e',
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
    return degrees * (3.14159265359 / 180);
  }

  /// Dispose resources
  static void dispose() {
    stopRealtimeSync();
    _campusStreamController.close();
  }
}
