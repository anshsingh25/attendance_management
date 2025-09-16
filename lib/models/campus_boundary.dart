import 'package:json_annotation/json_annotation.dart';
import '../services/location_service.dart';

part 'campus_boundary.g.dart';

@JsonSerializable()
class CampusBoundaryModel {
  final String id;
  final String name;
  final String description;
  final String boundaryType;
  final GeoPoint center;
  final double radius;
  final List<GeoPoint> polygonPoints;
  final GeoBounds bounds;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CampusBoundaryModel({
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

  factory CampusBoundaryModel.fromJson(Map<String, dynamic> json) {
    try {
      return CampusBoundaryModel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        boundaryType: json['boundaryType']?.toString() ?? 'circle',
        center: json['center'] != null 
            ? GeoPoint.fromJson(json['center'] as Map<String, dynamic>)
            : GeoPoint(latitude: 0, longitude: 0),
        radius: (json['radius'] as num?)?.toDouble() ?? 0.0,
        polygonPoints: (json['polygonPoints'] as List<dynamic>?)
            ?.map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
        bounds: json['bounds'] != null 
            ? GeoBounds.fromJson(json['bounds'] as Map<String, dynamic>)
            : GeoBounds(
                southwest: GeoPoint(latitude: 0, longitude: 0),
                northeast: GeoPoint(latitude: 0, longitude: 0),
              ),
        isActive: json['isActive'] as bool? ?? true,
        createdBy: json['createdBy']?.toString() ?? '',
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'].toString())
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing CampusBoundaryModel from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() {
    final json = _$CampusBoundaryModelToJson(this);
    // Remove fields that the backend doesn't expect
    json.remove('id'); // Backend will generate its own ID
    json.remove('createdAt'); // Backend will set this
    json.remove('updatedAt'); // Backend will set this
    return json;
  }

  CampusBoundaryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? boundaryType,
    GeoPoint? center,
    double? radius,
    List<GeoPoint>? polygonPoints,
    GeoBounds? bounds,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampusBoundaryModel(
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

  // Convert to CampusBoundary for use with LocationService
  CampusBoundary toCampusBoundary() {
    return CampusBoundary(
      id: id,
      name: name,
      description: description,
      boundaryType: CampusBoundaryType.values.firstWhere(
        (e) => e.name == boundaryType,
        orElse: () => CampusBoundaryType.circle,
      ),
      center: center,
      radius: radius,
      polygonPoints: polygonPoints,
      bounds: bounds,
      isActive: isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Create from CampusBoundary
  factory CampusBoundaryModel.fromCampusBoundary(CampusBoundary boundary) {
    return CampusBoundaryModel(
      id: boundary.id,
      name: boundary.name,
      description: boundary.description,
      boundaryType: boundary.boundaryType.name,
      center: boundary.center,
      radius: boundary.radius,
      polygonPoints: boundary.polygonPoints,
      bounds: boundary.bounds,
      isActive: boundary.isActive,
      createdBy: boundary.createdBy,
      createdAt: boundary.createdAt,
      updatedAt: boundary.updatedAt,
    );
  }
}
