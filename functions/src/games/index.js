const gameTriggers = require('./game_triggers');
const statsTriggers = require('./stats_triggers');
const scheduler = require('./scheduler');
const callables = require('./callables');
const signupSync = require('./signup-sync');

exports.onGameCreated = gameTriggers.onGameCreated;
exports.onGameCompleted = statsTriggers.onGameCompleted;
exports.onGameSignupChanged = gameTriggers.onGameSignupChanged;
exports.onGameEventChanged = statsTriggers.onGameEventChanged;
exports.onSignupStatusChanged = gameTriggers.onSignupStatusChanged;

// Signup denormalization sync triggers (for N+1 query optimization)
exports.onGameCreatedSyncSignups = signupSync.onGameCreatedSyncSignups;
exports.onGameUpdatedSyncSignups = signupSync.onGameUpdatedSyncSignups;
exports.onSignupCreatedPopulateGameData = signupSync.onSignupCreatedPopulateGameData;

exports.sendGameReminder = scheduler.sendGameReminder;

exports.startGameEarly = callables.startGameEarly;
exports.notifyHubOnNewGame = callables.notifyHubOnNewGame;
