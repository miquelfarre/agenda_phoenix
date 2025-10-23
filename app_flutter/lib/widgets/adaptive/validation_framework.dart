import 'adaptive_card.dart';
import 'adaptive_text_field.dart';

class EmailValidator extends TextFieldValidator {
  @override
  String get name => 'email';

  @override
  ValidationResult validate(String text) {
    if (text.isEmpty) {
      return ValidationResult.invalid([
        const ValidationIssue(
          message: 'Email is required',
          severity: ValidationSeverity.error,
        ),
      ]);
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(text)) {
      return ValidationResult.invalid([
        const ValidationIssue(
          message: 'Please enter a valid email address',
          severity: ValidationSeverity.error,
        ),
      ]);
    }

    return ValidationResult.valid();
  }
}

class RequiredValidator extends TextFieldValidator {
  final String? customMessage;

  RequiredValidator({this.customMessage});

  @override
  String get name => 'required';

  @override
  ValidationResult validate(String text) {
    if (text.trim().isEmpty) {
      return ValidationResult.invalid([
        ValidationIssue(
          message: customMessage ?? 'This field is required',
          severity: ValidationSeverity.error,
        ),
      ]);
    }

    return ValidationResult.valid();
  }
}

class MinLengthValidator extends TextFieldValidator {
  final int minLength;
  final String? customMessage;

  MinLengthValidator(this.minLength, {this.customMessage});

  @override
  String get name => 'minLength';

  @override
  ValidationResult validate(String text) {
    if (text.length < minLength) {
      return ValidationResult.invalid([
        ValidationIssue(
          message: customMessage ?? 'Minimum length is $minLength characters',
          severity: ValidationSeverity.error,
        ),
      ]);
    }

    return ValidationResult.valid();
  }
}

class MaxLengthValidator extends TextFieldValidator {
  final int maxLength;
  final String? customMessage;

  MaxLengthValidator(this.maxLength, {this.customMessage});

  @override
  String get name => 'maxLength';

  @override
  ValidationResult validate(String text) {
    if (text.length > maxLength) {
      return ValidationResult.invalid([
        ValidationIssue(
          message: customMessage ?? 'Maximum length is $maxLength characters',
          severity: ValidationSeverity.error,
        ),
      ]);
    }

    return ValidationResult.valid();
  }
}

class PhoneValidator extends TextFieldValidator {
  @override
  String get name => 'phone';

  @override
  ValidationResult validate(String text) {
    if (text.isEmpty) {
      return ValidationResult.invalid([
        const ValidationIssue(
          message: 'Phone number is required',
          severity: ValidationSeverity.error,
        ),
      ]);
    }

    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10) {
      return ValidationResult.invalid([
        const ValidationIssue(
          message: 'Phone number must have at least 10 digits',
          severity: ValidationSeverity.error,
        ),
      ]);
    }

    return ValidationResult.valid();
  }
}

class PasswordValidator extends TextFieldValidator {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;

  PasswordValidator({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = false,
  });

  @override
  String get name => 'password';

  @override
  ValidationResult validate(String text) {
    final issues = <ValidationIssue>[];

    if (text.length < minLength) {
      issues.add(
        ValidationIssue(
          message: 'Password must be at least $minLength characters',
          severity: ValidationSeverity.error,
        ),
      );
    }

    if (requireUppercase && !text.contains(RegExp(r'[A-Z]'))) {
      issues.add(
        const ValidationIssue(
          message: 'Password must contain uppercase letters',
          severity: ValidationSeverity.error,
        ),
      );
    }

    if (requireLowercase && !text.contains(RegExp(r'[a-z]'))) {
      issues.add(
        const ValidationIssue(
          message: 'Password must contain lowercase letters',
          severity: ValidationSeverity.error,
        ),
      );
    }

    if (requireNumbers && !text.contains(RegExp(r'[0-9]'))) {
      issues.add(
        const ValidationIssue(
          message: 'Password must contain numbers',
          severity: ValidationSeverity.error,
        ),
      );
    }

    if (requireSpecialChars &&
        !text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      issues.add(
        const ValidationIssue(
          message: 'Password must contain special characters',
          severity: ValidationSeverity.error,
        ),
      );
    }

    if (issues.isNotEmpty) {
      return ValidationResult.invalid(issues);
    }

    return ValidationResult.valid();
  }
}

class RegexValidator extends TextFieldValidator {
  final RegExp regex;
  final String message;
  final String validatorName;

  RegexValidator({
    required this.regex,
    required this.message,
    required this.validatorName,
  });

  @override
  String get name => validatorName;

  @override
  ValidationResult validate(String text) {
    if (!regex.hasMatch(text)) {
      return ValidationResult.invalid([
        ValidationIssue(message: message, severity: ValidationSeverity.error),
      ]);
    }

    return ValidationResult.valid();
  }
}

class CompositeValidator extends TextFieldValidator {
  final List<TextFieldValidator> validators;
  final bool stopOnFirstError;

  CompositeValidator({required this.validators, this.stopOnFirstError = true});

  @override
  String get name => 'composite';

  @override
  ValidationResult validate(String text) {
    final allErrors = <ValidationIssue>[];

    for (final validator in validators) {
      final result = validator.validate(text);
      if (!result.isValid) {
        allErrors.addAll(result.issues);
        if (stopOnFirstError) {
          break;
        }
      }
    }

    if (allErrors.isNotEmpty) {
      return ValidationResult.invalid(allErrors);
    }

    return ValidationResult.valid();
  }
}

class ValidationUtils {
  static List<TextFieldValidator> forEmail() => [
    RequiredValidator(),
    EmailValidator(),
  ];

  static List<TextFieldValidator> forPassword() => [
    RequiredValidator(),
    PasswordValidator(),
  ];

  static List<TextFieldValidator> forPhone() => [
    RequiredValidator(),
    PhoneValidator(),
  ];

  static List<TextFieldValidator> forName() => [
    RequiredValidator(),
    MinLengthValidator(2, customMessage: 'Name must be at least 2 characters'),
  ];

  static Map<String, ValidationResult> validateFields(
    Map<String, String> fieldValues,
    Map<String, List<TextFieldValidator>> fieldValidators,
  ) {
    final results = <String, ValidationResult>{};

    for (final entry in fieldValues.entries) {
      final fieldName = entry.key;
      final value = entry.value;
      final validators = fieldValidators[fieldName] ?? [];

      if (validators.isNotEmpty) {
        final composite = CompositeValidator(validators: validators);
        results[fieldName] = composite.validate(value);
      } else {
        results[fieldName] = ValidationResult.valid();
      }
    }

    return results;
  }

  static bool areAllValid(Map<String, ValidationResult> results) {
    return results.values.every((result) => result.isValid);
  }

  static List<String> getAllErrorMessages(
    Map<String, ValidationResult> results,
  ) {
    final messages = <String>[];
    for (final result in results.values) {
      if (!result.isValid) {
        messages.addAll(result.issues.map((e) => e.message));
      }
    }
    return messages;
  }
}
