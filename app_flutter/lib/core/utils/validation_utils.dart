import '../../services/config_service.dart';

class ValidationUtils {
  ValidationUtils._();

  static void requireNonNull(Map<String, dynamic> params) {
    for (final entry in params.entries) {
      if (entry.value == null) {
        throw ArgumentError('${entry.key} cannot be null');
      }
    }
  }

  static int requireCurrentUser([String? customError]) {
    if (!ConfigService.instance.hasUser) {
      throw Exception(customError ?? 'User not authenticated');
    }
    return ConfigService.instance.currentUserId;
  }

  static String requireNonEmpty(String? value, String paramName) {
    if (value == null || value.trim().isEmpty) {
      throw ArgumentError('$paramName cannot be empty');
    }
    return value.trim();
  }

  static T requirePositive<T extends num>(T? value, String paramName) {
    if (value == null || value <= 0) {
      throw ArgumentError('$paramName must be positive');
    }
    return value;
  }

  static T requireInRange<T extends num>(T? value, String paramName, T min, T max) {
    if (value == null) {
      throw ArgumentError('$paramName cannot be null');
    }
    if (value < min || value > max) {
      throw ArgumentError('$paramName must be between $min and $max');
    }
    return value;
  }

  static String requireValidEmail(String? email) {
    if (email == null || email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (!emailRegex.hasMatch(email)) {
      throw ArgumentError('Invalid email format');
    }

    return email;
  }

  static String requireValidPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }

    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      throw ArgumentError('Invalid phone number format');
    }

    return phoneNumber;
  }

  static void validate(List<bool Function()> validations, List<String> errorMessages) {
    if (validations.length != errorMessages.length) {
      throw ArgumentError('Validations and error messages must have same length');
    }

    for (int i = 0; i < validations.length; i++) {
      if (!validations[i]()) {
        throw Exception(errorMessages[i]);
      }
    }
  }
}
