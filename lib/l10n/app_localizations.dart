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
  /// **'קיקאדור'**
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

  /// No description provided for @locationPermissionError.
  ///
  /// In he, this message translates to:
  /// **'אין הרשאת מיקום'**
  String get locationPermissionError;

  /// No description provided for @pleaseLogin.
  ///
  /// In he, this message translates to:
  /// **'נא להתחבר'**
  String get pleaseLogin;

  /// No description provided for @guestsCannotCreateHubs.
  ///
  /// In he, this message translates to:
  /// **'אורחים לא יכולים ליצור הובים. נא להתחבר או להירשם.'**
  String get guestsCannotCreateHubs;

  /// No description provided for @hubCreatedSuccess.
  ///
  /// In he, this message translates to:
  /// **'ההוב נוצר בהצלחה!'**
  String get hubCreatedSuccess;

  /// No description provided for @hubCreationError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה ביצירת הוב'**
  String get hubCreationError;

  /// No description provided for @hubCreationPermissionError.
  ///
  /// In he, this message translates to:
  /// **'אין לך הרשאה ליצור הוב.'**
  String get hubCreationPermissionError;

  /// No description provided for @pleaseReLogin.
  ///
  /// In he, this message translates to:
  /// **'נא להתחבר מחדש'**
  String get pleaseReLogin;

  /// No description provided for @hubCreationErrorDetails.
  ///
  /// In he, this message translates to:
  /// **'שגיאה ביצירת הוב: {error}'**
  String hubCreationErrorDetails(String error);

  /// No description provided for @createHubTitle.
  ///
  /// In he, this message translates to:
  /// **'צור הוב'**
  String get createHubTitle;

  /// No description provided for @hubNameLabel.
  ///
  /// In he, this message translates to:
  /// **'שם ההוב'**
  String get hubNameLabel;

  /// No description provided for @hubNameHint.
  ///
  /// In he, this message translates to:
  /// **'הכנס שם להוב'**
  String get hubNameHint;

  /// No description provided for @hubNameValidator.
  ///
  /// In he, this message translates to:
  /// **'נא להכניס שם'**
  String get hubNameValidator;

  /// No description provided for @hubDescriptionLabel.
  ///
  /// In he, this message translates to:
  /// **'תיאור (אופציונלי)'**
  String get hubDescriptionLabel;

  /// No description provided for @hubDescriptionHint.
  ///
  /// In he, this message translates to:
  /// **'הכנס תיאור להוב'**
  String get hubDescriptionHint;

  /// No description provided for @regionLabel.
  ///
  /// In he, this message translates to:
  /// **'אזור'**
  String get regionLabel;

  /// No description provided for @regionHint.
  ///
  /// In he, this message translates to:
  /// **'בחר אזור'**
  String get regionHint;

  /// No description provided for @regionHelperText.
  ///
  /// In he, this message translates to:
  /// **'משפיע על הפיד האזורי'**
  String get regionHelperText;

  /// No description provided for @regionNorth.
  ///
  /// In he, this message translates to:
  /// **'צפון'**
  String get regionNorth;

  /// No description provided for @regionCenter.
  ///
  /// In he, this message translates to:
  /// **'מרכז'**
  String get regionCenter;

  /// No description provided for @regionSouth.
  ///
  /// In he, this message translates to:
  /// **'דרום'**
  String get regionSouth;

  /// No description provided for @regionJerusalem.
  ///
  /// In he, this message translates to:
  /// **'ירושלים'**
  String get regionJerusalem;

  /// No description provided for @venuesOptionalLabel.
  ///
  /// In he, this message translates to:
  /// **'מגרשים (אופציונלי)'**
  String get venuesOptionalLabel;

  /// No description provided for @venuesAddLaterInfo.
  ///
  /// In he, this message translates to:
  /// **'תוכל להוסיף מגרשים מאוחר יותר בהגדרות ההוב'**
  String get venuesAddLaterInfo;

  /// No description provided for @venuesAddAfterCreationInfo.
  ///
  /// In he, this message translates to:
  /// **'תוכל להוסיף מגרשים לאחר יצירת ההוב'**
  String get venuesAddAfterCreationInfo;

  /// No description provided for @addVenuesButton.
  ///
  /// In he, this message translates to:
  /// **'הוסף מגרשים'**
  String get addVenuesButton;

  /// No description provided for @locationOptionalLabel.
  ///
  /// In he, this message translates to:
  /// **'מיקום (אופציונלי)'**
  String get locationOptionalLabel;

  /// No description provided for @gettingLocation.
  ///
  /// In he, this message translates to:
  /// **'מקבל מיקום...'**
  String get gettingLocation;

  /// No description provided for @currentLocation.
  ///
  /// In he, this message translates to:
  /// **'מיקום נוכחי'**
  String get currentLocation;

  /// No description provided for @selectOnMap.
  ///
  /// In he, this message translates to:
  /// **'בחר במפה'**
  String get selectOnMap;

  /// No description provided for @creating.
  ///
  /// In he, this message translates to:
  /// **'יוצר...'**
  String get creating;

  /// No description provided for @errorMissingHubId.
  ///
  /// In he, this message translates to:
  /// **'שגיאה: מזהה הוב חסר'**
  String get errorMissingHubId;

  /// No description provided for @eventNotFound.
  ///
  /// In he, this message translates to:
  /// **'אירוע לא נמצא'**
  String get eventNotFound;

  /// No description provided for @gameNotFound.
  ///
  /// In he, this message translates to:
  /// **'משחק לא נמצא'**
  String get gameNotFound;

  /// No description provided for @noAdminPermissionForScreen.
  ///
  /// In he, this message translates to:
  /// **'אין לך הרשאת ניהול למסך זה'**
  String get noAdminPermissionForScreen;

  /// No description provided for @onlyHubAdminsCanCreateTeams.
  ///
  /// In he, this message translates to:
  /// **'רק מנהלי הוב יכולים ליצור קבוצות'**
  String get onlyHubAdminsCanCreateTeams;

  /// No description provided for @notEnoughRegisteredPlayers.
  ///
  /// In he, this message translates to:
  /// **'אין מספיק נרשמים'**
  String get notEnoughRegisteredPlayers;

  /// No description provided for @requiredPlayersCount.
  ///
  /// In he, this message translates to:
  /// **'נדרשים לפחות {count} שחקנים'**
  String requiredPlayersCount(int count);

  /// No description provided for @registeredPlayerCount.
  ///
  /// In he, this message translates to:
  /// **'נרשמו: {count}'**
  String registeredPlayerCount(int count);

  /// No description provided for @permissionCheckErrorDetails.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בבדיקת הרשאות: {error}'**
  String permissionCheckErrorDetails(String error);

  /// No description provided for @hubSettingsTitle.
  ///
  /// In he, this message translates to:
  /// **'הגדרות הוב'**
  String get hubSettingsTitle;

  /// No description provided for @loadingSettings.
  ///
  /// In he, this message translates to:
  /// **'טוען הגדרות...'**
  String get loadingSettings;

  /// No description provided for @hubNotFound.
  ///
  /// In he, this message translates to:
  /// **'הוב לא נמצא'**
  String get hubNotFound;

  /// No description provided for @tryAgain.
  ///
  /// In he, this message translates to:
  /// **'נסה שוב'**
  String get tryAgain;

  /// No description provided for @ratingMode.
  ///
  /// In he, this message translates to:
  /// **'מצב דירוג'**
  String get ratingMode;

  /// No description provided for @advancedRating.
  ///
  /// In he, this message translates to:
  /// **'מתקדם'**
  String get advancedRating;

  /// No description provided for @basicRating.
  ///
  /// In he, this message translates to:
  /// **'בסיסי'**
  String get basicRating;

  /// No description provided for @basicRatingDescription.
  ///
  /// In he, this message translates to:
  /// **'דירוג פשוט 1-10'**
  String get basicRatingDescription;

  /// No description provided for @advancedRatingDescription.
  ///
  /// In he, this message translates to:
  /// **'תכונות מפורטות (מהירות, בעיטה וכו\')'**
  String get advancedRatingDescription;

  /// No description provided for @privacySettings.
  ///
  /// In he, this message translates to:
  /// **'פרטיות'**
  String get privacySettings;

  /// No description provided for @privateHub.
  ///
  /// In he, this message translates to:
  /// **'פרטי'**
  String get privateHub;

  /// No description provided for @publicHub.
  ///
  /// In he, this message translates to:
  /// **'ציבורי'**
  String get publicHub;

  /// No description provided for @publicHubDescription.
  ///
  /// In he, this message translates to:
  /// **'גלוי לכולם'**
  String get publicHubDescription;

  /// No description provided for @privateHubDescription.
  ///
  /// In he, this message translates to:
  /// **'הזמנה בלבד'**
  String get privateHubDescription;

  /// No description provided for @joinMode.
  ///
  /// In he, this message translates to:
  /// **'מצב הצטרפות'**
  String get joinMode;

  /// No description provided for @approvalRequired.
  ///
  /// In he, this message translates to:
  /// **'נדרש אישור'**
  String get approvalRequired;

  /// No description provided for @autoJoin.
  ///
  /// In he, this message translates to:
  /// **'הצטרפות אוטומטית'**
  String get autoJoin;

  /// No description provided for @autoJoinDescription.
  ///
  /// In he, this message translates to:
  /// **'כל אחד יכול להצטרף מיידית'**
  String get autoJoinDescription;

  /// No description provided for @approvalRequiredDescription.
  ///
  /// In he, this message translates to:
  /// **'מנהלים חייבים לאשר בקשות'**
  String get approvalRequiredDescription;

  /// No description provided for @notifications.
  ///
  /// In he, this message translates to:
  /// **'התראות'**
  String get notifications;

  /// No description provided for @notificationsDescription.
  ///
  /// In he, this message translates to:
  /// **'אפשר התראות הוב'**
  String get notificationsDescription;

  /// No description provided for @hubChat.
  ///
  /// In he, this message translates to:
  /// **'צ\'אט הוב'**
  String get hubChat;

  /// No description provided for @hubChatDescription.
  ///
  /// In he, this message translates to:
  /// **'אפשר צ\'אט לחברים'**
  String get hubChatDescription;

  /// No description provided for @activityFeed.
  ///
  /// In he, this message translates to:
  /// **'פיד פעילות'**
  String get activityFeed;

  /// No description provided for @activityFeedDescription.
  ///
  /// In he, this message translates to:
  /// **'הצג פעילות חברים'**
  String get activityFeedDescription;

  /// No description provided for @manageVenues.
  ///
  /// In he, this message translates to:
  /// **'ניהול מגרשים'**
  String get manageVenues;

  /// No description provided for @manageVenuesDescription.
  ///
  /// In he, this message translates to:
  /// **'הוסף או הסר מגרשי משחק'**
  String get manageVenuesDescription;

  /// No description provided for @hubRules.
  ///
  /// In he, this message translates to:
  /// **'חוקי ההוב'**
  String get hubRules;

  /// No description provided for @characterCount.
  ///
  /// In he, this message translates to:
  /// **'{count} תווים'**
  String characterCount(int count);

  /// No description provided for @noRulesDefined.
  ///
  /// In he, this message translates to:
  /// **'לא הוגדרו חוקים'**
  String get noRulesDefined;

  /// No description provided for @paymentLinkLabel.
  ///
  /// In he, this message translates to:
  /// **'קישור לתשלום'**
  String get paymentLinkLabel;

  /// No description provided for @defined.
  ///
  /// In he, this message translates to:
  /// **'מוגדר'**
  String get defined;

  /// No description provided for @notDefined.
  ///
  /// In he, this message translates to:
  /// **'לא מוגדר'**
  String get notDefined;

  /// No description provided for @hubInvitations.
  ///
  /// In he, this message translates to:
  /// **'הזמנות'**
  String get hubInvitations;

  /// No description provided for @hubInvitationsDescription.
  ///
  /// In he, this message translates to:
  /// **'ניהול הזמנות ממתינות'**
  String get hubInvitationsDescription;

  /// No description provided for @checkingPermissions.
  ///
  /// In he, this message translates to:
  /// **'בודק הרשאות...'**
  String get checkingPermissions;

  /// No description provided for @permissionCheckError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בבדיקת הרשאות'**
  String get permissionCheckError;

  /// No description provided for @settingUpdatedSuccess.
  ///
  /// In he, this message translates to:
  /// **'הגדרה עודכנה בהצלחה'**
  String get settingUpdatedSuccess;

  /// No description provided for @settingUpdateError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בעדכון הגדרה: {error}'**
  String settingUpdateError(String error);

  /// No description provided for @hubRulesSavedSuccess.
  ///
  /// In he, this message translates to:
  /// **'חוקים נשמרו בהצלחה'**
  String get hubRulesSavedSuccess;

  /// No description provided for @hubRulesSaveError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בשמירת חוקים: {error}'**
  String hubRulesSaveError(String error);

  /// No description provided for @hubRulesHint.
  ///
  /// In he, this message translates to:
  /// **'הכנס חוקי הוב כאן...'**
  String get hubRulesHint;

  /// No description provided for @hubRulesHelper.
  ///
  /// In he, this message translates to:
  /// **'גלוי לכל החברים'**
  String get hubRulesHelper;

  /// No description provided for @saving.
  ///
  /// In he, this message translates to:
  /// **'שומר...'**
  String get saving;

  /// No description provided for @saveRules.
  ///
  /// In he, this message translates to:
  /// **'שמור חוקים'**
  String get saveRules;

  /// No description provided for @paymentLinkSavedSuccess.
  ///
  /// In he, this message translates to:
  /// **'קישור לתשלום נשמר'**
  String get paymentLinkSavedSuccess;

  /// No description provided for @paymentLinkSaveError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בשמירת קישור: {error}'**
  String paymentLinkSaveError(String error);

  /// No description provided for @paymentLinkBitLabel.
  ///
  /// In he, this message translates to:
  /// **'קישור לתשלום (ביט/פייבוקס)'**
  String get paymentLinkBitLabel;

  /// No description provided for @paymentLinkHint.
  ///
  /// In he, this message translates to:
  /// **'https://...'**
  String get paymentLinkHint;

  /// No description provided for @paymentLinkHelper.
  ///
  /// In he, this message translates to:
  /// **'משמש לאיסוף כספי משחק'**
  String get paymentLinkHelper;

  /// No description provided for @saveLink.
  ///
  /// In he, this message translates to:
  /// **'שמור קישור'**
  String get saveLink;

  /// No description provided for @onlyHubAdminsCanChangeSettings.
  ///
  /// In he, this message translates to:
  /// **'רק מנהלי הוב יכולים לשנות הגדרות'**
  String get onlyHubAdminsCanChangeSettings;

  /// No description provided for @playerDetailsUpdatedSuccess.
  ///
  /// In he, this message translates to:
  /// **'פרטי השחקן עודכנו בהצלחה'**
  String get playerDetailsUpdatedSuccess;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In he, this message translates to:
  /// **'נא להזין כתובת אימייל תקינה'**
  String get pleaseEnterValidEmail;

  /// No description provided for @hubInvitationEmailSubject.
  ///
  /// In he, this message translates to:
  /// **'הזמנה להצטרף ל-{hubName} ב-Kattrick'**
  String hubInvitationEmailSubject(String hubName);

  /// No description provided for @hubInvitationEmailBody.
  ///
  /// In he, this message translates to:
  /// **'היי!\n\n{playerName} הזמין אותך להצטרף ל-{hubName} ב-Kattrick.\n\nלחץ על הקישור להצטרפות:\n{link}\n\nאו השתמש בקוד: {code}'**
  String hubInvitationEmailBody(
      String playerName, String hubName, String link, String code);

  /// No description provided for @emailClientOpened.
  ///
  /// In he, this message translates to:
  /// **'אפליקציית האימייל נפתחה'**
  String get emailClientOpened;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In he, this message translates to:
  /// **'הקישור הועתק ללוח'**
  String get linkCopiedToClipboard;

  /// No description provided for @editManualPlayerTitle.
  ///
  /// In he, this message translates to:
  /// **'עריכת שחקן'**
  String get editManualPlayerTitle;

  /// No description provided for @editManualPlayerSubtitle.
  ///
  /// In he, this message translates to:
  /// **'עדכון פרטים לשחקן ידני'**
  String get editManualPlayerSubtitle;

  /// No description provided for @fullNameRequired.
  ///
  /// In he, this message translates to:
  /// **'שם מלא *'**
  String get fullNameRequired;

  /// No description provided for @pleaseEnterName.
  ///
  /// In he, this message translates to:
  /// **'נא להזין שם'**
  String get pleaseEnterName;

  /// No description provided for @emailForInvitationLabel.
  ///
  /// In he, this message translates to:
  /// **'אימייל (להזמנה)'**
  String get emailForInvitationLabel;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In he, this message translates to:
  /// **'כתובת אימייל לא תקינה'**
  String get invalidEmailAddress;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In he, this message translates to:
  /// **'מספר טלפון'**
  String get phoneNumberLabel;

  /// No description provided for @cityLabel.
  ///
  /// In he, this message translates to:
  /// **'עיר'**
  String get cityLabel;

  /// No description provided for @ratingLabel.
  ///
  /// In he, this message translates to:
  /// **'דירוג (0-10)'**
  String get ratingLabel;

  /// No description provided for @ratingRangeError.
  ///
  /// In he, this message translates to:
  /// **'הדירוג חייב להיות בין 0 ל-10'**
  String get ratingRangeError;

  /// No description provided for @preferredPositionLabel.
  ///
  /// In he, this message translates to:
  /// **'עמדה מועדפת'**
  String get preferredPositionLabel;

  /// No description provided for @sendEmailInvitation.
  ///
  /// In he, this message translates to:
  /// **'שלח הזמנה במייל'**
  String get sendEmailInvitation;

  /// No description provided for @saveChanges.
  ///
  /// In he, this message translates to:
  /// **'שמור שינויים'**
  String get saveChanges;

  /// No description provided for @positionGoalkeeper.
  ///
  /// In he, this message translates to:
  /// **'שוער'**
  String get positionGoalkeeper;

  /// No description provided for @positionDefense.
  ///
  /// In he, this message translates to:
  /// **'הגנה'**
  String get positionDefense;

  /// No description provided for @positionMidfielder.
  ///
  /// In he, this message translates to:
  /// **'קישור'**
  String get positionMidfielder;

  /// No description provided for @positionForward.
  ///
  /// In he, this message translates to:
  /// **'התקפה'**
  String get positionForward;

  /// No description provided for @yourHubsTitle.
  ///
  /// In he, this message translates to:
  /// **'ההובים שלך'**
  String get yourHubsTitle;

  /// No description provided for @notificationsTooltip.
  ///
  /// In he, this message translates to:
  /// **'התראות'**
  String get notificationsTooltip;

  /// No description provided for @mapTooltip.
  ///
  /// In he, this message translates to:
  /// **'מפה'**
  String get mapTooltip;

  /// No description provided for @discoverHubsTooltip.
  ///
  /// In he, this message translates to:
  /// **'גלה הובים'**
  String get discoverHubsTooltip;

  /// No description provided for @backToHomeTooltip.
  ///
  /// In he, this message translates to:
  /// **'חזרה לבית'**
  String get backToHomeTooltip;

  /// No description provided for @errorLoadingHubs.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בטעינת הובים'**
  String get errorLoadingHubs;

  /// No description provided for @noHubs.
  ///
  /// In he, this message translates to:
  /// **'לא נמצאו הובים'**
  String get noHubs;

  /// No description provided for @createHubToStart.
  ///
  /// In he, this message translates to:
  /// **'צור הוב כדי להתחיל!'**
  String get createHubToStart;

  /// No description provided for @memberCount.
  ///
  /// In he, this message translates to:
  /// **'{count} חברים'**
  String memberCount(int count);

  /// No description provided for @hubNotFoundWithInviteCode.
  ///
  /// In he, this message translates to:
  /// **'לא נמצא הוב עם קוד הזמנה זה'**
  String get hubNotFoundWithInviteCode;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In he, this message translates to:
  /// **'נא להתחבר תחילה'**
  String get pleaseLoginFirst;

  /// No description provided for @hubInvitationsDisabled.
  ///
  /// In he, this message translates to:
  /// **'ההזמנות להוב זה מושבתות'**
  String get hubInvitationsDisabled;

  /// No description provided for @joinedHubSuccess.
  ///
  /// In he, this message translates to:
  /// **'הצטרפת בהצלחה ל-{hubName}'**
  String joinedHubSuccess(String hubName);

  /// No description provided for @joinRequestSent.
  ///
  /// In he, this message translates to:
  /// **'בקשת הצטרפות נשלחה בהצלחה'**
  String get joinRequestSent;

  /// No description provided for @joinHubError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בהצטרפות להוב: {error}'**
  String joinHubError(String error);

  /// No description provided for @joinHubTitle.
  ///
  /// In he, this message translates to:
  /// **'הצטרף להוב'**
  String get joinHubTitle;

  /// No description provided for @backToHome.
  ///
  /// In he, this message translates to:
  /// **'חזרה לבית'**
  String get backToHome;

  /// No description provided for @hubRequiresApproval.
  ///
  /// In he, this message translates to:
  /// **'הוב זה דורש אישור מנהל להצטרפות'**
  String get hubRequiresApproval;

  /// No description provided for @sendJoinRequest.
  ///
  /// In he, this message translates to:
  /// **'שלח בקשת הצטרפות'**
  String get sendJoinRequest;

  /// No description provided for @joinHubButton.
  ///
  /// In he, this message translates to:
  /// **'הצטרף להוב'**
  String get joinHubButton;

  /// Error message when status update fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה בעדכון סטטוס: {error}'**
  String statusUpdateError(String error);

  /// Notification when a join request is approved
  ///
  /// In he, this message translates to:
  /// **'בקשתך אושרה!'**
  String get requestApproved;

  /// Message when a game is postponed
  ///
  /// In he, this message translates to:
  /// **'המשחק נדחה'**
  String get gamePostponed;

  /// Message when a game is cancelled
  ///
  /// In he, this message translates to:
  /// **'המשחק בוטל'**
  String get gameCancelled;

  /// Message when a game is completed
  ///
  /// In he, this message translates to:
  /// **'המשחק הסתיים'**
  String get gameCompleted;

  /// Message when game signup is confirmed
  ///
  /// In he, this message translates to:
  /// **'ההרשמה אושרה!'**
  String get signupConfirmed;

  /// Message when game signup is cancelled
  ///
  /// In he, this message translates to:
  /// **'ההרשמה בוטלה'**
  String get signupCancelled;

  /// Success message for location update
  ///
  /// In he, this message translates to:
  /// **'המיקום עודכן בהצלחה'**
  String get locationUpdatedSuccess;

  /// Error message for location update failure
  ///
  /// In he, this message translates to:
  /// **'שגיאה בעדכון מיקום: {error}'**
  String locationUpdateError(String error);

  /// Generic permission denied message
  ///
  /// In he, this message translates to:
  /// **'אין לך הרשאה לבצע פעולה זו'**
  String get noPermissionForAction;

  /// Generic not found message
  ///
  /// In he, this message translates to:
  /// **'הפריט לא נמצא'**
  String get itemNotFound;

  /// Service unavailable error message
  ///
  /// In he, this message translates to:
  /// **'השירות לא זמין כרגע, נסה שוב מאוחר יותר'**
  String get serviceUnavailable;

  /// Message asking user to sign in again
  ///
  /// In he, this message translates to:
  /// **'נא להתחבר מחדש'**
  String get pleaseSignInAgain;

  /// Generic error message
  ///
  /// In he, this message translates to:
  /// **'אירעה שגיאה, נסה שוב'**
  String get genericError;

  /// Section title for upcoming games
  ///
  /// In he, this message translates to:
  /// **'משחקים קרובים'**
  String get upcomingGames;

  /// Link text to view all events
  ///
  /// In he, this message translates to:
  /// **'לכל האירועים'**
  String get toAllEvents;

  /// Admin console button label
  ///
  /// In he, this message translates to:
  /// **'לוח בקרה'**
  String get adminConsole;

  /// Generate dummy data button for dev mode
  ///
  /// In he, this message translates to:
  /// **'יצירת נתוני דמה (פיתוח)'**
  String get generateDummyData;

  /// Force location button for dev mode
  ///
  /// In he, this message translates to:
  /// **'כפה מיקום (פיתוח)'**
  String get forceLocation;

  /// No description provided for @gameDetailsTitle.
  ///
  /// In he, this message translates to:
  /// **'פרטי משחק'**
  String get gameDetailsTitle;

  /// No description provided for @gameLoadingMessage.
  ///
  /// In he, this message translates to:
  /// **'טוען משחק...'**
  String get gameLoadingMessage;

  /// No description provided for @gameLoadingError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בטעינת המשחק'**
  String get gameLoadingError;

  /// No description provided for @attendanceMonitoring.
  ///
  /// In he, this message translates to:
  /// **'ניטור הגעה'**
  String get attendanceMonitoring;

  /// No description provided for @locationNotSpecified.
  ///
  /// In he, this message translates to:
  /// **'מיקום לא צוין'**
  String get locationNotSpecified;

  /// No description provided for @teamCountLabel.
  ///
  /// In he, this message translates to:
  /// **'{count} קבוצות'**
  String teamCountLabel(Object count);

  /// No description provided for @signupsCount.
  ///
  /// In he, this message translates to:
  /// **'{count} נרשמו'**
  String signupsCount(Object count);

  /// No description provided for @signupsCountFull.
  ///
  /// In he, this message translates to:
  /// **'{count} נרשמו (מלא)'**
  String signupsCountFull(Object count);

  /// No description provided for @gameRulesTitle.
  ///
  /// In he, this message translates to:
  /// **'חוקי המשחק'**
  String get gameRulesTitle;

  /// No description provided for @gameDurationLabel.
  ///
  /// In he, this message translates to:
  /// **'משך: {minutes} דקות'**
  String gameDurationLabel(Object minutes);

  /// No description provided for @gameEndConditionLabel.
  ///
  /// In he, this message translates to:
  /// **'תנאי סיום: {condition}'**
  String gameEndConditionLabel(Object condition);

  /// No description provided for @statusApproved.
  ///
  /// In he, this message translates to:
  /// **'מאושר'**
  String get statusApproved;

  /// No description provided for @statusPending.
  ///
  /// In he, this message translates to:
  /// **'ממתין'**
  String get statusPending;

  /// No description provided for @removePlayerTooltip.
  ///
  /// In he, this message translates to:
  /// **'הסר שחקן'**
  String get removePlayerTooltip;

  /// No description provided for @signupRemovedSuccess.
  ///
  /// In he, this message translates to:
  /// **'הסרת הרשמה'**
  String get signupRemovedSuccess;

  /// No description provided for @signupSuccess.
  ///
  /// In he, this message translates to:
  /// **'נרשמת למשחק'**
  String get signupSuccess;

  /// No description provided for @onlyCreatorCanStartGame.
  ///
  /// In he, this message translates to:
  /// **'רק יוצר המשחק יכול להתחיל'**
  String get onlyCreatorCanStartGame;

  /// No description provided for @gameStartedSuccess.
  ///
  /// In he, this message translates to:
  /// **'המשחק התחיל'**
  String get gameStartedSuccess;

  /// No description provided for @onlyCreatorCanEndGame.
  ///
  /// In he, this message translates to:
  /// **'רק יוצר המשחק יכול לסיים'**
  String get onlyCreatorCanEndGame;

  /// No description provided for @gameEndedSuccess.
  ///
  /// In he, this message translates to:
  /// **'המשחק הסתיים'**
  String get gameEndedSuccess;

  /// No description provided for @gameStatusDraft.
  ///
  /// In he, this message translates to:
  /// **'טיוטה'**
  String get gameStatusDraft;

  /// No description provided for @gameStatusScheduled.
  ///
  /// In he, this message translates to:
  /// **'מתוכנן'**
  String get gameStatusScheduled;

  /// No description provided for @gameStatusRecruiting.
  ///
  /// In he, this message translates to:
  /// **'גיוס שחקנים'**
  String get gameStatusRecruiting;

  /// No description provided for @gameStatusTeamSelection.
  ///
  /// In he, this message translates to:
  /// **'בחירת קבוצות'**
  String get gameStatusTeamSelection;

  /// No description provided for @gameStatusTeamsFormed.
  ///
  /// In he, this message translates to:
  /// **'קבוצות נוצרו'**
  String get gameStatusTeamsFormed;

  /// No description provided for @gameStatusFull.
  ///
  /// In he, this message translates to:
  /// **'מלא'**
  String get gameStatusFull;

  /// No description provided for @gameStatusInProgress.
  ///
  /// In he, this message translates to:
  /// **'במהלך'**
  String get gameStatusInProgress;

  /// No description provided for @gameStatusCompleted.
  ///
  /// In he, this message translates to:
  /// **'הושלם'**
  String get gameStatusCompleted;

  /// No description provided for @gameStatusStatsInput.
  ///
  /// In he, this message translates to:
  /// **'הזנת סטטיסטיקות'**
  String get gameStatusStatsInput;

  /// No description provided for @gameStatusCancelled.
  ///
  /// In he, this message translates to:
  /// **'בוטל'**
  String get gameStatusCancelled;

  /// No description provided for @gameStatusArchivedNotPlayed.
  ///
  /// In he, this message translates to:
  /// **'ארכיון - לא שוחק'**
  String get gameStatusArchivedNotPlayed;

  /// No description provided for @playersLoadError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בטעינת שחקנים'**
  String get playersLoadError;

  /// No description provided for @targetingMismatchWarning.
  ///
  /// In he, this message translates to:
  /// **'שים לב: המשחק מיועד לגילאים {minAge}-{maxAge} {genderSuffix}'**
  String targetingMismatchWarning(
      Object minAge, Object maxAge, Object genderSuffix);

  /// No description provided for @genderMaleSuffix.
  ///
  /// In he, this message translates to:
  /// **'(גברים)'**
  String get genderMaleSuffix;

  /// No description provided for @genderFemaleSuffix.
  ///
  /// In he, this message translates to:
  /// **'(נשים)'**
  String get genderFemaleSuffix;

  /// No description provided for @gameChatButton.
  ///
  /// In he, this message translates to:
  /// **'צ\'אט משחק'**
  String get gameChatButton;

  /// No description provided for @requestToJoin.
  ///
  /// In he, this message translates to:
  /// **'בקש להצטרף'**
  String get requestToJoin;

  /// No description provided for @signupForGame.
  ///
  /// In he, this message translates to:
  /// **'הירשם למשחק'**
  String get signupForGame;

  /// No description provided for @requestSentPendingApproval.
  ///
  /// In he, this message translates to:
  /// **'בקשה נשלחה - ממתין לאישור'**
  String get requestSentPendingApproval;

  /// No description provided for @cancelSignup.
  ///
  /// In he, this message translates to:
  /// **'בטל הרשמה'**
  String get cancelSignup;

  /// No description provided for @gameFullWaitlist.
  ///
  /// In he, this message translates to:
  /// **'המשחק מלא - ניתן להירשם לרשימת המתנה'**
  String get gameFullWaitlist;

  /// No description provided for @pendingRequestsTitle.
  ///
  /// In he, this message translates to:
  /// **'בקשות ממתינות ({count})'**
  String pendingRequestsTitle(Object count);

  /// No description provided for @findMissingPlayers.
  ///
  /// In he, this message translates to:
  /// **'מצא שחקנים חסרים'**
  String get findMissingPlayers;

  /// No description provided for @createTeams.
  ///
  /// In he, this message translates to:
  /// **'צור קבוצות'**
  String get createTeams;

  /// No description provided for @logResultAndStats.
  ///
  /// In he, this message translates to:
  /// **'תעד תוצאה וסטטיסטיקות'**
  String get logResultAndStats;

  /// No description provided for @startGame.
  ///
  /// In he, this message translates to:
  /// **'התחל משחק'**
  String get startGame;

  /// No description provided for @recordStats.
  ///
  /// In he, this message translates to:
  /// **'רישום סטטיסטיקות'**
  String get recordStats;

  /// No description provided for @endGame.
  ///
  /// In he, this message translates to:
  /// **'סיים משחק'**
  String get endGame;

  /// No description provided for @editResult.
  ///
  /// In he, this message translates to:
  /// **'ערוך תוצאה'**
  String get editResult;

  /// No description provided for @viewFullStats.
  ///
  /// In he, this message translates to:
  /// **'צפה בסטטיסטיקות המלאות'**
  String get viewFullStats;

  /// No description provided for @signupsTitle.
  ///
  /// In he, this message translates to:
  /// **'נרשמים'**
  String get signupsTitle;

  /// No description provided for @confirmedSignupsTitle.
  ///
  /// In he, this message translates to:
  /// **'מאושרים ({count})'**
  String confirmedSignupsTitle(Object count);

  /// No description provided for @pendingSignupsTitle.
  ///
  /// In he, this message translates to:
  /// **'ממתינים ({count})'**
  String pendingSignupsTitle(Object count);

  /// No description provided for @noSignups.
  ///
  /// In he, this message translates to:
  /// **'אין נרשמים'**
  String get noSignups;

  /// No description provided for @requestedToJoinAt.
  ///
  /// In he, this message translates to:
  /// **'ביקש להצטרף • {time}'**
  String requestedToJoinAt(Object time);

  /// No description provided for @approveTooltip.
  ///
  /// In he, this message translates to:
  /// **'אשר'**
  String get approveTooltip;

  /// No description provided for @rejectTooltip.
  ///
  /// In he, this message translates to:
  /// **'דחה'**
  String get rejectTooltip;

  /// No description provided for @playerApprovedSuccess.
  ///
  /// In he, this message translates to:
  /// **'שחקן אושר בהצלחה'**
  String get playerApprovedSuccess;

  /// No description provided for @rejectRequestTitle.
  ///
  /// In he, this message translates to:
  /// **'דחיית בקשה'**
  String get rejectRequestTitle;

  /// No description provided for @rejectionReasonLabel.
  ///
  /// In he, this message translates to:
  /// **'סיבת הדחייה (חובה)'**
  String get rejectionReasonLabel;

  /// No description provided for @rejectionReasonHint.
  ///
  /// In he, this message translates to:
  /// **'לדוגמה: המשחק מלא, לא מתאים לרמה...'**
  String get rejectionReasonHint;

  /// No description provided for @rejectRequestButton.
  ///
  /// In he, this message translates to:
  /// **'דחה בקשה'**
  String get rejectRequestButton;

  /// No description provided for @requestRejectedSuccess.
  ///
  /// In he, this message translates to:
  /// **'בקשה נדחתה'**
  String get requestRejectedSuccess;

  /// No description provided for @findMissingPlayersDescription.
  ///
  /// In he, this message translates to:
  /// **'המשחק יהפוך ל-\"מגייס שחקנים\" ויוצג בפיד האזורי.\nנדרשים {count} שחקנים נוספים.'**
  String findMissingPlayersDescription(Object count);

  /// No description provided for @confirm.
  ///
  /// In he, this message translates to:
  /// **'אישור'**
  String get confirm;

  /// No description provided for @recruitingFeedContent.
  ///
  /// In he, this message translates to:
  /// **'האב {hubName} צריך {count} שחקנים למשחק ב-{gameDate}'**
  String recruitingFeedContent(Object hubName, Object count, Object gameDate);

  /// No description provided for @gamePromotedToRegionalFeed.
  ///
  /// In he, this message translates to:
  /// **'המשחק הוצג בפיד האזורי למציאת שחקנים'**
  String get gamePromotedToRegionalFeed;

  /// No description provided for @gameOpenForRecruiting.
  ///
  /// In he, this message translates to:
  /// **'המשחק פתוח כעת לגיוס שחקנים'**
  String get gameOpenForRecruiting;

  /// No description provided for @loadingWeather.
  ///
  /// In he, this message translates to:
  /// **'טוען תנאי מזג אוויר...'**
  String get loadingWeather;

  /// No description provided for @gameWeatherTitle.
  ///
  /// In he, this message translates to:
  /// **'תנאי מזג אוויר למשחק'**
  String get gameWeatherTitle;

  /// No description provided for @temperatureCelsius.
  ///
  /// In he, this message translates to:
  /// **'{temp}°C'**
  String temperatureCelsius(Object temp);

  /// No description provided for @resultUpdatedSuccess.
  ///
  /// In he, this message translates to:
  /// **'התוצאה עודכנה בהצלחה'**
  String get resultUpdatedSuccess;

  /// No description provided for @resultUpdateError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בעדכון התוצאה: {error}'**
  String resultUpdateError(Object error);

  /// No description provided for @teamsTitle.
  ///
  /// In he, this message translates to:
  /// **'הקבוצות'**
  String get teamsTitle;

  /// No description provided for @teamPlayerCount.
  ///
  /// In he, this message translates to:
  /// **'({count})'**
  String teamPlayerCount(Object count);

  /// No description provided for @noPlayers.
  ///
  /// In he, this message translates to:
  /// **'אין שחקנים'**
  String get noPlayers;

  /// No description provided for @sessionSummaryTitle.
  ///
  /// In he, this message translates to:
  /// **'סיכום סשן'**
  String get sessionSummaryTitle;

  /// No description provided for @sessionWinnerLabel.
  ///
  /// In he, this message translates to:
  /// **'מנצח: {winner}'**
  String sessionWinnerLabel(Object winner);

  /// No description provided for @teamStatsTitle.
  ///
  /// In he, this message translates to:
  /// **'סטטיסטיקות קבוצות'**
  String get teamStatsTitle;

  /// No description provided for @teamStatsRecord.
  ///
  /// In he, this message translates to:
  /// **'ניצחונות: {wins} | תיקו: {draws} | הפסדים: {losses}'**
  String teamStatsRecord(Object wins, Object draws, Object losses);

  /// No description provided for @teamStatsGoals.
  ///
  /// In he, this message translates to:
  /// **'שערים: {goalsFor} | הפרש: {goalDifference}'**
  String teamStatsGoals(Object goalsFor, Object goalDifference);

  /// No description provided for @pointsShort.
  ///
  /// In he, this message translates to:
  /// **'{points} נק\''**
  String pointsShort(Object points);

  /// No description provided for @totalMatchesLabel.
  ///
  /// In he, this message translates to:
  /// **'סה\"כ {count} משחקים'**
  String totalMatchesLabel(Object count);

  /// No description provided for @teamADefaultName.
  ///
  /// In he, this message translates to:
  /// **'קבוצה א\''**
  String get teamADefaultName;

  /// No description provided for @teamBDefaultName.
  ///
  /// In he, this message translates to:
  /// **'קבוצה ב\''**
  String get teamBDefaultName;

  /// No description provided for @finalScoreTitle.
  ///
  /// In he, this message translates to:
  /// **'תוצאה סופית'**
  String get finalScoreTitle;

  /// No description provided for @hubFallbackName.
  ///
  /// In he, this message translates to:
  /// **'האב'**
  String get hubFallbackName;

  /// No description provided for @temp.
  ///
  /// In he, this message translates to:
  /// **'temp'**
  String get temp;
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
