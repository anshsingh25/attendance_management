import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/mongodb_campus_service.dart';

/// Utility class for student location validation against campus boundaries
class StudentLocationValidator {
  static final LocationService _locationService = LocationService();

  /// Check student's current location against campus boundaries
  static Future<StudentLocationResult> validateStudentLocation() async {
    try {
      // Get current location
      final position = await _locationService.getCurrentPosition();
      
      if (position == null) {
        return StudentLocationResult(
          success: false,
          error: 'Could not get your current location. Please check location permissions.',
          position: null,
          isInsideCampus: false,
        );
      }

      // Validate against campus boundaries using MongoDB ONLY
      final result = await MongoDBCampusService.validateStudentLocationMongoDB(
        position.latitude, 
        position.longitude
      );
      
      return StudentLocationResult(
        success: true,
        error: result.error,
        position: position,
        isInsideCampus: result.isInsideCampus,
        campusName: result.campusName,
        distanceToCenter: result.distanceToCenter,
        accuracy: result.accuracy,
      );
      
    } catch (e) {
      return StudentLocationResult(
        success: false,
        error: 'Error checking location: $e',
        position: null,
        isInsideCampus: false,
      );
    }
  }

  /// Show location validation dialog for students
  static Future<void> showLocationValidationDialog(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Checking your location against campus boundaries...'),
          ],
        ),
      ),
    );

    try {
      final result = await validateStudentLocation();
      
      Navigator.pop(context); // Close loading dialog

      // Show results
      _showLocationResultDialog(context, result);
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog(context, 'Error checking location: $e');
    }
  }

  static void _showLocationResultDialog(BuildContext context, StudentLocationResult result) {
    if (!result.success) {
      _showErrorDialog(context, result.error ?? 'Unknown error occurred');
      return;
    }

    final isInside = result.isInsideCampus;
    final position = result.position!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isInside ? Icons.check_circle : Icons.cancel,
              color: isInside ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isInside ? 'Inside Campus' : 'Outside Campus'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your current location
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Current Location:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Latitude: ${position.latitude.toStringAsFixed(6)}'),
                  Text('Longitude: ${position.longitude.toStringAsFixed(6)}'),
                  Text('Accuracy: ${position.accuracy.toStringAsFixed(1)} meters'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Campus status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isInside ? Colors.green : Colors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (isInside ? Colors.green : Colors.red).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus Status:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isInside ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isInside 
                        ? '✅ You are inside the campus area'
                        : '❌ You are outside the campus area',
                    style: TextStyle(
                      color: isInside ? Colors.green : Colors.red,
                    ),
                  ),
                  if (result.campusName != null) ...[
                    const SizedBox(height: 4),
                    Text('Campus: ${result.campusName}'),
                  ],
                  if (result.distanceToCenter != null) ...[
                    const SizedBox(height: 4),
                    Text('Distance to campus center: ${result.distanceToCenter!.toStringAsFixed(0)} meters'),
                  ],
                  if (result.error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.error!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Location Error'),
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
}

/// Result class for student location validation
class StudentLocationResult {
  final bool success;
  final String? error;
  final Position? position;
  final bool isInsideCampus;
  final String? campusName;
  final double? distanceToCenter;
  final double? accuracy;

  const StudentLocationResult({
    required this.success,
    this.error,
    this.position,
    required this.isInsideCampus,
    this.campusName,
    this.distanceToCenter,
    this.accuracy,
  });
}
