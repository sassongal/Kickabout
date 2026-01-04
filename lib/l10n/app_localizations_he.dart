// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'קיקאדור';

  @override
  String get welcome => 'ברוכים הבאים';

  @override
  String get login => 'התחבר';

  @override
  String get register => 'הרשם';

  @override
  String get email => 'אימייל';

  @override
  String get password => 'סיסמה';

  @override
  String get name => 'שם';

  @override
  String get phoneNumber => 'מספר טלפון';

  @override
  String get home => 'בית';

  @override
  String get players => 'שחקנים';

  @override
  String get games => 'משחקים';

  @override
  String get hubs => 'הובס';

  @override
  String get createGame => 'צור משחק';

  @override
  String get createHub => 'צור הוב';

  @override
  String get teamFormation => 'יצירת קבוצות';

  @override
  String get stats => 'סטטיסטיקות';

  @override
  String get profile => 'פרופיל';

  @override
  String get share => 'שתף';

  @override
  String get save => 'שמור';

  @override
  String get cancel => 'ביטול';

  @override
  String get delete => 'מחק';

  @override
  String get edit => 'ערוך';

  @override
  String get loading => 'טוען...';

  @override
  String get error => 'שגיאה';

  @override
  String get success => 'הצלחה';

  @override
  String get locationPermissionError => 'אין הרשאת מיקום';

  @override
  String get pleaseLogin => 'נא להתחבר';

  @override
  String get guestsCannotCreateHubs =>
      'אורחים לא יכולים ליצור הובים. נא להתחבר או להירשם.';

  @override
  String get hubCreatedSuccess => 'ההוב נוצר בהצלחה!';

  @override
  String get hubCreationError => 'שגיאה ביצירת הוב';

  @override
  String get hubCreationPermissionError => 'אין לך הרשאה ליצור הוב.';

  @override
  String get pleaseReLogin => 'נא להתחבר מחדש';

  @override
  String hubCreationErrorDetails(String error) {
    return 'שגיאה ביצירת הוב: $error';
  }

  @override
  String get createHubTitle => 'צור הוב';

  @override
  String get hubNameLabel => 'שם ההוב';

  @override
  String get hubNameHint => 'הכנס שם להוב';

  @override
  String get hubNameValidator => 'נא להכניס שם';

  @override
  String get hubDescriptionLabel => 'תיאור (אופציונלי)';

  @override
  String get hubDescriptionHint => 'הכנס תיאור להוב';

  @override
  String get regionLabel => 'אזור';

  @override
  String get regionHint => 'בחר אזור';

  @override
  String get regionHelperText => 'משפיע על הפיד האזורי';

  @override
  String get regionNorth => 'צפון';

  @override
  String get regionCenter => 'מרכז';

  @override
  String get regionSouth => 'דרום';

  @override
  String get regionJerusalem => 'ירושלים';

  @override
  String get venuesOptionalLabel => 'מגרשים (אופציונלי)';

  @override
  String get venuesAddLaterInfo => 'תוכל להוסיף מגרשים מאוחר יותר בהגדרות ההוב';

  @override
  String get venuesAddAfterCreationInfo => 'תוכל להוסיף מגרשים לאחר יצירת ההוב';

  @override
  String get addVenuesButton => 'הוסף מגרשים';

  @override
  String get locationOptionalLabel => 'מיקום (אופציונלי)';

  @override
  String get gettingLocation => 'מקבל מיקום...';

  @override
  String get currentLocation => 'מיקום נוכחי';

  @override
  String get selectOnMap => 'בחר במפה';

  @override
  String get creating => 'יוצר...';

  @override
  String get errorMissingHubId => 'שגיאה: מזהה הוב חסר';

  @override
  String get eventNotFound => 'אירוע לא נמצא';

  @override
  String get gameNotFound => 'משחק לא נמצא';

  @override
  String get noAdminPermissionForScreen => 'אין לך הרשאת ניהול למסך זה';

  @override
  String get onlyHubAdminsCanCreateTeams => 'רק מנהלי הוב יכולים ליצור קבוצות';

  @override
  String get notEnoughRegisteredPlayers => 'אין מספיק נרשמים';

  @override
  String requiredPlayersCount(int count) {
    return 'נדרשים לפחות $count שחקנים';
  }

  @override
  String registeredPlayerCount(int count) {
    return 'נרשמו: $count';
  }

  @override
  String permissionCheckErrorDetails(String error) {
    return 'שגיאה בבדיקת הרשאות: $error';
  }

  @override
  String get hubSettingsTitle => 'הגדרות הוב';

  @override
  String get loadingSettings => 'טוען הגדרות...';

  @override
  String get hubNotFound => 'הוב לא נמצא';

  @override
  String get tryAgain => 'נסה שוב';

  @override
  String get ratingMode => 'מצב דירוג';

  @override
  String get advancedRating => 'מתקדם';

  @override
  String get basicRating => 'בסיסי';

  @override
  String get basicRatingDescription => 'דירוג פשוט 1-10';

  @override
  String get advancedRatingDescription =>
      'תכונות מפורטות (מהירות, בעיטה וכו\')';

  @override
  String get privacySettings => 'פרטיות';

  @override
  String get privateHub => 'פרטי';

  @override
  String get publicHub => 'ציבורי';

  @override
  String get publicHubDescription => 'גלוי לכולם';

  @override
  String get privateHubDescription => 'הזמנה בלבד';

  @override
  String get joinMode => 'מצב הצטרפות';

  @override
  String get approvalRequired => 'נדרש אישור';

  @override
  String get autoJoin => 'הצטרפות אוטומטית';

  @override
  String get autoJoinDescription => 'כל אחד יכול להצטרף מיידית';

  @override
  String get approvalRequiredDescription => 'מנהלים חייבים לאשר בקשות';

  @override
  String get notifications => 'התראות';

  @override
  String get notificationsDescription => 'אפשר התראות הוב';

  @override
  String get hubChat => 'צ\'אט הוב';

  @override
  String get hubChatDescription => 'אפשר צ\'אט לחברים';

  @override
  String get activityFeed => 'פיד פעילות';

  @override
  String get activityFeedDescription => 'הצג פעילות חברים';

  @override
  String get manageVenues => 'ניהול מגרשים';

  @override
  String get manageVenuesDescription => 'הוסף או הסר מגרשי משחק';

  @override
  String get hubRules => 'חוקי ההוב';

  @override
  String characterCount(int count) {
    return '$count תווים';
  }

  @override
  String get noRulesDefined => 'לא הוגדרו חוקים';

  @override
  String get paymentLinkLabel => 'קישור לתשלום';

  @override
  String get defined => 'מוגדר';

  @override
  String get notDefined => 'לא מוגדר';

  @override
  String get hubInvitations => 'הזמנות';

  @override
  String get hubInvitationsDescription => 'ניהול הזמנות ממתינות';

  @override
  String get checkingPermissions => 'בודק הרשאות...';

  @override
  String get permissionCheckError => 'שגיאה בבדיקת הרשאות';

  @override
  String get settingUpdatedSuccess => 'הגדרה עודכנה בהצלחה';

  @override
  String settingUpdateError(String error) {
    return 'שגיאה בעדכון הגדרה: $error';
  }

  @override
  String get hubRulesSavedSuccess => 'חוקים נשמרו בהצלחה';

  @override
  String hubRulesSaveError(String error) {
    return 'שגיאה בשמירת חוקים: $error';
  }

  @override
  String get hubRulesHint => 'הכנס חוקי הוב כאן...';

  @override
  String get hubRulesHelper => 'גלוי לכל החברים';

  @override
  String get saving => 'שומר...';

  @override
  String get saveRules => 'שמור חוקים';

  @override
  String get paymentLinkSavedSuccess => 'קישור לתשלום נשמר';

  @override
  String paymentLinkSaveError(String error) {
    return 'שגיאה בשמירת קישור: $error';
  }

  @override
  String get paymentLinkBitLabel => 'קישור לתשלום (ביט/פייבוקס)';

  @override
  String get paymentLinkHint => 'https://...';

  @override
  String get paymentLinkHelper => 'משמש לאיסוף כספי משחק';

  @override
  String get saveLink => 'שמור קישור';

  @override
  String get onlyHubAdminsCanChangeSettings =>
      'רק מנהלי הוב יכולים לשנות הגדרות';

  @override
  String get playerDetailsUpdatedSuccess => 'פרטי השחקן עודכנו בהצלחה';

  @override
  String get pleaseEnterValidEmail => 'נא להזין כתובת אימייל תקינה';

  @override
  String hubInvitationEmailSubject(String hubName) {
    return 'הזמנה להצטרף ל-$hubName ב-Kattrick';
  }

  @override
  String hubInvitationEmailBody(
      String playerName, String hubName, String link, String code) {
    return 'היי!\n\n$playerName הזמין אותך להצטרף ל-$hubName ב-Kattrick.\n\nלחץ על הקישור להצטרפות:\n$link\n\nאו השתמש בקוד: $code';
  }

  @override
  String get emailClientOpened => 'אפליקציית האימייל נפתחה';

  @override
  String get linkCopiedToClipboard => 'הקישור הועתק ללוח';

  @override
  String get editManualPlayerTitle => 'עריכת שחקן';

  @override
  String get editManualPlayerSubtitle => 'עדכון פרטים לשחקן ידני';

  @override
  String get fullNameRequired => 'שם מלא *';

  @override
  String get pleaseEnterName => 'נא להזין שם';

  @override
  String get emailForInvitationLabel => 'אימייל (להזמנה)';

  @override
  String get invalidEmailAddress => 'כתובת אימייל לא תקינה';

  @override
  String get phoneNumberLabel => 'מספר טלפון';

  @override
  String get cityLabel => 'עיר';

  @override
  String get ratingLabel => 'דירוג (0-10)';

  @override
  String get ratingRangeError => 'הדירוג חייב להיות בין 0 ל-10';

  @override
  String get preferredPositionLabel => 'עמדה מועדפת';

  @override
  String get sendEmailInvitation => 'שלח הזמנה במייל';

  @override
  String get saveChanges => 'שמור שינויים';

  @override
  String get positionGoalkeeper => 'שוער';

  @override
  String get positionDefense => 'הגנה';

  @override
  String get positionMidfielder => 'קישור';

  @override
  String get positionForward => 'התקפה';

  @override
  String get yourHubsTitle => 'ההובים שלך';

  @override
  String get notificationsTooltip => 'התראות';

  @override
  String get mapTooltip => 'מפה';

  @override
  String get discoverHubsTooltip => 'גלה הובים';

  @override
  String get backToHomeTooltip => 'חזרה לבית';

  @override
  String get errorLoadingHubs => 'שגיאה בטעינת הובים';

  @override
  String get noHubs => 'לא נמצאו הובים';

  @override
  String get createHubToStart => 'צור הוב כדי להתחיל!';

  @override
  String memberCount(int count) {
    return '$count חברים';
  }

  @override
  String get hubNotFoundWithInviteCode => 'לא נמצא הוב עם קוד הזמנה זה';

  @override
  String get pleaseLoginFirst => 'נא להתחבר תחילה';

  @override
  String get hubInvitationsDisabled => 'ההזמנות להוב זה מושבתות';

  @override
  String joinedHubSuccess(String hubName) {
    return 'הצטרפת בהצלחה ל-$hubName';
  }

  @override
  String get joinRequestSent => 'בקשת הצטרפות נשלחה בהצלחה';

  @override
  String joinHubError(String error) {
    return 'שגיאה בהצטרפות להוב: $error';
  }

  @override
  String get joinHubTitle => 'הצטרף להוב';

  @override
  String get backToHome => 'חזרה לבית';

  @override
  String get hubRequiresApproval => 'הוב זה דורש אישור מנהל להצטרפות';

  @override
  String get sendJoinRequest => 'שלח בקשת הצטרפות';

  @override
  String get joinHubButton => 'הצטרף להוב';

  @override
  String statusUpdateError(String error) {
    return 'שגיאה בעדכון סטטוס: $error';
  }

  @override
  String get requestApproved => 'בקשתך אושרה!';

  @override
  String get gamePostponed => 'המשחק נדחה';

  @override
  String get gameCancelled => 'המשחק בוטל';

  @override
  String get gameCompleted => 'המשחק הסתיים';

  @override
  String get signupConfirmed => 'ההרשמה אושרה!';

  @override
  String get signupCancelled => 'ההרשמה בוטלה';

  @override
  String get locationUpdatedSuccess => 'המיקום עודכן בהצלחה';

  @override
  String locationUpdateError(String error) {
    return 'שגיאה בעדכון מיקום: $error';
  }

  @override
  String get noPermissionForAction => 'אין לך הרשאה לבצע פעולה זו';

  @override
  String get itemNotFound => 'הפריט לא נמצא';

  @override
  String get serviceUnavailable => 'השירות לא זמין כרגע, נסה שוב מאוחר יותר';

  @override
  String get pleaseSignInAgain => 'נא להתחבר מחדש';

  @override
  String get genericError => 'אירעה שגיאה, נסה שוב';

  @override
  String get upcomingGames => 'משחקים קרובים';

  @override
  String get toAllEvents => 'לכל האירועים';

  @override
  String get adminConsole => 'לוח בקרה';

  @override
  String get generateDummyData => 'יצירת נתוני דמה (פיתוח)';

  @override
  String get forceLocation => 'כפה מיקום (פיתוח)';

  @override
  String get gameDetailsTitle => 'פרטי משחק';

  @override
  String get gameLoadingMessage => 'טוען משחק...';

  @override
  String get gameLoadingError => 'שגיאה בטעינת המשחק';

  @override
  String get attendanceMonitoring => 'ניטור הגעה';

  @override
  String get locationNotSpecified => 'מיקום לא צוין';

  @override
  String teamCountLabel(Object count) {
    return '$count קבוצות';
  }

  @override
  String signupsCount(Object count) {
    return '$count נרשמו';
  }

  @override
  String signupsCountFull(Object count) {
    return '$count נרשמו (מלא)';
  }

  @override
  String get gameRulesTitle => 'חוקי המשחק';

  @override
  String gameDurationLabel(Object minutes) {
    return 'משך: $minutes דקות';
  }

  @override
  String gameEndConditionLabel(Object condition) {
    return 'תנאי סיום: $condition';
  }

  @override
  String get statusApproved => 'מאושר';

  @override
  String get statusPending => 'ממתין';

  @override
  String get removePlayerTooltip => 'הסר שחקן';

  @override
  String get signupRemovedSuccess => 'הסרת הרשמה';

  @override
  String get signupSuccess => 'נרשמת למשחק';

  @override
  String get onlyCreatorCanStartGame => 'רק יוצר המשחק יכול להתחיל';

  @override
  String get gameStartedSuccess => 'המשחק התחיל';

  @override
  String get onlyCreatorCanEndGame => 'רק יוצר המשחק יכול לסיים';

  @override
  String get gameEndedSuccess => 'המשחק הסתיים';

  @override
  String get gameStatusDraft => 'טיוטה';

  @override
  String get gameStatusScheduled => 'מתוכנן';

  @override
  String get gameStatusRecruiting => 'גיוס שחקנים';

  @override
  String get gameStatusTeamSelection => 'בחירת קבוצות';

  @override
  String get gameStatusTeamsFormed => 'קבוצות נוצרו';

  @override
  String get gameStatusFull => 'מלא';

  @override
  String get gameStatusInProgress => 'במהלך';

  @override
  String get gameStatusCompleted => 'הושלם';

  @override
  String get gameStatusStatsInput => 'הזנת סטטיסטיקות';

  @override
  String get gameStatusCancelled => 'בוטל';

  @override
  String get gameStatusArchivedNotPlayed => 'ארכיון - לא שוחק';

  @override
  String get playersLoadError => 'שגיאה בטעינת שחקנים';

  @override
  String targetingMismatchWarning(
      Object minAge, Object maxAge, Object genderSuffix) {
    return 'שים לב: המשחק מיועד לגילאים $minAge-$maxAge $genderSuffix';
  }

  @override
  String get genderMaleSuffix => '(גברים)';

  @override
  String get genderFemaleSuffix => '(נשים)';

  @override
  String get gameChatButton => 'צ\'אט משחק';

  @override
  String get requestToJoin => 'בקש להצטרף';

  @override
  String get signupForGame => 'הירשם למשחק';

  @override
  String get requestSentPendingApproval => 'בקשה נשלחה - ממתין לאישור';

  @override
  String get cancelSignup => 'בטל הרשמה';

  @override
  String get gameFullWaitlist => 'המשחק מלא - ניתן להירשם לרשימת המתנה';

  @override
  String pendingRequestsTitle(Object count) {
    return 'בקשות ממתינות ($count)';
  }

  @override
  String get findMissingPlayers => 'מצא שחקנים חסרים';

  @override
  String get createTeams => 'צור קבוצות';

  @override
  String get logResultAndStats => 'תעד תוצאה וסטטיסטיקות';

  @override
  String get startGame => 'התחל משחק';

  @override
  String get recordStats => 'רישום סטטיסטיקות';

  @override
  String get endGame => 'סיים משחק';

  @override
  String get editResult => 'ערוך תוצאה';

  @override
  String get viewFullStats => 'צפה בסטטיסטיקות המלאות';

  @override
  String get signupsTitle => 'נרשמים';

  @override
  String confirmedSignupsTitle(Object count) {
    return 'מאושרים ($count)';
  }

  @override
  String pendingSignupsTitle(Object count) {
    return 'ממתינים ($count)';
  }

  @override
  String get noSignups => 'אין נרשמים';

  @override
  String requestedToJoinAt(Object time) {
    return 'ביקש להצטרף • $time';
  }

  @override
  String get approveTooltip => 'אשר';

  @override
  String get rejectTooltip => 'דחה';

  @override
  String get playerApprovedSuccess => 'שחקן אושר בהצלחה';

  @override
  String get rejectRequestTitle => 'דחיית בקשה';

  @override
  String get rejectionReasonLabel => 'סיבת הדחייה (חובה)';

  @override
  String get rejectionReasonHint => 'לדוגמה: המשחק מלא, לא מתאים לרמה...';

  @override
  String get rejectRequestButton => 'דחה בקשה';

  @override
  String get requestRejectedSuccess => 'בקשה נדחתה';

  @override
  String findMissingPlayersDescription(Object count) {
    return 'המשחק יהפוך ל-\"מגייס שחקנים\" ויוצג בפיד האזורי.\nנדרשים $count שחקנים נוספים.';
  }

  @override
  String get confirm => 'אישור';

  @override
  String get recruitingUrgentLabel => 'דחוף';

  @override
  String recruitingNeededPlayers(int count) {
    return 'מחפשים $count שחקנים';
  }

  @override
  String recruitingUntilLabel(Object date) {
    return 'עד: $date';
  }

  @override
  String recruitingFeedContent(Object hubName, Object count, Object gameDate) {
    return 'האב $hubName צריך $count שחקנים למשחק ב-$gameDate';
  }

  @override
  String get gamePromotedToRegionalFeed =>
      'המשחק הוצג בפיד האזורי למציאת שחקנים';

  @override
  String get gameOpenForRecruiting => 'המשחק פתוח כעת לגיוס שחקנים';

  @override
  String get loadingWeather => 'טוען תנאי מזג אוויר...';

  @override
  String get gameWeatherTitle => 'תנאי מזג אוויר למשחק';

  @override
  String temperatureCelsius(Object temp) {
    return '$temp°C';
  }

  @override
  String get resultUpdatedSuccess => 'התוצאה עודכנה בהצלחה';

  @override
  String resultUpdateError(Object error) {
    return 'שגיאה בעדכון התוצאה: $error';
  }

  @override
  String get teamsTitle => 'הקבוצות';

  @override
  String teamPlayerCount(Object count) {
    return '($count)';
  }

  @override
  String get noPlayers => 'אין שחקנים';

  @override
  String get sessionSummaryTitle => 'סיכום סשן';

  @override
  String sessionWinnerLabel(Object winner) {
    return 'מנצח: $winner';
  }

  @override
  String get teamStatsTitle => 'סטטיסטיקות קבוצות';

  @override
  String teamStatsRecord(Object wins, Object draws, Object losses) {
    return 'ניצחונות: $wins | תיקו: $draws | הפסדים: $losses';
  }

  @override
  String teamStatsGoals(Object goalsFor, Object goalDifference) {
    return 'שערים: $goalsFor | הפרש: $goalDifference';
  }

  @override
  String pointsShort(Object points) {
    return '$points נק\'';
  }

  @override
  String totalMatchesLabel(Object count) {
    return 'סה\"כ $count משחקים';
  }

  @override
  String get teamADefaultName => 'קבוצה א\'';

  @override
  String get teamBDefaultName => 'קבוצה ב\'';

  @override
  String get finalScoreTitle => 'תוצאה סופית';

  @override
  String get hubFallbackName => 'האב';

  @override
  String get welcome_message_1_premium => '✨ ברוך הבא למשפחה! בואו תצא למגרש';

  @override
  String get welcome_message_2_premium =>
      '🔥 מוכן להציג כישורים? הגיע הזמן לזרוח!';

  @override
  String get welcome_message_3_premium =>
      '⚡ הפלטפורמה שלך למשחק ברמה הבאה מתחילה כאן';

  @override
  String get welcome_message_4_premium =>
      '🏆 קבוצתך מחכה - בואו נעשה היסטוריה ביחד';

  @override
  String get welcome_message_5_premium =>
      '🎯 מהחלום למגרש - המסע שלך מתחיל עכשיו';

  @override
  String get noUpcomingEvents => 'אין אירועים קרובים';

  @override
  String get signUpOrCreateEvent => 'הירשם למשחק או צור אירוע חדש';

  @override
  String get startsIn => 'מתחיל בעוד';

  @override
  String get allMyEvents => 'לכל האירועים שלי';

  @override
  String get organizer => 'מארגן';

  @override
  String get userFallback => 'משתמש';

  @override
  String get eventLabel => 'אירוע';

  @override
  String get gameLabel => 'משחק';

  @override
  String get startEvent => 'התחל אירוע';

  @override
  String get voteMotm => 'הצבעה למצטיין';

  @override
  String get whoIsMotm => 'מי היה השחקן המצטיין היום?';

  @override
  String get submitVote => 'שלח הצבעה';

  @override
  String get voteCaptured => 'ההצבעה נקלטה! תודה על ההשתתפות.';

  @override
  String get alreadyVoted => 'כבר הצבעת למשחק זה';

  @override
  String voteError(Object error) {
    return 'שגיאה בשליחת ההצבעה: $error';
  }

  @override
  String get voteAtAnotherTime => 'לא עכשיו';

  @override
  String get enableMotmVoting => 'אפשר הצבעה למצטיין';

  @override
  String get enableMotmVotingSubtitle =>
      'אפשר לחברים להצביע לשחקן המצטיין לאחר המשחק';

  @override
  String motmWinner(Object name) {
    return 'השחקן המצטיין: $name';
  }

  @override
  String get noWinnerYet => 'טרם נבחר מנצח';

  @override
  String get payNow => 'שלם עכשיו';

  @override
  String get paymentLinkNotConfigured => 'קישור תשלום לא הוגדר';

  @override
  String get openingPaymentApp => 'פותח אפליקציית תשלום...';

  @override
  String get couldNotOpenPaymentLink => 'לא ניתן לפתוח קישור תשלום';

  @override
  String get rideSharing => 'טרמפיאדה';

  @override
  String get offeringRide => 'מציע טרמפ';

  @override
  String get needsRide => 'צריך טרמפ';

  @override
  String get hasCar => 'יש לי רכב';

  @override
  String get availableSeats => 'מקומות פנויים';

  @override
  String get requestRide => 'בקש טרמפ';

  @override
  String get cancelRideRequest => 'בטל בקשה';

  @override
  String get offerRide => 'הצע טרמפ';

  @override
  String get cancelRideOffer => 'בטל הצעה';

  @override
  String get drivers => 'נהגים';

  @override
  String get passengersNeeded => 'מחפשים טרמפ';

  @override
  String get selectDriver => 'בחר נהג';

  @override
  String get rideRequestSent => 'בקשת טרמפ נשלחה';

  @override
  String get noDriversAvailable => 'אין נהגים זמינים כרגע';

  @override
  String seatsAvailable(int count) {
    return '$count מקומות פנויים';
  }
}
