// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kattrick';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get home => 'Home';

  @override
  String get players => 'Players';

  @override
  String get games => 'Games';

  @override
  String get hubs => 'Hubs';

  @override
  String get createGame => 'Create Game';

  @override
  String get createHub => 'Create Hub';

  @override
  String get teamFormation => 'Team Formation';

  @override
  String get stats => 'Stats';

  @override
  String get profile => 'Profile';

  @override
  String get share => 'Share';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get locationPermissionError => 'Location permission denied';

  @override
  String get pleaseLogin => 'Please login';

  @override
  String get guestsCannotCreateHubs =>
      'Guests cannot create hubs. Please login or register.';

  @override
  String get hubCreatedSuccess => 'Hub created successfully!';

  @override
  String get hubCreationError => 'Error creating hub';

  @override
  String get hubCreationPermissionError =>
      'You do not have permission to create a hub.';

  @override
  String get pleaseReLogin => 'Please re-login';

  @override
  String hubCreationErrorDetails(String error) {
    return 'Error creating hub: $error';
  }

  @override
  String get createHubTitle => 'Create Hub';

  @override
  String get hubNameLabel => 'Hub Name';

  @override
  String get hubNameHint => 'Enter hub name';

  @override
  String get hubNameValidator => 'Please enter a name';

  @override
  String get hubDescriptionLabel => 'Description (Optional)';

  @override
  String get hubDescriptionHint => 'Enter hub description';

  @override
  String get regionLabel => 'Region';

  @override
  String get regionHint => 'Select region';

  @override
  String get regionHelperText => 'Affects regional feed';

  @override
  String get regionNorth => 'North';

  @override
  String get regionCenter => 'Center';

  @override
  String get regionSouth => 'South';

  @override
  String get regionJerusalem => 'Jerusalem';

  @override
  String get venuesOptionalLabel => 'Venues (Optional)';

  @override
  String get venuesAddLaterInfo => 'You can add venues later in hub settings';

  @override
  String get venuesAddAfterCreationInfo =>
      'You can add venues after creating the hub';

  @override
  String get addVenuesButton => 'Add Venues';

  @override
  String get locationOptionalLabel => 'Location (Optional)';

  @override
  String get gettingLocation => 'Getting location...';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get selectOnMap => 'Select on Map';

  @override
  String get creating => 'Creating...';

  @override
  String get errorMissingHubId => 'Error: Missing Hub ID';

  @override
  String get eventNotFound => 'Event not found';

  @override
  String get gameNotFound => 'Game not found';

  @override
  String get noAdminPermissionForScreen =>
      'You do not have admin permission for this screen';

  @override
  String get onlyHubAdminsCanCreateTeams => 'Only Hub admins can create teams';

  @override
  String get notEnoughRegisteredPlayers => 'Not enough registered players';

  @override
  String requiredPlayersCount(int count) {
    return 'At least $count players are required';
  }

  @override
  String registeredPlayerCount(int count) {
    return 'Registered: $count';
  }

  @override
  String permissionCheckErrorDetails(String error) {
    return 'Permission check error: $error';
  }

  @override
  String get hubSettingsTitle => 'Hub Settings';

  @override
  String get loadingSettings => 'Loading settings...';

  @override
  String get hubNotFound => 'Hub not found';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get ratingMode => 'Rating Mode';

  @override
  String get advancedRating => 'Advanced';

  @override
  String get basicRating => 'Basic';

  @override
  String get basicRatingDescription => 'Simple 1-10 rating';

  @override
  String get advancedRatingDescription =>
      'Detailed attributes (Pace, Shooting, etc.)';

  @override
  String get privacySettings => 'Privacy';

  @override
  String get privateHub => 'Private';

  @override
  String get publicHub => 'Public';

  @override
  String get publicHubDescription => 'Visible to everyone';

  @override
  String get privateHubDescription => 'Invite only';

  @override
  String get joinMode => 'Join Mode';

  @override
  String get approvalRequired => 'Approval Required';

  @override
  String get autoJoin => 'Auto Join';

  @override
  String get autoJoinDescription => 'Anyone can join instantly';

  @override
  String get approvalRequiredDescription => 'Admins must approve requests';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDescription => 'Enable hub notifications';

  @override
  String get hubChat => 'Hub Chat';

  @override
  String get hubChatDescription => 'Enable chat for members';

  @override
  String get activityFeed => 'Activity Feed';

  @override
  String get activityFeedDescription => 'Show member activity';

  @override
  String get manageVenues => 'Manage Venues';

  @override
  String get manageVenuesDescription => 'Add or remove playing venues';

  @override
  String get hubRules => 'Hub Rules';

  @override
  String characterCount(int count) {
    return '$count characters';
  }

  @override
  String get noRulesDefined => 'No rules defined';

  @override
  String get paymentLinkLabel => 'Payment Link';

  @override
  String get defined => 'Defined';

  @override
  String get notDefined => 'Not defined';

  @override
  String get hubInvitations => 'Invitations';

  @override
  String get hubInvitationsDescription => 'Manage pending invitations';

  @override
  String get checkingPermissions => 'Checking permissions...';

  @override
  String get permissionCheckError => 'Permission check error';

  @override
  String get settingUpdatedSuccess => 'Setting updated successfully';

  @override
  String settingUpdateError(String error) {
    return 'Error updating setting: $error';
  }

  @override
  String get hubRulesSavedSuccess => 'Rules saved successfully';

  @override
  String hubRulesSaveError(String error) {
    return 'Error saving rules: $error';
  }

  @override
  String get hubRulesHint => 'Enter hub rules here...';

  @override
  String get hubRulesHelper => 'Visible to all members';

  @override
  String get saving => 'Saving...';

  @override
  String get saveRules => 'Save Rules';

  @override
  String get paymentLinkSavedSuccess => 'Payment link saved';

  @override
  String paymentLinkSaveError(String error) {
    return 'Error saving link: $error';
  }

  @override
  String get paymentLinkBitLabel => 'Payment Link (Bit/PayBox)';

  @override
  String get paymentLinkHint => 'https://...';

  @override
  String get paymentLinkHelper => 'Used for collecting game fees';

  @override
  String get saveLink => 'Save Link';

  @override
  String get onlyHubAdminsCanChangeSettings =>
      'Only Hub admins can change settings';

  @override
  String get playerDetailsUpdatedSuccess =>
      'Player details updated successfully';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String hubInvitationEmailSubject(String hubName) {
    return 'Invitation to join $hubName on Kattrick';
  }

  @override
  String hubInvitationEmailBody(
      String playerName, String hubName, String link, String code) {
    return 'Hi!\n\n$playerName invited you to join $hubName on Kattrick.\n\nClick the link to join:\n$link\n\nOr use code: $code';
  }

  @override
  String get emailClientOpened => 'Email client opened';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get editManualPlayerTitle => 'Edit Player';

  @override
  String get editManualPlayerSubtitle => 'Update details for manual player';

  @override
  String get fullNameRequired => 'Full Name *';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get emailForInvitationLabel => 'Email (for invitation)';

  @override
  String get invalidEmailAddress => 'Invalid email address';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get cityLabel => 'City';

  @override
  String get ratingLabel => 'Rating (0-10)';

  @override
  String get ratingRangeError => 'Rating must be between 0 and 10';

  @override
  String get preferredPositionLabel => 'Preferred Position';

  @override
  String get sendEmailInvitation => 'Send Invitation via Email';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get positionGoalkeeper => 'Goalkeeper';

  @override
  String get positionDefense => 'Defender';

  @override
  String get positionMidfielder => 'Midfielder';

  @override
  String get positionForward => 'Forward';

  @override
  String get yourHubsTitle => 'Your Hubs';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get mapTooltip => 'Map';

  @override
  String get discoverHubsTooltip => 'Discover Hubs';

  @override
  String get backToHomeTooltip => 'Back to Home';

  @override
  String get errorLoadingHubs => 'Error loading hubs';

  @override
  String get noHubs => 'No hubs found';

  @override
  String get createHubToStart => 'Create a hub to get started!';

  @override
  String memberCount(int count) {
    return '$count members';
  }

  @override
  String get hubNotFoundWithInviteCode =>
      'Hub not found with this invitation code';

  @override
  String get pleaseLoginFirst => 'Please login first';

  @override
  String get hubInvitationsDisabled => 'Invitations are disabled for this hub';

  @override
  String joinedHubSuccess(String hubName) {
    return 'Successfully joined $hubName';
  }

  @override
  String get joinRequestSent => 'Join request sent successfully';

  @override
  String joinHubError(String error) {
    return 'Error joining hub: $error';
  }

  @override
  String get joinHubTitle => 'Join Hub';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get hubRequiresApproval => 'This hub requires admin approval to join';

  @override
  String get sendJoinRequest => 'Send Join Request';

  @override
  String get joinHubButton => 'Join Hub';

  @override
  String statusUpdateError(String error) {
    return 'Error updating status: $error';
  }

  @override
  String get requestApproved => 'Your request was approved!';

  @override
  String get gamePostponed => 'Game postponed';

  @override
  String get gameCancelled => 'Game cancelled';

  @override
  String get gameCompleted => 'Game completed';

  @override
  String get signupConfirmed => 'Signup confirmed!';

  @override
  String get signupCancelled => 'Signup cancelled';

  @override
  String get locationUpdatedSuccess => 'Location updated successfully';

  @override
  String locationUpdateError(String error) {
    return 'Error updating location: $error';
  }

  @override
  String get noPermissionForAction =>
      'You don\'t have permission for this action';

  @override
  String get itemNotFound => 'Item not found';

  @override
  String get serviceUnavailable =>
      'Service unavailable, please try again later';

  @override
  String get pleaseSignInAgain => 'Please sign in again';

  @override
  String get genericError => 'An error occurred, please try again';

  @override
  String get upcomingGames => 'Upcoming Games';

  @override
  String get toAllEvents => 'To All Events';

  @override
  String get adminConsole => 'Admin Console';

  @override
  String get generateDummyData => 'Generate Dummy Data (Dev)';

  @override
  String get forceLocation => 'Force Location (Dev)';

  @override
  String get gameDetailsTitle => 'Game Details';

  @override
  String get gameLoadingMessage => 'Loading game...';

  @override
  String get gameLoadingError => 'Failed to load game';

  @override
  String get attendanceMonitoring => 'Attendance Monitoring';

  @override
  String get locationNotSpecified => 'Location not specified';

  @override
  String teamCountLabel(Object count) {
    return '$count teams';
  }

  @override
  String signupsCount(Object count) {
    return '$count registered';
  }

  @override
  String signupsCountFull(Object count) {
    return '$count registered (full)';
  }

  @override
  String get gameRulesTitle => 'Game rules';

  @override
  String gameDurationLabel(Object minutes) {
    return 'Duration: $minutes minutes';
  }

  @override
  String gameEndConditionLabel(Object condition) {
    return 'End condition: $condition';
  }

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusPending => 'Pending';

  @override
  String get removePlayerTooltip => 'Remove player';

  @override
  String get signupRemovedSuccess => 'Registration removed';

  @override
  String get signupSuccess => 'Joined the game';

  @override
  String get onlyCreatorCanStartGame => 'Only the game creator can start';

  @override
  String get gameStartedSuccess => 'Game started';

  @override
  String get onlyCreatorCanEndGame => 'Only the game creator can end';

  @override
  String get gameEndedSuccess => 'Game ended';

  @override
  String get gameStatusDraft => 'Draft';

  @override
  String get gameStatusScheduled => 'Scheduled';

  @override
  String get gameStatusRecruiting => 'Recruiting players';

  @override
  String get gameStatusTeamSelection => 'Team selection';

  @override
  String get gameStatusTeamsFormed => 'Teams formed';

  @override
  String get gameStatusFull => 'Full';

  @override
  String get gameStatusInProgress => 'In progress';

  @override
  String get gameStatusCompleted => 'Completed';

  @override
  String get gameStatusStatsInput => 'Stats input';

  @override
  String get gameStatusCancelled => 'Cancelled';

  @override
  String get gameStatusArchivedNotPlayed => 'Archived - not played';

  @override
  String get playersLoadError => 'Failed to load players';

  @override
  String targetingMismatchWarning(
      Object minAge, Object maxAge, Object genderSuffix) {
    return 'Note: this game is for ages $minAge-$maxAge $genderSuffix';
  }

  @override
  String get genderMaleSuffix => '(men)';

  @override
  String get genderFemaleSuffix => '(women)';

  @override
  String get gameChatButton => 'Game chat';

  @override
  String get requestToJoin => 'Request to join';

  @override
  String get signupForGame => 'Sign up for game';

  @override
  String get requestSentPendingApproval => 'Request sent - awaiting approval';

  @override
  String get cancelSignup => 'Cancel registration';

  @override
  String get gameFullWaitlist => 'Game is full - you can join the waitlist';

  @override
  String pendingRequestsTitle(Object count) {
    return 'Pending requests ($count)';
  }

  @override
  String get findMissingPlayers => 'Find missing players';

  @override
  String get createTeams => 'Create teams';

  @override
  String get logResultAndStats => 'Log result & stats';

  @override
  String get startGame => 'Start game';

  @override
  String get recordStats => 'Record stats';

  @override
  String get endGame => 'End game';

  @override
  String get editResult => 'Edit result';

  @override
  String get viewFullStats => 'View full stats';

  @override
  String get signupsTitle => 'Signups';

  @override
  String confirmedSignupsTitle(Object count) {
    return 'Confirmed ($count)';
  }

  @override
  String pendingSignupsTitle(Object count) {
    return 'Pending ($count)';
  }

  @override
  String get noSignups => 'No signups';

  @override
  String requestedToJoinAt(Object time) {
    return 'Requested to join • $time';
  }

  @override
  String get approveTooltip => 'Approve';

  @override
  String get rejectTooltip => 'Reject';

  @override
  String get playerApprovedSuccess => 'Player approved successfully';

  @override
  String get rejectRequestTitle => 'Reject request';

  @override
  String get rejectionReasonLabel => 'Rejection reason (required)';

  @override
  String get rejectionReasonHint =>
      'For example: the game is full, not the right level...';

  @override
  String get rejectRequestButton => 'Reject request';

  @override
  String get requestRejectedSuccess => 'Request rejected';

  @override
  String findMissingPlayersDescription(Object count) {
    return 'The game will switch to \"recruiting\" and appear in the regional feed.\\n$count more players needed.';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get recruitingUrgentLabel => 'Urgent';

  @override
  String recruitingNeededPlayers(int count) {
    return 'Looking for $count players';
  }

  @override
  String recruitingUntilLabel(Object date) {
    return 'Until: $date';
  }

  @override
  String recruitingFeedContent(Object hubName, Object count, Object gameDate) {
    return 'Hub $hubName needs $count players for a game on $gameDate';
  }

  @override
  String get gamePromotedToRegionalFeed =>
      'The game was promoted to the regional feed to find players';

  @override
  String get gameOpenForRecruiting =>
      'The game is now open for recruiting players';

  @override
  String get loadingWeather => 'Loading weather conditions...';

  @override
  String get gameWeatherTitle => 'Weather for the game';

  @override
  String temperatureCelsius(Object temp) {
    return '$temp°C';
  }

  @override
  String get resultUpdatedSuccess => 'Result updated successfully';

  @override
  String resultUpdateError(Object error) {
    return 'Failed to update result: $error';
  }

  @override
  String get teamsTitle => 'Teams';

  @override
  String teamPlayerCount(Object count) {
    return '($count)';
  }

  @override
  String get noPlayers => 'No players';

  @override
  String get sessionSummaryTitle => 'Session summary';

  @override
  String sessionWinnerLabel(Object winner) {
    return 'Winner: $winner';
  }

  @override
  String get teamStatsTitle => 'Team stats';

  @override
  String teamStatsRecord(Object wins, Object draws, Object losses) {
    return 'Wins: $wins | Draws: $draws | Losses: $losses';
  }

  @override
  String teamStatsGoals(Object goalsFor, Object goalDifference) {
    return 'Goals: $goalsFor | Diff: $goalDifference';
  }

  @override
  String pointsShort(Object points) {
    return '$points pts';
  }

  @override
  String totalMatchesLabel(Object count) {
    return 'Total $count games';
  }

  @override
  String get teamADefaultName => 'Team A';

  @override
  String get teamBDefaultName => 'Team B';

  @override
  String get finalScoreTitle => 'Final score';

  @override
  String get hubFallbackName => 'Hub';

  @override
  String get temp => 'temp';

  @override
  String get welcome_message_1_premium =>
      '✨ Welcome to the family! Let\'s hit the field';

  @override
  String get welcome_message_2_premium =>
      '🔥 Ready to showcase your skills? Time to shine!';

  @override
  String get welcome_message_3_premium =>
      '⚡ Your next-level game platform starts here';

  @override
  String get welcome_message_4_premium =>
      '🏆 Your team is waiting - let\'s make history together';

  @override
  String get welcome_message_5_premium =>
      '🎯 From dream to field - your journey starts now';

  @override
  String get noUpcomingEvents => 'No upcoming events';

  @override
  String get signUpOrCreateEvent => 'Sign up for a game or create a new event';

  @override
  String get startsIn => 'Starts in';

  @override
  String get allMyEvents => 'All my events';

  @override
  String get organizer => 'Organizer';

  @override
  String get userFallback => 'User';

  @override
  String get eventLabel => 'Event';

  @override
  String get gameLabel => 'Game';

  @override
  String get startEvent => 'Start event';
}
