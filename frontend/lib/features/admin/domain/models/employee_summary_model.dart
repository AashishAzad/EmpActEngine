/// Employee Summary Model
///
/// Lightweight model for displaying employee lists in admin screens

class EmployeeSummaryModel {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? designation;
  final String? department;
  final String role;
  final String? dateOfJoining;

  EmployeeSummaryModel({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.designation,
    this.department,
    required this.role,
    this.dateOfJoining,
  });

  // Computed properties
  String get fullName => '$firstName $lastName';

  String get initials {
    return firstName.isNotEmpty && lastName.isNotEmpty
        ? firstName[0] + lastName[0]
        : '??';
  }

  // From JSON
  factory EmployeeSummaryModel.fromJson(Map<String, dynamic> json) {
    return EmployeeSummaryModel(
      id: json['id'].toString(),
      employeeId: json['employeeId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      designation: json['designation'],
      department: json['department'],
      role: json['role'] ?? 'EMPLOYEE',
      dateOfJoining: json['dateOfJoining'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'designation': designation,
      'department': department,
      'role': role,
      'dateOfJoining': dateOfJoining,
    };
  }

  // Copy with
  EmployeeSummaryModel copyWith({
    String? id,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? designation,
    String? department,
    String? role,
    String? dateOfJoining,
  }) {
    return EmployeeSummaryModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      role: role ?? this.role,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
    );
  }
}