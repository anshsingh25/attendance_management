// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceSession _$AttendanceSessionFromJson(Map<String, dynamic> json) =>
    AttendanceSession(
      id: json['id'] as String,
      classroomId: json['classroomId'] as String,
      teacherId: json['teacherId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      status: $enumDecode(_$SessionStatusEnumMap, json['status']),
      qrCodeData: json['qrCodeData'] as String?,
      qrCodeGeneratedAt: json['qrCodeGeneratedAt'] == null
          ? null
          : DateTime.parse(json['qrCodeGeneratedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      attendedStudentIds:
          (json['attendedStudentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      attendanceRecords:
          (json['attendanceRecords'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              AttendanceRecord.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          const {},
    );

Map<String, dynamic> _$AttendanceSessionToJson(AttendanceSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'classroomId': instance.classroomId,
      'teacherId': instance.teacherId,
      'title': instance.title,
      'description': instance.description,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'durationMinutes': instance.durationMinutes,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'qrCodeData': instance.qrCodeData,
      'qrCodeGeneratedAt': instance.qrCodeGeneratedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'attendedStudentIds': instance.attendedStudentIds,
      'attendanceRecords': instance.attendanceRecords,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.scheduled: 'scheduled',
  SessionStatus.active: 'active',
  SessionStatus.completed: 'completed',
  SessionStatus.cancelled: 'cancelled',
};

AttendanceRecord _$AttendanceRecordFromJson(Map<String, dynamic> json) =>
    AttendanceRecord(
      studentId: json['studentId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      locationLatitude: json['locationLatitude'] as String?,
      locationLongitude: json['locationLongitude'] as String?,
      wifiSSID: json['wifiSSID'] as String?,
      qrCodeData: json['qrCodeData'] as String?,
      isValidated: json['isValidated'] as bool? ?? false,
      validationError: json['validationError'] as String?,
      deviceInfo: json['deviceInfo'] as String?,
    );

Map<String, dynamic> _$AttendanceRecordToJson(AttendanceRecord instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'timestamp': instance.timestamp.toIso8601String(),
      'locationLatitude': instance.locationLatitude,
      'locationLongitude': instance.locationLongitude,
      'wifiSSID': instance.wifiSSID,
      'qrCodeData': instance.qrCodeData,
      'isValidated': instance.isValidated,
      'validationError': instance.validationError,
      'deviceInfo': instance.deviceInfo,
    };
