import 'package:VehiCall/config/app_config.dart';

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < AppConfig.minPasswordLength) {
      return 'Password must be at least ${AppConfig.minPasswordLength} characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < AppConfig.minNameLength) {
      return 'Name must be at least ${AppConfig.minNameLength} characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  static String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a message';
    }
    if (value.length > AppConfig.maxMessageLength) {
      return 'Message must be less than ${AppConfig.maxMessageLength} characters';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a description';
    }
    if (value.length > AppConfig.maxDescriptionLength) {
      return 'Description must be less than ${AppConfig.maxDescriptionLength} characters';
    }
    return null;
  }
}
