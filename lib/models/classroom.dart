import 'package:json_annotation/json_annotation.dart';

part 'classroom.g.dart';

@JsonSerializable()
class Classroom {
  final String id;
  final String name;
  final String code;
  final String description;
  final String? building;
  final String? roomNumber;
  final String? wifiSSID;
  final double? latitude;
  final double? longitude;
  final double? radius; // in meters for geofencing
  final String? teacherId;
  final List<String> studentIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const Classroom({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    this.building,
    this.roomNumber,
    this.wifiSSID,
    this.latitude,
    this.longitude,
    this.radius,
    this.teacherId,
    this.studentIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) => _$ClassroomFromJson(json);
  Map<String, dynamic> toJson() => _$ClassroomToJson(this);

  Classroom copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? building,
    String? roomNumber,
    String? wifiSSID,
    double? latitude,
    double? longitude,
    double? radius,
    String? teacherId,
    List<String>? studentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Classroom(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      building: building ?? this.building,
      roomNumber: roomNumber ?? this.roomNumber,
      wifiSSID: wifiSSID ?? this.wifiSSID,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      teacherId: teacherId ?? this.teacherId,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get hasLocationValidation => latitude != null && longitude != null && radius != null;
  bool get hasWifiValidation => wifiSSID != null && wifiSSID!.isNotEmpty;
}
