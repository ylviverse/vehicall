import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          return 'Invalid request. Please check your input.';
        case '401':
          return 'Invalid credentials. Please try again.';
        case '422':
          return 'Email already registered or invalid format.';
        case '429':
          return 'Too many requests. Please try again later.';
        default:
          return error.message;
      }
    } else if (error is PostgrestException) {
      return 'Database error. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
