// GENERATED CODE - DO NOT MODIFY BY HAND
// But manually maintained to match backend EmployeeResponse + AuthResponse.UserInfo shapes.
// If you run build_runner, it will regenerate this correctly from user_model.dart.

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  // ── Required fields (present in both AuthResponse.UserInfo and EmployeeResponse)
  id: json['id'] as String,                          // UUID serialized as String
  employeeId: json['employeeId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  role: (json['role'] as String?) ?? '',             // UserRole enum → "ADMIN" / "MANAGER" / "EMPLOYEE"

  // ── Optional fields (in both shapes, nullable)
  phoneNumber: json['phoneNumber'] as String?,
  designation: json['designation'] as String?,
  department: json['department'] as String?,
  casualLeaveBalance: (json['casualLeaveBalance'] as num?)?.toInt(),
  sickLeaveBalance: (json['sickLeaveBalance'] as num?)?.toInt(),
  allPurposeLeaveBalance: (json['allPurposeLeaveBalance'] as num?)?.toInt(),

  // ── DateTime fields — backend sends ISO strings, stored as String in Flutter
  // LocalDate  → "2025-08-23"
  // LocalDateTime → "2026-02-23T20:51:41"
  dateOfJoining: json['dateOfJoining'] as String?,
  lastLogin: json['lastLogin'] as String?,

  // ── EmployeeResponse-only fields (null when coming from AuthResponse.UserInfo)
  status: json['status'] as String?,                 // EmployeeStatus enum → "ACTIVE" etc.
  qualification: json['qualification'] as String?,
  address: json['address'] as String?,
  emergencyContact: json['emergencyContact'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,

  // NOTE: 'salary' field from EmployeeResponse is intentionally ignored here.
  // It's only used on the employee detail screen via a separate SalaryModel.
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employeeId': instance.employeeId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'role': instance.role,
      'status': instance.status,
      'phoneNumber': instance.phoneNumber,
      'designation': instance.designation,
      'department': instance.department,
      'dateOfJoining': instance.dateOfJoining,
      'qualification': instance.qualification,
      'address': instance.address,
      'emergencyContact': instance.emergencyContact,
      'casualLeaveBalance': instance.casualLeaveBalance,
      'sickLeaveBalance': instance.sickLeaveBalance,
      'allPurposeLeaveBalance': instance.allPurposeLeaveBalance,
      'lastLogin': instance.lastLogin,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user.toJson(),
    };