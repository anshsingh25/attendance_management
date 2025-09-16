import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;
  final int? statusCode;
  final DateTime timestamp;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.statusCode,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) => 
      _$ApiResponseToJson(this, toJsonT);

  factory ApiResponse.success({
    required String message,
    T? data,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode ?? 200,
      timestamp: DateTime.now(),
    );
  }

  factory ApiResponse.error({
    required String message,
    String? error,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      error: error,
      statusCode: statusCode ?? 500,
      timestamp: DateTime.now(),
    );
  }
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final String token;
  final String refreshToken;
  @JsonKey(fromJson: _userFromJson, toJson: _userToJson)
  final User user;

  const LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  static User _userFromJson(Map<String, dynamic> json) => User.fromJson(json);
  static Map<String, dynamic> _userToJson(User user) => user.toJson();
}

@JsonSerializable()
class AttendanceSubmissionRequest {
  final String sessionId;
  final String studentId;
  final double? latitude;
  final double? longitude;
  final String? wifiSSID;
  final String? qrCodeData;
  final String? deviceInfo;

  const AttendanceSubmissionRequest({
    required this.sessionId,
    required this.studentId,
    this.latitude,
    this.longitude,
    this.wifiSSID,
    this.qrCodeData,
    this.deviceInfo,
  });

  factory AttendanceSubmissionRequest.fromJson(Map<String, dynamic> json) => 
      _$AttendanceSubmissionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceSubmissionRequestToJson(this);
}
