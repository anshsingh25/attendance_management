import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/campus_boundary.dart';
import '../services/location_service.dart';

/// MongoDB-only campus service for real-time geofencing
class MongoDBCampusService {
  static const String _baseUrl = 'http://localhost:5000/api'; // Your backend URL
  static Timer? _syncTimer;
  static StreamController<List<CampusBoundaryModel>> _campusStreamController = 
      StreamController<List<CampusBoundaryModel>>.broadcast();

  /// Start real-time campus synchronization from MongoDB
  static Future<void> startMongoDBSync() async {
    try {
      // Initial sync
      await _syncCampusBoundariesFromMongoDB();
      
      // Start periodic sync every 30 seconds
      _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _syncCampusBoundariesFromMongoDB();
      });
      
      print('MongoDB campus sync started');
    } catch (e) {
      print('Error starting MongoDB sync: $e');
    }
  }

  /// Stop real-time synchronization
  static void stopMongoDBSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('MongoDB campus sync stopped');
  }

  /// Sync campus boundaries from MongoDB
  static Future<void> _syncCampusBoundariesFromMongoDB() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/campus/boundaries/realtime'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        final List<CampusBoundaryModel> boundaries = data
            .map((json) => CampusBoundaryModel.fromJson(json))
            .toList();

        // Emit to stream
        _campusStreamController.add(boundaries);
        
        print('MongoDB campus boundaries synced: ${boundaries.length} boundaries');
      } else {
        print('Failed to sync campus boundaries from MongoDB: ${response.statusCode}');
      }
    } catch (e) {
      print('Error syncing campus boundaries from MongoDB: $e');
    }
  }

  /// Get real-time campus boundaries stream
  static Stream<List<CampusBoundaryModel>> get campusBoundariesStream => 
      _campusStreamController.stream;

  /// Create new campus boundary in MongoDB (Demo endpoint)
  static Future<String?> createCampusBoundary(CampusBoundaryModel campus) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/campus/boundaries/demo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(campus.toJson()),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Full response data: $responseData');
        final campusId = responseData['data']['_id'] ?? responseData['data']['id'];
        print('Campus boundary created in MongoDB: $campusId');
        return campusId;
      } else {
        print('Failed to create campus boundary: ${response.statusCode}');
        print('Response body: ${response.body}');
        print('Request body sent: ${json.encode(campus.toJson())}');
        
        // Handle specific error cases
        if (response.statusCode == 400) {
          try {
            final errorData = json.decode(response.body);
            if (errorData['message'] != null) {
              throw Exception(errorData['message']);
            }
          } catch (e) {
            // If parsing fails, throw generic error
            throw Exception('Failed to create campus boundary: ${response.statusCode}');
          }
        }
        
        return null;
      }
    } catch (e) {
      print('Error creating campus boundary: $e');
      return null;
    }
  }

  /// Get current campus boundaries from MongoDB (for real-time sync - only active)
  static Future<List<CampusBoundaryModel>> getCurrentCampusBoundaries() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/campus/boundaries/realtime'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => CampusBoundaryModel.fromJson(json)).toList();
      } else {
        print('Failed to get campus boundaries: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting campus boundaries: $e');
      return [];
    }
  }

  /// Get all campus boundaries from MongoDB (for teacher portal - all campuses)
  static Future<List<CampusBoundaryModel>> getAllCampusBoundaries() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/campus/boundaries/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => CampusBoundaryModel.fromJson(json)).toList();
      } else {
        print('Failed to get all campus boundaries: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting all campus boundaries: $e');
      return [];
    }
  }

  /// Update campus boundary in MongoDB (Demo endpoint)
  static Future<bool> updateCampusBoundary(CampusBoundaryModel campus) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/campus/boundaries/demo/${campus.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(campus.toJson()),
      );

      if (response.statusCode == 200) {
        print('Campus boundary updated in MongoDB: ${campus.id}');
        return true;
      } else {
        print('Failed to update campus boundary: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating campus boundary: $e');
      return false;
    }
  }

  /// Delete campus boundary from MongoDB (Demo endpoint)
  static Future<bool> deleteCampusBoundary(String campusId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/campus/boundaries/demo/$campusId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Campus boundary deleted from MongoDB: $campusId');
        return true;
      } else {
        print('Failed to delete campus boundary: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting campus boundary: $e');
      return false;
    }
  }

  /// Validate student location against MongoDB campus boundaries
  static Future<CampusGeofenceResult> validateStudentLocationMongoDB(
    double latitude, 
    double longitude
  ) async {
    try {
      final boundaries = await getCurrentCampusBoundaries();
      final activeBoundaries = boundaries.where((b) => b.isActive).toList();
      
      if (activeBoundaries.isEmpty) {
        return const CampusGeofenceResult(
          isInsideCampus: true,
          error: 'No active campus boundaries found in MongoDB. Attendance can be marked anywhere.',
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
        error: 'MongoDB campus validation failed: $e',
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

  /// Dispose resources
  static void dispose() {
    stopMongoDBSync();
    _campusStreamController.close();
  }
}
