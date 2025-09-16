import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'student', 'teacher', 'admin'
  final String? studentId;
  final String? department;
  final String? course;
  final String? semester;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.studentId,
    this.department,
    this.course,
    this.semester,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? studentId,
    String? department,
    String? course,
    String? semester,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      course: course ?? this.course,
      semester: semester ?? this.semester,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin';
}
