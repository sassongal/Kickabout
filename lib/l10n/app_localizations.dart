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
