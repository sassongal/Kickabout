/* eslint-disable max-len */
// Main entry point for Cloud Functions
// All functions are organized in modules under src/

// Games
const games = require('./src/games');
exports.onGameCreated = games.onGameCreated;
exports.onGameCompleted = games.onGameCompleted;
exports.onGameSignupChanged = games.onGameSignupChanged;
exports.onGameEventChanged = games.onGameEventChanged;
exports.sendGameReminder = games.sendGameReminder;
exports.startGameEarly = games.startGameEarly;
exports.notifyHubOnNewGame = games.notifyHubOnNewGame;
exports.onSignupStatusChanged = games.onSignupStatusChanged;

// Game Signup Denormalization Sync (CRITICAL: Keeps signup data in sync with games)
exports.onGameCreatedSyncSignups = games.onGameCreatedSyncSignups;
exports.onGameUpdatedSyncSignups = games.onGameUpdatedSyncSignups;
exports.onSignupCreatedPopulateGameData = games.onSignupCreatedPopulateGameData;

// Social
const social = require('./src/social');
exports.onHubMessageCreated = social.onHubMessageCreated;
exports.onCommentCreated = social.onCommentCreated;
exports.onRecruitingPostCreated = social.onRecruitingPostCreated;
exports.onContactMessageCreated = social.onContactMessageCreated;
exports.onFollowCreated = social.onFollowCreated;
exports.onUserUpdatedSyncPosts = social.onUserUpdatedSyncPosts;

// API
const api = require('./src/api');
exports.searchVenues = api.searchVenues;
exports.getPlaceDetails = api.getPlaceDetails;
exports.getHubsForPlace = api.getHubsForPlace;
exports.getHomeDashboardData = api.getHomeDashboardData;

// Gamification
const gamification = require('./src/gamification');
exports.onRatingSnapshotCreated = gamification.onRatingSnapshotCreated;

// Badge Triggers (Separated from game completion for better performance)
const badgeTriggers = require('./src/games/badge_triggers');
exports.onUserStatsUpdated = badgeTriggers.onUserStatsUpdated;

// Feed Triggers (Separated from game completion for better performance)
const feedTriggers = require('./src/games/feed_triggers');
exports.onGameFeedTrigger = feedTriggers.onGameFeedTrigger;

// Session Triggers (Winner Stays session lifecycle)
const sessionTriggers = require('./src/games/session_triggers');
exports.onSessionEnded = sessionTriggers.onSessionEnded;
exports.onSessionStarted = sessionTriggers.onSessionStarted;
exports.cleanupAbandonedSessions = sessionTriggers.cleanupAbandonedSessions;

// Hubs
const hubs = require('./src/hubs');
exports.addSuperAdminToHub = hubs.addSuperAdminToHub;
exports.onHubDeleted = hubs.onHubDeleted;
exports.onHubMembershipChanged = hubs.onHubMembershipChanged;
exports.createSuperAdmin = hubs.createSuperAdmin;

// Venues
const venues = require('./src/venues');
exports.onVenueChanged = venues.onVenueChanged;

// Storage
const storage = require('./src/storage');
exports.onImageUploaded = storage.onImageUploaded;

// Polls (already modular)
const { votePoll, closePoll, onPollCreated, scheduledPollAutoClose } = require('./pollFunctions');
exports.votePoll = votePoll;
exports.closePoll = closePoll;
exports.onPollCreated = onPollCreated;
exports.scheduledPollAutoClose = scheduledPollAutoClose;

// Scheduled (already modular)
const autoClose = require('./scheduledGameAutoClose');
exports.scheduledGameAutoClose = autoClose.scheduledGameAutoClose;
const reminders = require('./scheduledGameReminders');
exports.scheduledGameReminders = reminders.scheduledGameReminders;

// Membership (HubMember subcollection functions)
const membership = require('./src/membership');
exports.onMembershipChange = membership.onMembershipChange;
exports.onChatMessage = membership.onChatMessage;
exports.onGameSignup = membership.onGameSignup;
exports.promoteVeterans = membership.promoteVeterans;

// Migrations (One-time data migrations)
const migrations = require('./src/migrations/migrate_hub_member_arrays');
exports.migrateHubMemberArrays = migrations.migrateHubMemberArrays;
