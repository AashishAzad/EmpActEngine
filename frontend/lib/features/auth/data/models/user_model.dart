import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// User Model
///
/// Handles TWO different backend response shapes:
///
/// 1. AuthResponse.UserInfo — returned inside login/refresh response
///    Fields: id, employeeId, firstName, lastName, email, role,
///            designation, department, phoneNumber, dateOfJoining,
///            casualLeaveBalance, sickLeaveBalance, allPurposeLeaveBalance,
///            lastLogin
///
/// 2. EmployeeResponse — returned by GET /auth/profile and employee endpoints
///    All of the above PLUS: status, qualification, address, emergencyContact,
///    createdAt, updatedAt, salary (ignored here)
///
/// Both shapes share the same field names, so one model handles both.
/// Extra fields from EmployeeResponse are nullable and ignored if absent.

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.employeeId,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.role,
    super.status,
    super.phoneNumber,
    super.designation,
    super.department,
    super.dateOfJoining,
    super.qualification,
    super.address,
    super.emergencyContact,
    super.casualLeaveBalance,
    super.sickLeaveBalance,
    super.allPurposeLeaveBalance,
    super.lastLogin,
    super.createdAt,
    super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  User toEntity() => User(
    id: id,
    employeeId: employeeId,
    firstName: firstName,
    lastName: lastName,
    email: email,
    role: role,
    status: status,
    phoneNumber: phoneNumber,
    designation: designation,
    department: department,
    dateOfJoining: dateOfJoining,
    qualification: qualification,
    address: address,
    emergencyContact: emergencyContact,
    casualLeaveBalance: casualLeaveBalance,
    sickLeaveBalance: sickLeaveBalance,
    allPurposeLeaveBalance: allPurposeLeaveBalance,
    lastLogin: lastLogin,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Login Response Model
///
/// Maps to AuthResponse from backend:
/// { accessToken, refreshToken, user: UserInfo }

@JsonSerializable()
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}