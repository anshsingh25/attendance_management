import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../utils/campus_setup_helper.dart';

/// Helper class to handle location permission requests with better user experience
class LocationPermissionHelper {
  
  /// Request location permission with detailed user guidance
  static Future<GeoPoint?> requestLocationWithGuidance(BuildContext context) async {
    // Step 1: Show explanation dialog
    final shouldProceed = await _showExplanationDialog(context);
    if (!shouldProceed) return null;

    // Step 2: Show loading dialog
    _showLoadingDialog(context);

    try {
      final locationService = LocationService();
      
      // Step 3: Check and request permission
      final hasPermission = await locationService.hasLocationPermission();
      if (!hasPermission) {
        print('Requesting location permission...');
        final granted = await locationService.requestLocationPermission();
        if (!granted) {
          Navigator.pop(context); // Close loading dialog
          await _showPermissionDeniedDialog(context);
          return null;
        }
      }

      // Step 4: Check if location services are enabled
      final isEnabled = await locationService.isLocationServiceEnabled();
      if (!isEnabled) {
        Navigator.pop(context); // Close loading dialog
        await _showLocationServicesDisabledDialog(context);
        return null;
      }

      // Step 5: Get current location
      final currentLocation = await CampusSetupHelper.getCurrentLocation();
      Navigator.pop(context); // Close loading dialog
      
      if (currentLocation != null) {
        _showSuccessMessage(context, currentLocation);
        return currentLocation;
      } else {
        _showLocationError(context);
        return null;
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showError(context, e.toString());
      return null;
    }
  }

  static Future<bool> _showExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.my_location, color: Colors.blue),
            SizedBox(width: 8),
            Text('Get Current Location'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will:'),
            SizedBox(height: 8),
            Text('1. Request location permission from macOS'),
            Text('2. Get your current GPS coordinates'),
            Text('3. Create a campus boundary at your location'),
            SizedBox(height: 12),
            Text(
              'Note: macOS will show a permission dialog. Click "Allow" to continue.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Requesting location permission...'),
          ],
        ),
      ),
    );
  }

  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Location Permission Denied'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location access was denied. To use this feature:'),
            SizedBox(height: 12),
            Text('1. Go to System Settings > Privacy & Security > Location Services'),
            Text('2. Find "attendence_app" in the list'),
            Text('3. Enable location access'),
            Text('4. Try again'),
            SizedBox(height: 12),
            Text(
              'Alternatively, you can use "Popular Colleges" to create campus boundaries with pre-configured locations.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showLocationServicesDisabledDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Location Services Disabled'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location services are disabled on your Mac. To enable:'),
            SizedBox(height: 12),
            Text('1. Go to System Settings > Privacy & Security > Location Services'),
            Text('2. Turn ON "Location Services"'),
            Text('3. Try again'),
            SizedBox(height: 12),
            Text(
              'Alternatively, you can use "Popular Colleges" to create campus boundaries with pre-configured locations.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showSuccessMessage(BuildContext context, GeoPoint location) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location obtained: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _showLocationError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not get current location. Please check location permissions.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error getting location: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
