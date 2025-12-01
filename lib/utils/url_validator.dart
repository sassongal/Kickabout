/// Utility functions for validating and cleaning social media URLs
class UrlValidator {
  /// Validates if a URL is a valid Facebook profile URL
  static bool isValidFacebookUrl(String url) {
    if (url.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('facebook.com') || 
           lowerUrl.contains('fb.com') ||
           lowerUrl.contains('m.facebook.com');
  }

  /// Validates if a URL is a valid Instagram profile URL
  static bool isValidInstagramUrl(String url) {
    if (url.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('instagram.com') || 
           lowerUrl.contains('instagr.am');
  }

  /// Cleans and normalizes a URL
  /// - Adds https:// if no protocol is present
  /// - Removes trailing slashes
  /// - Trims whitespace
  static String cleanUrl(String url) {
    if (url.isEmpty) return url;
    
    var cleaned = url.trim();
    
    // Remove trailing slashes
    cleaned = cleaned.replaceAll(RegExp(r'/+$'), '');
    
    // Add https:// if no protocol is present
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }
    
    return cleaned;
  }

  /// Validates and cleans a Facebook URL
  /// Returns null if invalid, cleaned URL if valid
  static String? validateAndCleanFacebookUrl(String url) {
    if (url.isEmpty) return null;
    final cleaned = cleanUrl(url);
    if (isValidFacebookUrl(cleaned)) {
      return cleaned;
    }
    return null;
  }

  /// Validates and cleans an Instagram URL
  /// Returns null if invalid, cleaned URL if valid
  static String? validateAndCleanInstagramUrl(String url) {
    if (url.isEmpty) return null;
    final cleaned = cleanUrl(url);
    if (isValidInstagramUrl(cleaned)) {
      return cleaned;
    }
    return null;
  }

  /// Gets error message for invalid Facebook URL
  static String getFacebookUrlErrorMessage() {
    return 'כתובת פייסבוק לא תקינה. אנא הזן כתובת תקינה (לדוגמה: facebook.com/username)';
  }

  /// Gets error message for invalid Instagram URL
  static String getInstagramUrlErrorMessage() {
    return 'כתובת אינסטגרם לא תקינה. אנא הזן כתובת תקינה (לדוגמה: instagram.com/username)';
  }
}

