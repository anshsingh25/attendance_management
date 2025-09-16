// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Classroom _$ClassroomFromJson(Map<String, dynamic> json) => Classroom(
  id: json['id'] as String,
  name: json['name'] as String,
  code: json['code'] as String,
  description: json['description'] as String,
  building: json['building'] as String?,
  roomNumber: json['roomNumber'] as String?,
  wifiSSID: json['wifiSSID'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  radius: (json['radius'] as num?)?.toDouble(),
  teacherId: json['teacherId'] as String?,
  studentIds:
      (json['studentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$ClassroomToJson(Classroom instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'code': instance.code,
  'description': instance.description,
  'building': instance.building,
  'roomNumber': instance.roomNumber,
  'wifiSSID': instance.wifiSSID,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'radius': instance.radius,
  'teacherId': instance.teacherId,
  'studentIds': instance.studentIds,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isActive': instance.isActive,
};
