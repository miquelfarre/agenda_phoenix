import 'package:flutter/material.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';

/// Utility class for parsing API errors into user-friendly messages
///
/// Centralizes error message logic used across multiple screens
class ErrorMessageParser {
  /// Parse error into localized user-friendly message
  ///
  /// Handles common error patterns:
  /// - Network errors (socket, connection)
  /// - Timeout errors
  /// - HTTP status codes (401, 403, 404, 409, 500)
  /// - Generic fallback
  static String parse(dynamic error, BuildContext context) {
    final errorStr = error.toString().toLowerCase();
    final l10n = context.l10n;

    // Network errors
    if (errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return l10n.noInternetCheckNetwork;
    }

    // Timeout errors
    if (errorStr.contains('timeout')) {
      return l10n.requestTimedOut;
    }

    // Server errors (500)
    if (errorStr.contains('500') || errorStr.contains('server error')) {
      return l10n.serverError;
    }

    // Unauthorized (401)
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return l10n.sessionExpired;
    }

    // Forbidden (403)
    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return l10n.noPermission;
    }

    // Not found (404)
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return l10n.calendarNotFound;
    }

    // Conflict (409)
    if (errorStr.contains('conflict') || errorStr.contains('409')) {
      return l10n.failedToCreateCalendar;
    }

    // Generic fallback
    return l10n.failedToLoadCalendar;
  }

  /// Parse calendar-specific errors
  static String parseCalendarError(dynamic error, BuildContext context, String operation) {
    final l10n = context.l10n;
    final parsed = parse(error, context);

    // Return specific message if it's a known error
    if (parsed != l10n.failedToLoadCalendar) {
      return parsed;
    }

    // Return operation-specific message for unknown errors
    // Note: Using generic error message since specific calendar errors
    // don't have translations yet. Can be expanded in future.
    return l10n.error;
  }
}
