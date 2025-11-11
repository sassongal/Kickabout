import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he')
  ];

  /// שם האפליקציה
  ///
  /// In he, this message translates to:
  /// **'קיקאבוט'**
  String get appName;

  /// הודעת ברכה
  ///
  /// In he, this message translates to:
  /// **'ברוכים הבאים'**
  String get welcome;

  /// כפתור התחברות
  ///
  /// In he, this message translates to:
  /// **'התחבר'**
  String get login;

  /// כפתור הרשמה
  ///
  /// In he, this message translates to:
  /// **'הרשם'**
  String get register;

  /// שדה אימייל
  ///
  /// In he, this message translates to:
  /// **'אימייל'**
  String get email;

  /// שדה סיסמה
  ///
  /// In he, this message translates to:
  /// **'סיסמה'**
  String get password;

  /// שדה שם
  ///
  /// In he, this message translates to:
  /// **'שם'**
  String get name;

  /// שדה מספר טלפון
  ///
  /// In he, this message translates to:
  /// **'מספר טלפון'**
  String get phoneNumber;

  /// כותרת דף בית
  ///
  /// In he, this message translates to:
  /// **'בית'**
  String get home;

  /// כותרת שחקנים
  ///
  /// In he, this message translates to:
  /// **'שחקנים'**
  String get players;

  /// כותרת משחקים
  ///
  /// In he, this message translates to:
  /// **'משחקים'**
  String get games;

  /// כותרת הובס
  ///
  /// In he, this message translates to:
  /// **'הובס'**
  String get hubs;

  /// כפתור צור משחק
  ///
  /// In he, this message translates to:
  /// **'צור משחק'**
  String get createGame;

  /// כפתור צור הוב
  ///
  /// In he, this message translates to:
  /// **'צור הוב'**
  String get createHub;

  /// כותרת יצירת קבוצות
  ///
  /// In he, this message translates to:
  /// **'יצירת קבוצות'**
  String get teamFormation;

  /// כותרת סטטיסטיקות
  ///
  /// In he, this message translates to:
  /// **'סטטיסטיקות'**
  String get stats;

  /// כותרת פרופיל
  ///
  /// In he, this message translates to:
  /// **'פרופיל'**
  String get profile;

  /// כפתור שיתוף
  ///
  /// In he, this message translates to:
  /// **'שתף'**
  String get share;

  /// כפתור שמירה
  ///
  /// In he, this message translates to:
  /// **'שמור'**
  String get save;

  /// כפתור ביטול
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get cancel;

  /// כפתור מחיקה
  ///
  /// In he, this message translates to:
  /// **'מחק'**
  String get delete;

  /// כפתור עריכה
  ///
  /// In he, this message translates to:
  /// **'ערוך'**
  String get edit;

  /// הודעת טעינה
  ///
  /// In he, this message translates to:
  /// **'טוען...'**
  String get loading;

  /// כותרת שגיאה
  ///
  /// In he, this message translates to:
  /// **'שגיאה'**
  String get error;

  /// כותרת הצלחה
  ///
  /// In he, this message translates to:
  /// **'הצלחה'**
  String get success;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
