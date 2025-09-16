// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResponse<T> _$ApiResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ApiResponse<T>(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  error: json['error'] as String?,
  statusCode: (json['statusCode'] as num?)?.toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$ApiResponseToJson<T>(
  ApiResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
  'error': instance.error,
  'statusCode': instance.statusCode,
  'timestamp': instance.timestamp.toIso8601String(),
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      user: LoginResponse._userFromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refreshToken': instance.refreshToken,
      'user': LoginResponse._userToJson(instance.user),
    };

AttendanceSubmissionRequest _$AttendanceSubmissionRequestFromJson(
  Map<String, dynamic> json,
) => AttendanceSubmissionRequest(
  sessionId: json['sessionId'] as String,
  studentId: json['studentId'] as String,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  wifiSSID: json['wifiSSID'] as String?,
  qrCodeData: json['qrCodeData'] as String?,
  deviceInfo: json['deviceInfo'] as String?,
);

Map<String, dynamic> _$AttendanceSubmissionRequestToJson(
  AttendanceSubmissionRequest instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'studentId': instance.studentId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'wifiSSID': instance.wifiSSID,
  'qrCodeData': instance.qrCodeData,
  'deviceInfo': instance.deviceInfo,
};
