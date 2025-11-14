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
    if (value == null || value.trim().isEmpty) {
      return 'נא להזין $fieldName';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return '$fieldName חייב להכיל לפחות 2 תווים';
    }

    if (trimmed.length > 50) {
      return '$fieldName לא יכול להכיל יותר מ-50 תווים';
    }

    // Allow Hebrew, English, numbers, spaces, and common punctuation
    // Check if contains only valid characters
    final hasInvalidChars = trimmed.split('').any((char) {
      final code = char.codeUnitAt(0);
      final isHebrew = (code >= 0x0590 && code <= 0x05FF);
      final isEnglish = (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
      final isNumber = (code >= 0x30 && code <= 0x39);
      final isSpace = code == 0x20;
      final isPunctuation = ['-', '.', '\''].contains(char);
      return !isHebrew && !isEnglish && !isNumber && !isSpace && !isPunctuation;
    });
    
    if (hasInvalidChars) {
      return '$fieldName מכיל תווים לא תקינים';
    }

    return null;
  }

  /// Validate city name
  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'נא להזין עיר';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'שם העיר חייב להכיל לפחות 2 תווים';
    }

    if (trimmed.length > 50) {
      return 'שם העיר לא יכול להכיל יותר מ-50 תווים';
    }

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
  static String? validateRequired(String? value, {String fieldName = 'שדה זה'}) {
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
    return text
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();
  }

  /// Sanitize HTML content (basic)
  static String sanitizeHtml(String html) {
    // Remove script tags and dangerous HTML
    return html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false), '')
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
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-\.]')),
      LengthLimitingTextInputFormatter(50),
    ];
  }

  static List<TextInputFormatter> cityInputFormatter() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]')),
      LengthLimitingTextInputFormatter(50),
    ];
  }
}

