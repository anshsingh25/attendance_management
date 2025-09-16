import 'package:json_annotation/json_annotation.dart';

part 'attendance_session.g.dart';

enum SessionStatus {
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

@JsonSerializable()
class AttendanceSession {
  final String id;
  final String classroomId;
  final String teacherId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final SessionStatus status;
  final String? qrCodeData;
  final DateTime? qrCodeGeneratedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> attendedStudentIds;
  final Map<String, AttendanceRecord> attendanceRecords;

  const AttendanceSession({
    required this.id,
    required this.classroomId,
    required this.teacherId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.status,
    this.qrCodeData,
    this.qrCodeGeneratedAt,
    required this.createdAt,
    required this.updatedAt,
    this.attendedStudentIds = const [],
    this.attendanceRecords = const {},
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) => _$AttendanceSessionFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceSessionToJson(this);

  AttendanceSession copyWith({
    String? id,
    String? classroomId,
    String? teacherId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    SessionStatus? status,
    String? qrCodeData,
    DateTime? qrCodeGeneratedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attendedStudentIds,
    Map<String, AttendanceRecord>? attendanceRecords,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      classroomId: classroomId ?? this.classroomId,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      qrCodeGeneratedAt: qrCodeGeneratedAt ?? this.qrCodeGeneratedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attendedStudentIds: attendedStudentIds ?? this.attendedStudentIds,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
    );
  }

  bool get isActive => status == SessionStatus.active;
  bool get isCompleted => status == SessionStatus.completed;
  bool get isScheduled => status == SessionStatus.scheduled;
  bool get isCancelled => status == SessionStatus.cancelled;
  
  bool get hasQrCode => qrCodeData != null && qrCodeData!.isNotEmpty;
  
  Duration get remainingTime {
    if (!isActive) return Duration.zero;
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }
  
  bool get isExpired => DateTime.now().isAfter(endTime);
}

@JsonSerializable()
class AttendanceRecord {
  final String studentId;
  final DateTime timestamp;
  final String? locationLatitude;
  final String? locationLongitude;
  final String? wifiSSID;
  final String? qrCodeData;
  final bool isValidated;
  final String? validationError;
  final String? deviceInfo;

  const AttendanceRecord({
    required this.studentId,
    required this.timestamp,
    this.locationLatitude,
    this.locationLongitude,
    this.wifiSSID,
    this.qrCodeData,
    this.isValidated = false,
    this.validationError,
    this.deviceInfo,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => _$AttendanceRecordFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceRecordToJson(this);

  AttendanceRecord copyWith({
    String? studentId,
    DateTime? timestamp,
    String? locationLatitude,
    String? locationLongitude,
    String? wifiSSID,
    String? qrCodeData,
    bool? isValidated,
    String? validationError,
    String? deviceInfo,
  }) {
    return AttendanceRecord(
      studentId: studentId ?? this.studentId,
      timestamp: timestamp ?? this.timestamp,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      wifiSSID: wifiSSID ?? this.wifiSSID,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      isValidated: isValidated ?? this.isValidated,
      validationError: validationError ?? this.validationError,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}
