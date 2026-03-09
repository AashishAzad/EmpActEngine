import 'package:equatable/equatable.dart';

/// User Entity
///
/// Domain model representing a user.
/// Used throughout the app — BLoC, UI, storage.

class User extends Equatable {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? status;
  final String? phoneNumber;
  final String? designation;
  final String? department;
  final String? dateOfJoining;
  final String? qualification;
  final String? address;
  final String? emergencyContact;
  final int? casualLeaveBalance;
  final int? sickLeaveBalance;
  final int? allPurposeLeaveBalance;
  final String? lastLogin;
  final String? createdAt;
  final String? updatedAt;

  const User({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.status,
    this.phoneNumber,
    this.designation,
    this.department,
    this.dateOfJoining,
    this.qualification,
    this.address,
    this.emergencyContact,
    this.casualLeaveBalance,
    this.sickLeaveBalance,
    this.allPurposeLeaveBalance,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isManager => role.toUpperCase() == 'MANAGER';
  bool get isEmployee => role.toUpperCase() == 'EMPLOYEE';
  bool get isAdminOrManager => isAdmin || isManager;

  int get totalLeaveBalance =>
      (casualLeaveBalance ?? 0) +
          (sickLeaveBalance ?? 0) +
          (allPurposeLeaveBalance ?? 0);

  @override
  List<Object?> get props => [
    id,
    employeeId,
    firstName,
    lastName,
    email,
    role,
    status,
    phoneNumber,
    designation,
    department,
    dateOfJoining,
    qualification,
    address,
    emergencyContact,
    casualLeaveBalance,
    sickLeaveBalance,
    allPurposeLeaveBalance,
    lastLogin,
    createdAt,
    updatedAt,
  ];
}