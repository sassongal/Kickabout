/// A collection of constant error messages used throughout the app.
class ErrorMessages {
  static const String unknownError =
      'An unknown error occurred. Please try again.';
  static const String networkError =
      'A network error occurred. Please check your connection and try again.';
  static const String permissionError =
      'Permission denied. Please grant the necessary permissions in your device settings.';
  static const String authError =
      'Authentication error. Please sign out and sign in again.';
  static const String serverError =
      'A server error occurred. Please try again later.';
  static const String invalidInput =
      'Invalid input. Please check the fields and try again.';
  static const String notFound = 'The requested item was not found.';
}

/// Hebrew error messages for RTL UI
class HebrewErrorMessages {
  static const String unknownError = 'אירעה שגיאה לא ידועה. נסה שוב.';
  static const String networkError =
      'אירעה שגיאת רשת. בדוק את החיבור לאינטרנט ונסה שוב.';
  static const String permissionError =
      'הגישה נדחתה. נא לאשר את ההרשאות הנדרשות בהגדרות המכשיר.';
  static const String authError = 'שגיאת אימות. נא להתנתק ולהתחבר מחדש.';
  static const String serverError = 'אירעה שגיאת שרת. נסה שוב מאוחר יותר.';
  static const String invalidInput = 'קלט לא תקין. בדוק את השדות ונסה שוב.';
  static const String notFound = 'הפריט המבוקש לא נמצא.';
}

/// Maps Firebase error codes to user-friendly Hebrew messages.
///
/// Use this to translate cryptic Firebase errors into readable Hebrew.
/// Example:
/// ```dart
/// try {
///   await firestore.doc('path').get();
/// } catch (e) {
///   if (e is FirebaseException) {
///     final message = FirebaseErrorMapper.toHebrewMessage(e.code);
///     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
///   }
/// }
/// ```
class FirebaseErrorMapper {
  /// Convert Firebase error code to user-friendly Hebrew message
  static String toHebrewMessage(String code) {
    return switch (code) {
      // Permission errors
      'permission-denied' => 'אין לך הרשאה לבצע פעולה זו',
      'unauthorized' => 'נא להתחבר כדי לבצע פעולה זו',

      // Document errors
      'not-found' => 'הפריט לא נמצא',
      'already-exists' => 'הפריט כבר קיים',
      'failed-precondition' => 'לא ניתן לבצע את הפעולה במצב הנוכחי',
      'aborted' => 'הפעולה בוטלה עקב התנגשות, נסה שוב',

      // Network/availability errors
      'unavailable' => 'השירות לא זמין כרגע, נסה שוב מאוחר יותר',
      'deadline-exceeded' => 'הפעולה לקחה יותר מדי זמן, נסה שוב',
      'cancelled' => 'הפעולה בוטלה',

      // Authentication errors
      'unauthenticated' => 'נא להתחבר מחדש',
      'invalid-argument' => 'הנתונים שהוזנו אינם תקינים',

      // Quota/limit errors
      'resource-exhausted' => 'חרגת ממגבלת השימוש, נסה מאוחר יותר',

      // Data errors
      'data-loss' => 'חלק מהנתונים אבדו, פנה לתמיכה',
      'internal' => 'שגיאה פנימית, נסה שוב',

      // Default fallback
      _ => 'אירעה שגיאה, נסה שוב',
    };
  }

  /// Convert Firebase error code to English message
  static String toEnglishMessage(String code) {
    return switch (code) {
      'permission-denied' =>
        'You don\'t have permission to perform this action',
      'not-found' => 'The requested item was not found',
      'already-exists' => 'This item already exists',
      'unavailable' => 'Service unavailable, please try again later',
      'deadline-exceeded' => 'Request timed out, please try again',
      'cancelled' => 'Operation was cancelled',
      'unauthenticated' => 'Please sign in again',
      'invalid-argument' => 'Invalid input provided',
      _ => 'An error occurred, please try again',
    };
  }
}
