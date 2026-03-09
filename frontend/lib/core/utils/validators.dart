/// Validators
///
/// Form validation utilities

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Employee ID validation
  static String? validateEmployeeId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Employee ID is required';
    }

    if (value.length < 3) {
      return 'Employee ID must be at least 3 characters';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces, dashes, and parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it starts with + and has 10-15 digits
    final phoneRegex = RegExp(r'^\+?[1-9]\d{9,14}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Name'} is required';
    }

    if (value.length < 2) {
      return '${fieldName ?? 'Name'} must be at least 2 characters';
    }

    if (value.length > 50) {
      return '${fieldName ?? 'Name'} must be less than 50 characters';
    }

    // Only letters and spaces
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return '${fieldName ?? 'Name'} can only contain letters';
    }

    return null;
  }

  // Number validation
  static String? validateNumber(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value, {String? fieldName}) {
    final error = validateNumber(value, fieldName: fieldName);
    if (error != null) return error;

    if (double.parse(value!) <= 0) {
      return '${fieldName ?? 'Value'} must be greater than 0';
    }

    return null;
  }

  // Date validation (not in future)
  static String? validatePastDate(DateTime? date, {String? fieldName}) {
    if (date == null) {
      return '${fieldName ?? 'Date'} is required';
    }

    if (date.isAfter(DateTime.now())) {
      return '${fieldName ?? 'Date'} cannot be in the future';
    }

    return null;
  }

  // Date validation (not in past)
  static String? validateFutureDate(DateTime? date, {String? fieldName}) {
    if (date == null) {
      return '${fieldName ?? 'Date'} is required';
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (date.isBefore(todayDate)) {
      return '${fieldName ?? 'Date'} cannot be in the past';
    }

    return null;
  }

  // Date range validation
  static String? validateDateRange(
      DateTime? startDate,
      DateTime? endDate, {
        String? startFieldName,
        String? endFieldName,
      }) {
    if (startDate == null) {
      return '${startFieldName ?? 'Start date'} is required';
    }

    if (endDate == null) {
      return '${endFieldName ?? 'End date'} is required';
    }

    if (endDate.isBefore(startDate)) {
      return '${endFieldName ?? 'End date'} must be after ${startFieldName ?? 'start date'}';
    }

    return null;
  }

  // Reason/Comments validation
  static String? validateReason(String? value, {int? maxLength}) {
    if (value == null || value.isEmpty) {
      return 'Reason is required';
    }

    if (value.length < 10) {
      return 'Reason must be at least 10 characters';
    }

    if (maxLength != null && value.length > maxLength) {
      return 'Reason must be less than $maxLength characters';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(
      String? value,
      String? password,
      ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Salary validation
  static String? validateSalary(String? value) {
    final error = validatePositiveNumber(value, fieldName: 'Salary');
    if (error != null) return error;

    final salary = double.parse(value!);

    if (salary < 1000) {
      return 'Salary must be at least ₹1,000';
    }

    if (salary > 10000000) {
      return 'Salary must be less than ₹1,00,00,000';
    }

    return null;
  }

  // Phone number validation (Indian format - 10 digits)
  static String? validateIndianPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // Remove spaces, dashes, parentheses, and +91
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '').replaceAll('91', '');

    // Must be exactly 10 digits and start with 6-9
    if (cleaned.length != 10) {
      return 'Phone number must be 10 digits';
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Please enter a valid 10-digit phone number';
    }

    return null;
  }

  // Leave days validation
  static String? validateLeaveDays(int? days, int? availableBalance) {
    if (days == null || days <= 0) {
      return 'Please select valid leave days';
    }

    if (availableBalance != null && days > availableBalance) {
      return 'Insufficient leave balance. Available: $availableBalance days';
    }

    if (days > 30) {
      return 'Cannot apply for more than 30 days at once';
    }

    return null;
  }
}