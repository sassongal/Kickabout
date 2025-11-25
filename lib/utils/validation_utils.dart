import 'package:flutter/services.dart';

/// Validation utilities for forms and user input
class ValidationUtils {
  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'נא להזין אימייל';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'נא להזין אימייל תקין';
    }

    return null;
  }

  /// Validate Israeli phone number
  static String? validatePhone(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) {
        return 'נא להזין מספר טלפון';
      }
      return null; // Phone is optional
    }

    // Remove spaces and dashes
    final cleanPhone = value.trim().replaceAll(RegExp(r'[-\s]'), '');

    // Israeli phone number regex: 0[2-9] followed by 7-8 digits
    final phoneRegex = RegExp(r'^0[2-9]\d{7,8}$');

    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'נא להזין מספר טלפון תקין (ישראל)';
    }

    return null;
  }

  /// Validate name (Hebrew/English, 2-50 characters)
  static String? validateName(String? value, {String fieldName = 'שם'}) {
    var error = validateRequired(value, fieldName: fieldName);
    if (error != null) return error;

    error = validateMinLength(value, 2, fieldName: fieldName);
    if (error != null) return error;

    error = validateMaxLength(value, 50, fieldName: fieldName);
    if (error != null) return error;

    // Allow letters (English and Hebrew), numbers, spaces, and specific punctuation.
    final nameRegex = RegExp('^[a-zA-Z0-9\\s\\-\\.\\\'\u0590-\u05FF]+\$');
    if (!nameRegex.hasMatch(value!.trim())) {
      return '$fieldName מכיל תווים לא תקינים';
    }

    return null;
  }

  /// Validate city name
  static String? validateCity(String? value) {
    var error = validateRequired(value, fieldName: 'עיר');
    if (error != null) return error;

    error = validateMinLength(value, 2, fieldName: 'שם העיר');
    if (error != null) return error;

    error = validateMaxLength(value, 50, fieldName: 'שם העיר');
    if (error != null) return error;

    return null;
  }

  /// Validate rating (0.0 - 10.0)
  static String? validateRating(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'נא להזין דירוג';
    }

    final rating = double.tryParse(value.trim());

    if (rating == null) {
      return 'נא להזין מספר תקין';
    }

    if (rating < 0.0 || rating > 10.0) {
      return 'דירוג חייב להיות בין 0 ל-10';
    }

    return null;
  }

  /// Validate non-empty text
  static String? validateRequired(String? value,
      {String fieldName = 'שדה זה'}) {
    if (value == null || value.trim().isEmpty) {
      return 'נא למלא $fieldName';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(
    String? value,
    int minLength, {
    String fieldName = 'שדה זה',
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'נא למלא $fieldName';
    }

    if (value.trim().length < minLength) {
      return '$fieldName חייב להכיל לפחות $minLength תווים';
    }

    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String fieldName = 'שדה זה',
  }) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName לא יכול להכיל יותר מ-$maxLength תווים';
    }
    return null;
  }

  /// Sanitize text input (remove dangerous characters)
  static String sanitizeText(String text) {
    // Remove null bytes and control characters
    // Collapse multiple spaces into a single space
    return text
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(
            RegExp(r'\s+'), ' ') // Collapse multiple whitespace to single space
        .trim();
  }

  /// Sanitize HTML content (basic)
  static String sanitizeHtml(String html) {
    // Remove script tags and dangerous HTML
    return html
        .replaceAll(
            RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
  }

  /// Format phone number for display
  static String formatPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[-\s]'), '');
    if (clean.length == 10) {
      return '${clean.substring(0, 3)}-${clean.substring(3, 6)}-${clean.substring(6)}';
    }
    return phone;
  }

  /// Input formatters
  static List<TextInputFormatter> phoneInputFormatter() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9\-\s]')),
      LengthLimitingTextInputFormatter(13), // 0XX-XXX-XXXX
    ];
  }

  static List<TextInputFormatter> nameInputFormatter() {
    return [
      // Allow letters (English and Hebrew), numbers, spaces, and specific punctuation.
      FilteringTextInputFormatter.allow(
          RegExp('^[a-zA-Z0-9\\s\\-\\.\\\'\u0590-\u05FF]')),
      LengthLimitingTextInputFormatter(50),
    ];
  }

  static List<TextInputFormatter> cityInputFormatter() {
    return [
      // Allow letters (including Hebrew), spaces, and hyphens.
      FilteringTextInputFormatter.allow(RegExp(r'[\p{L}\s\-]', unicode: true)),
      LengthLimitingTextInputFormatter(50),
    ];
  }
}
