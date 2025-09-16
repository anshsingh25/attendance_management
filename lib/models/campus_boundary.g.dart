// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campus_boundary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampusBoundaryModel _$CampusBoundaryModelFromJson(Map<String, dynamic> json) =>
    CampusBoundaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      boundaryType: json['boundaryType'] as String,
      center: GeoPoint.fromJson(json['center'] as Map<String, dynamic>),
      radius: (json['radius'] as num).toDouble(),
      polygonPoints: (json['polygonPoints'] as List<dynamic>)
          .map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      bounds: GeoBounds.fromJson(json['bounds'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CampusBoundaryModelToJson(
  CampusBoundaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'boundaryType': instance.boundaryType,
  'center': instance.center,
  'radius': instance.radius,
  'polygonPoints': instance.polygonPoints,
  'bounds': instance.bounds,
  'isActive': instance.isActive,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
