// lib/utils/error_handler.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ErrorType { info, warning, error, success }

class ErrorHandler {
  /// Call this to show any error — it automatically formats FirebaseAuth errors
  static void show(
      BuildContext context,
      dynamic error, {
        ErrorType type = ErrorType.error,
      }) {
    final message = _mapErrorToMessage(error);

    Color backgroundColor;

    switch (type) {
      case ErrorType.info:
        backgroundColor = Colors.blue;
        break;
      case ErrorType.warning:
        backgroundColor = Colors.orange;
        break;
      case ErrorType.success:
        backgroundColor = Colors.green;
        break;
      case ErrorType.error:
      default:
        backgroundColor = Colors.red;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Internal: maps FirebaseAuth errors to readable messages
  static String _mapErrorToMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Your password is too weak. Please choose a stronger one.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'operation-not-allowed':
          return 'Email/password sign up is disabled. Please contact support.';
      // Sign in errors
        case 'invalid-credential':
        case 'wrong-password':
          return 'Invalid email or password. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
