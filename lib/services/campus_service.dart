import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import 'location_service.dart';

class CampusService {
  static const String _campusKey = 'cached_campus_boundaries';
  
  final Dio _dio;
  final SharedPreferences _prefs;

  CampusService(this._dio, this._prefs);

  // Get all campus boundaries
  Future<ApiResponse<List<CampusBoundary>>> getCampusBoundaries() async {
    try {
      final response = await _dio.get('/campus/boundaries');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final boundaries = data.map((json) => CampusBoundary.fromJson(json)).toList();
        
        // Cache the boundaries
        await _cacheCampusBoundaries(boundaries);
        
        return ApiResponse.success(
          message: 'Campus boundaries retrieved successfully',
          data: boundaries,
        );
      } else {
        return ApiResponse.error(
          message: response.data['message'] ?? 'Failed to get campus boundaries',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Try to get cached data if network fails
      final cachedBoundaries = await _getCachedCampusBoundaries();
      if (cachedBoundaries.isNotEmpty) {
        return ApiResponse.success(
          message: 'Using cached campus boundaries',
          data: cachedBoundaries,
        );
      }
      
      return ApiResponse.error(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  // Get campus boundary by ID
  Future<ApiResponse<CampusBoundary>> getCampusBoundary(String campusId) async {
    try {
      final response = await _dio.get('/campus/boundaries/$campusId');

      if (response.statusCode == 200) {
        final boundary = CampusBoundary.fromJson(response.data['data']);
        
        return ApiResponse.success(
          message: 'Campus boundary retrieved successfully',
          data: boundary,
        );
      } else {
        return ApiResponse.error(
          message: response.data['message'] ?? 'Failed to get campus boundary',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  // Create new campus boundary (Teacher/Admin only)
  Future<ApiResponse<CampusBoundary>> createCampusBoundary(CampusBoundary boundary) async {
    try {
      final response = await _dio.post(
        '/campus/boundaries',
        data: boundary.toJson(),
      );

      if (response.statusCode == 201) {
        final newBoundary = CampusBoundary.fromJson(response.data['data']);
        
        // Update cache
        await _addToCachedBoundaries(newBoundary);
        
        return ApiResponse.success(
          message: 'Campus boundary created successfully',
          data: newBoundary,
        );
      } else {
        return ApiResponse.error(
          message: response.data['message'] ?? 'Failed to create campus boundary',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  // Update campus boundary (Teacher/Admin only)
  Future<ApiResponse<CampusBoundary>> updateCampusBoundary(String campusId, CampusBoundary boundary) async {
    try {
      final response = await _dio.put(
        '/campus/boundaries/$campusId',
        data: boundary.toJson(),
      );

      if (response.statusCode == 200) {
        final updatedBoundary = CampusBoundary.fromJson(response.data['data']);
        
        // Update cache
        await _updateCachedBoundary(updatedBoundary);
        
        return ApiResponse.success(
          message: 'Campus boundary updated successfully',
          data: updatedBoundary,
        );
      } else {
        return ApiResponse.error(
          message: response.data['message'] ?? 'Failed to update campus boundary',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  // Delete campus boundary (Admin only)
  Future<ApiResponse<void>> deleteCampusBoundary(String campusId) async {
    try {
      final response = await _dio.delete('/campus/boundaries/$campusId');

      if (response.statusCode == 200) {
        // Remove from cache
        await _removeFromCachedBoundaries(campusId);
        
        return ApiResponse.success(
          message: 'Campus boundary deleted successfully',
          data: null,
        );
      } else {
        return ApiResponse.error(
          message: response.data['message'] ?? 'Failed to delete campus boundary',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  // Get active campus boundaries for attendance
  Future<List<CampusBoundary>> getActiveCampusBoundaries() async {
    try {
      final response = await getCampusBoundaries();
      if (response.success && response.data != null) {
        return response.data!.where((boundary) => boundary.isActive).toList();
      }
    } catch (e) {
      print('Error getting active campus boundaries: $e');
    }
    return [];
  }

  // Validate if user is within any active campus boundary
  Future<CampusGeofenceResult> validateCampusAttendance() async {
    try {
      final activeBoundaries = await getActiveCampusBoundaries();
      
      if (activeBoundaries.isEmpty) {
        return CampusGeofenceResult(
          isInsideCampus: false,
          error: 'No campus boundaries configured. Please contact your administrator.',
        );
      }

      final locationService = LocationService();
      
      // Check against all active boundaries
      for (final boundary in activeBoundaries) {
        final result = await locationService.validateCampusGeofence(boundary);
        if (result.isInsideCampus) {
          return result;
        }
      }

      // If not inside any boundary, return error for user feedback
      return CampusGeofenceResult(
        isInsideCampus: false,
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

  // Cache management methods
  Future<void> _cacheCampusBoundaries(List<CampusBoundary> boundaries) async {
    try {
      final jsonList = boundaries.map((b) => b.toJson()).toList();
      await _prefs.setString(_campusKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error caching campus boundaries: $e');
    }
  }

  Future<List<CampusBoundary>> _getCachedCampusBoundaries() async {
    try {
      final cachedData = _prefs.getString(_campusKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => CampusBoundary.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting cached campus boundaries: $e');
    }
    return [];
  }

  Future<void> _addToCachedBoundaries(CampusBoundary boundary) async {
    try {
      final cachedBoundaries = await _getCachedCampusBoundaries();
      cachedBoundaries.add(boundary);
      await _cacheCampusBoundaries(cachedBoundaries);
    } catch (e) {
      print('Error adding to cached boundaries: $e');
    }
  }

  Future<void> _updateCachedBoundary(CampusBoundary boundary) async {
    try {
      final cachedBoundaries = await _getCachedCampusBoundaries();
      final index = cachedBoundaries.indexWhere((b) => b.id == boundary.id);
      if (index != -1) {
        cachedBoundaries[index] = boundary;
        await _cacheCampusBoundaries(cachedBoundaries);
      }
    } catch (e) {
      print('Error updating cached boundary: $e');
    }
  }

  Future<void> _removeFromCachedBoundaries(String campusId) async {
    try {
      final cachedBoundaries = await _getCachedCampusBoundaries();
      cachedBoundaries.removeWhere((b) => b.id == campusId);
      await _cacheCampusBoundaries(cachedBoundaries);
    } catch (e) {
      print('Error removing from cached boundaries: $e');
    }
  }

  // Handle Dio errors
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return 'Unauthorized. Please login again.';
        } else if (statusCode == 403) {
          return 'Access denied. You do not have permission to perform this action.';
        } else if (statusCode == 404) {
          return 'Campus boundary not found.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return 'Request failed with status: $statusCode';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
