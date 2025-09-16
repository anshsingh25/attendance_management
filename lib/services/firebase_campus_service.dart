import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/campus_boundary.dart';
import '../services/location_service.dart';

/// Firebase service for managing campus boundaries
class FirebaseCampusService {
  static final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _campusCollection = 'campus_boundaries';

  /// Get current user ID
  static String? get _currentUserId => _auth.currentUser?.uid;

  /// Create a new campus boundary
  static Future<String?> createCampusBoundary(CampusBoundaryModel campus) async {
    try {
      final docRef = await _firestore.collection(_campusCollection).add({
        ...campus.toJson(),
        'createdBy': _currentUserId,
        'createdAt': firestore.FieldValue.serverTimestamp(),
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      print('Error creating campus boundary: $e');
      return null;
    }
  }

  /// Get all campus boundaries
  static Future<List<CampusBoundaryModel>> getCampusBoundaries() async {
    try {
      final querySnapshot = await _firestore
          .collection(_campusCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CampusBoundaryModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting campus boundaries: $e');
      return [];
    }
  }

  /// Get campus boundaries by teacher
  static Future<List<CampusBoundaryModel>> getCampusBoundariesByTeacher(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_campusCollection)
          .where('createdBy', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CampusBoundaryModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting campus boundaries by teacher: $e');
      return [];
    }
  }

  /// Update a campus boundary
  static Future<bool> updateCampusBoundary(String id, CampusBoundaryModel campus) async {
    try {
      await _firestore.collection(_campusCollection).doc(id).update({
        ...campus.toJson(),
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating campus boundary: $e');
      return false;
    }
  }

  /// Delete a campus boundary
  static Future<bool> deleteCampusBoundary(String id) async {
    try {
      await _firestore.collection(_campusCollection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting campus boundary: $e');
      return false;
    }
  }

  /// Get active campus boundaries for attendance validation
  static Future<List<CampusBoundaryModel>> getActiveCampusBoundaries() async {
    try {
      final querySnapshot = await _firestore
          .collection(_campusCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CampusBoundaryModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting active campus boundaries: $e');
      return [];
    }
  }

  /// Listen to campus boundary changes in real-time
  static Stream<List<CampusBoundaryModel>> listenToCampusBoundaries() {
    return _firestore
        .collection(_campusCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CampusBoundaryModel.fromJson(data);
      }).toList();
    });
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
        (dLat / 2).sin() * (dLat / 2).sin() +
        _degreesToRadians(lat1).cos() * _degreesToRadians(lat2).cos() *
        (dLng / 2).sin() * (dLng / 2).sin();
    
    final double c = 2 * (a.sqrt()).asin();
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}

/// Extension for math functions
extension MathExtensions on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double asin() => math.asin(this);
  double sqrt() => math.sqrt(this);
}
