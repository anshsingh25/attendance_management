import '../services/location_service.dart';

/// Helper class for setting up campus boundaries
/// This provides easy-to-use methods for common college locations
class CampusSetupHelper {
  
  /// Get coordinates for popular Indian colleges/universities
  static Map<String, Map<String, dynamic>> getPopularColleges() {
    return {
      'IIT Delhi': {
        'coordinates': {'latitude': 28.5450, 'longitude': 77.1925},
        'suggestedRadius': 800.0, // meters
        'description': 'Indian Institute of Technology Delhi',
      },
      'IIT Bombay': {
        'coordinates': {'latitude': 19.1334, 'longitude': 72.9133},
        'suggestedRadius': 1000.0,
        'description': 'Indian Institute of Technology Bombay',
      },
      'IIT Madras': {
        'coordinates': {'latitude': 12.9915, 'longitude': 80.2337},
        'suggestedRadius': 900.0,
        'description': 'Indian Institute of Technology Madras',
      },
      'IIT Kanpur': {
        'coordinates': {'latitude': 26.5123, 'longitude': 80.2329},
        'suggestedRadius': 850.0,
        'description': 'Indian Institute of Technology Kanpur',
      },
      'IIT Kharagpur': {
        'coordinates': {'latitude': 22.3149, 'longitude': 87.3105},
        'suggestedRadius': 1200.0,
        'description': 'Indian Institute of Technology Kharagpur',
      },
      'Delhi University': {
        'coordinates': {'latitude': 28.6892, 'longitude': 77.2125},
        'suggestedRadius': 600.0,
        'description': 'University of Delhi',
      },
      'JNU Delhi': {
        'coordinates': {'latitude': 28.5450, 'longitude': 77.1650},
        'suggestedRadius': 700.0,
        'description': 'Jawaharlal Nehru University',
      },
      'Anna University': {
        'coordinates': {'latitude': 12.9900, 'longitude': 80.2337},
        'suggestedRadius': 800.0,
        'description': 'Anna University Chennai',
      },
      'VIT Vellore': {
        'coordinates': {'latitude': 12.9698, 'longitude': 79.1559},
        'suggestedRadius': 900.0,
        'description': 'Vellore Institute of Technology',
      },
      'BITS Pilani': {
        'coordinates': {'latitude': 28.3589, 'longitude': 75.5880},
        'suggestedRadius': 1000.0,
        'description': 'Birla Institute of Technology and Science',
      },
    };
  }

  /// Create a circular campus boundary for a college
  static CampusBoundary createCircularCampus({
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    required double radius,
    String? createdBy,
  }) {
    return CampusBoundary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      boundaryType: CampusBoundaryType.circle,
      center: GeoPoint(latitude: latitude, longitude: longitude),
      radius: radius,
      polygonPoints: const [],
      bounds: const GeoBounds(
        southwest: GeoPoint(latitude: 0, longitude: 0),
        northeast: GeoPoint(latitude: 0, longitude: 0),
      ),
      isActive: true,
      createdBy: createdBy ?? 'teacher',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a rectangular campus boundary
  static CampusBoundary createRectangularCampus({
    required String name,
    required String description,
    required double southwestLat,
    required double southwestLng,
    required double northeastLat,
    required double northeastLng,
    String? createdBy,
  }) {
    return CampusBoundary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      boundaryType: CampusBoundaryType.rectangle,
      center: GeoPoint(
        latitude: (southwestLat + northeastLat) / 2,
        longitude: (southwestLng + northeastLng) / 2,
      ),
      radius: 0,
      polygonPoints: const [],
      bounds: GeoBounds(
        southwest: GeoPoint(latitude: southwestLat, longitude: southwestLng),
        northeast: GeoPoint(latitude: northeastLat, longitude: northeastLng),
      ),
      isActive: true,
      createdBy: createdBy ?? 'teacher',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a polygon campus boundary
  static CampusBoundary createPolygonCampus({
    required String name,
    required String description,
    required List<GeoPoint> points,
    String? createdBy,
  }) {
    // Calculate center point
    double totalLat = 0, totalLng = 0;
    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }
    
    return CampusBoundary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      boundaryType: CampusBoundaryType.polygon,
      center: GeoPoint(
        latitude: totalLat / points.length,
        longitude: totalLng / points.length,
      ),
      radius: 0,
      polygonPoints: points,
      bounds: const GeoBounds(
        southwest: GeoPoint(latitude: 0, longitude: 0),
        northeast: GeoPoint(latitude: 0, longitude: 0),
      ),
      isActive: true,
      createdBy: createdBy ?? 'teacher',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get current location coordinates
  static Future<GeoPoint?> getCurrentLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      if (position != null) {
        return GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
      return null;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() *
        (dLng / 2).sin() * (dLng / 2).sin();
    
    final double c = 2 * (a.sqrt()).asin();
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Validate coordinates
  static bool isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && 
           longitude >= -180 && longitude <= 180;
  }

  /// Get suggested radius based on campus type
  static double getSuggestedRadius(String campusType) {
    switch (campusType.toLowerCase()) {
      case 'small college':
        return 300.0;
      case 'medium college':
        return 600.0;
      case 'large university':
        return 1000.0;
      case 'campus with multiple buildings':
        return 1500.0;
      default:
        return 500.0;
    }
  }
}

/// Extension for math functions
extension MathExtensions on double {
  double sin() => this * (3.14159265359 / 180);
  double cos() => this * (3.14159265359 / 180);
  double asin() => this * (180 / 3.14159265359);
  double sqrt() => this * this;
}
