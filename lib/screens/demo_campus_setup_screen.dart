import 'package:flutter/material.dart';
import '../services/mongodb_campus_service.dart';
import '../models/campus_boundary.dart';
import '../services/location_service.dart';
import '../utils/campus_setup_helper.dart';

/// Demo campus setup screen for teachers
class DemoCampusSetupScreen extends StatefulWidget {
  const DemoCampusSetupScreen({super.key});

  @override
  State<DemoCampusSetupScreen> createState() => _DemoCampusSetupScreenState();
}

class _DemoCampusSetupScreenState extends State<DemoCampusSetupScreen> {
  bool _isLoading = false;
  List<CampusBoundaryModel> _campusBoundaries = [];

  @override
  void initState() {
    super.initState();
    _loadCampusBoundaries();
  }

  /// Load existing campus boundaries from MongoDB
  Future<void> _loadCampusBoundaries() async {
    setState(() => _isLoading = true);
    try {
      final boundaries = await MongoDBCampusService.getAllCampusBoundaries();
      print('Loaded ${boundaries.length} campus boundaries from MongoDB');
      for (final boundary in boundaries) {
        print('Campus: ${boundary.name}, Active: ${boundary.isActive}');
      }
      setState(() {
        _campusBoundaries = boundaries;
      });
    } catch (e) {
      _showErrorDialog('Error loading campus boundaries from MongoDB: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Create demo campus in MongoDB
  Future<void> _createDemoCampus() async {
    setState(() => _isLoading = true);
    try {
      final demoCampus = CampusBoundaryModel(
        id: 'demo_campus_${DateTime.now().millisecondsSinceEpoch}',
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
        createdBy: 'demo_teacher',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final campusId = await MongoDBCampusService.createCampusBoundary(demoCampus);
      if (campusId != null) {
        _showSuccessDialog('Demo campus created successfully in MongoDB!');
        await _loadCampusBoundaries();
      } else {
        _showErrorDialog('Failed to create demo campus in MongoDB');
      }
    } catch (e) {
      _showErrorDialog('Error creating demo campus: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Use current location to create campus
  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      // Get current location
      final currentLocation = await CampusSetupHelper.getCurrentLocation();
      if (currentLocation == null) {
        _showErrorDialog('Unable to get current location. Please check location permissions.');
        return;
      }

      // Show dialog to confirm and set radius
      final result = await _showCurrentLocationDialog(currentLocation);
      if (result != null) {
        print('Creating campus with data: ${result.toJson()}');
        final campusId = await MongoDBCampusService.createCampusBoundary(result);
        if (campusId != null) {
          _showSuccessDialog('Campus created successfully using your current location!');
          await _loadCampusBoundaries();
        } else {
          _showErrorDialog('Failed to create campus in MongoDB. You may already have an active campus boundary. Please deactivate your existing campus before creating a new one.');
        }
      }
    } catch (e) {
      _showErrorDialog('Error using current location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Create custom campus
  Future<void> _createCustomCampus() async {
      final result = await _showCustomCampusDialog();
      if (result != null) {
        setState(() => _isLoading = true);
        try {
          print('Creating custom campus with data: ${result.toJson()}');
          final campusId = await MongoDBCampusService.createCampusBoundary(result);
          if (campusId != null) {
            _showSuccessDialog('Custom campus created successfully in MongoDB!');
            await _loadCampusBoundaries();
          } else {
            _showErrorDialog('Failed to create custom campus in MongoDB. You may already have an active campus boundary. Please deactivate your existing campus before creating a new one.');
          }
        } catch (e) {
          _showErrorDialog('Error creating custom campus: $e');
        } finally {
          setState(() => _isLoading = false);
        }
      }
  }

  /// Show current location dialog
  Future<CampusBoundaryModel?> _showCurrentLocationDialog(GeoPoint currentLocation) async {
    final nameController = TextEditingController(text: 'My Campus');
    final descriptionController = TextEditingController(text: 'Campus created using current location');
    final radiusController = TextEditingController(text: '500');

    return await showDialog<CampusBoundaryModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Campus at Current Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.my_location, color: Colors.blue, size: 32),
                      const SizedBox(height: 8),
                      const Text('Current Location', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Lat: ${currentLocation.latitude.toStringAsFixed(6)}'),
                      Text('Lng: ${currentLocation.longitude.toStringAsFixed(6)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Campus Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  border: OutlineInputBorder(),
                  helperText: 'Recommended: 200-1000 meters',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && radiusController.text.isNotEmpty) {
                final campus = CampusBoundaryModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descriptionController.text,
                  boundaryType: 'circle',
                  center: currentLocation,
                  radius: double.parse(radiusController.text),
                  polygonPoints: const [],
                  bounds: GeoBounds(
                    southwest: GeoPoint(
                      latitude: currentLocation.latitude - 0.01,
                      longitude: currentLocation.longitude - 0.01,
                    ),
                    northeast: GeoPoint(
                      latitude: currentLocation.latitude + 0.01,
                      longitude: currentLocation.longitude + 0.01,
                    ),
                  ),
                  isActive: true,
                  createdBy: 'teacher',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                Navigator.pop(context, campus);
              }
            },
            child: const Text('Create Campus'),
          ),
        ],
      ),
    );
  }

  /// Show custom campus creation dialog
  Future<CampusBoundaryModel?> _showCustomCampusDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final latController = TextEditingController(text: '12.9716');
    final lngController = TextEditingController(text: '77.5946');
    final radiusController = TextEditingController(text: '500');

    return await showDialog<CampusBoundaryModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Custom Campus'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Campus Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  latController.text.isNotEmpty &&
                  lngController.text.isNotEmpty &&
                  radiusController.text.isNotEmpty) {
                try {
                  final lat = double.parse(latController.text);
                  final lng = double.parse(lngController.text);
                  final radius = double.parse(radiusController.text);
                  
                  // Validate coordinates
                  if (lat < -90 || lat > 90) {
                    _showErrorDialog('Latitude must be between -90 and 90');
                    return;
                  }
                  if (lng < -180 || lng > 180) {
                    _showErrorDialog('Longitude must be between -180 and 180');
                    return;
                  }
                  if (radius <= 0 || radius > 10000) {
                    _showErrorDialog('Radius must be between 1 and 10000 meters');
                    return;
                  }
                  
                  final campus = CampusBoundaryModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    description: descriptionController.text,
                    boundaryType: 'circle',
                    center: GeoPoint(latitude: lat, longitude: lng),
                    radius: radius,
                    polygonPoints: const [],
                    bounds: GeoBounds(
                      southwest: GeoPoint(latitude: lat - 0.01, longitude: lng - 0.01),
                      northeast: GeoPoint(latitude: lat + 0.01, longitude: lng + 0.01),
                    ),
                    isActive: true,
                    createdBy: 'teacher',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  Navigator.pop(context, campus);
                } catch (e) {
                  _showErrorDialog('Invalid input. Please check your coordinates and radius.');
                }
              } else {
                _showErrorDialog('Please fill in all required fields');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(String campusName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campus'),
        content: Text('Are you sure you want to delete "$campusName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Check if teacher already has an active campus
  bool _hasActiveCampus() {
    return _campusBoundaries.any((campus) => campus.isActive);
  }

  /// Show success dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Success'),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Setup'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Setup Campus Boundaries',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Define the area where students can mark attendance',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Warning message if teacher has active campus
                  if (_hasActiveCampus())
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You already have an active campus boundary. Deactivate it first to create a new one.',
                              style: TextStyle(color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_hasActiveCampus()) const SizedBox(height: 16),

                  // Quick Setup Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _hasActiveCampus() ? null : _createDemoCampus,
                          icon: const Icon(Icons.school),
                          label: const Text('Demo Campus'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasActiveCampus() ? Colors.grey : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _hasActiveCampus() ? null : _useCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Use Current Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasActiveCampus() ? Colors.grey : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _hasActiveCampus() ? null : _createCustomCampus,
                          icon: const Icon(Icons.add_location),
                          label: const Text('Custom Campus'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasActiveCampus() ? Colors.grey : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Campus Boundaries List
                  const Text(
                    'Existing Campus Boundaries',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: _campusBoundaries.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No campus boundaries defined',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Create a campus boundary to get started',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _campusBoundaries.length,
                            itemBuilder: (context, index) {
                              final campus = _campusBoundaries[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: campus.isActive ? Colors.green : Colors.orange,
                                    child: Icon(
                                      campus.isActive ? Icons.check : Icons.pause,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(campus.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(campus.description),
                                      Row(
                                        children: [
                                          Icon(
                                            campus.isActive ? Icons.check_circle : Icons.pause_circle,
                                            size: 16,
                                            color: campus.isActive ? Colors.green : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            campus.isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: campus.isActive ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text('Type: ${campus.boundaryType}'),
                                      Text('Radius: ${campus.radius}m'),
                                      Text('Center: ${campus.center.latitude.toStringAsFixed(4)}, ${campus.center.longitude.toStringAsFixed(4)}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'toggle',
                                        child: Text(campus.isActive ? 'Deactivate' : 'Activate'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'toggle') {
                                        // Toggle active status
                                        setState(() => _isLoading = true);
                                        try {
                                          final updatedCampus = CampusBoundaryModel(
                                            id: campus.id,
                                            name: campus.name,
                                            description: campus.description,
                                            boundaryType: campus.boundaryType,
                                            center: campus.center,
                                            radius: campus.radius,
                                            polygonPoints: campus.polygonPoints,
                                            bounds: campus.bounds,
                                            isActive: !campus.isActive,
                                            createdBy: campus.createdBy,
                                            createdAt: campus.createdAt,
                                            updatedAt: DateTime.now(),
                                          );
                                          print('Updating campus ${campus.name} from ${campus.isActive} to ${!campus.isActive}');
                                          final success = await MongoDBCampusService.updateCampusBoundary(updatedCampus);
                                          if (success) {
                                            _showSuccessDialog('Campus ${campus.isActive ? 'deactivated' : 'activated'} successfully!');
                                            // Force UI refresh by updating the local list immediately
                                            setState(() {
                                              _campusBoundaries[index] = updatedCampus;
                                            });
                                            // Also reload from server to ensure consistency
                                            await _loadCampusBoundaries();
                                          } else {
                                            _showErrorDialog('Failed to ${campus.isActive ? 'deactivate' : 'activate'} campus');
                                          }
                                        } catch (e) {
                                          _showErrorDialog('Error updating campus: $e');
                                        } finally {
                                          setState(() => _isLoading = false);
                                        }
                                      } else if (value == 'delete') {
                                        // Delete campus
                                        final confirmed = await _showDeleteConfirmation(campus.name);
                                        if (confirmed) {
                                          setState(() => _isLoading = true);
                                          try {
                                            final success = await MongoDBCampusService.deleteCampusBoundary(campus.id);
                                            if (success) {
                                              _showSuccessDialog('Campus deleted successfully!');
                                              await _loadCampusBoundaries();
                                            } else {
                                              _showErrorDialog('Failed to delete campus');
                                            }
                                          } catch (e) {
                                            _showErrorDialog('Error deleting campus: $e');
                                          } finally {
                                            setState(() => _isLoading = false);
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

}
