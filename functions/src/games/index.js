const triggers = require('./triggers');
const scheduler = require('./scheduler');
const callables = require('./callables');
const signupSync = require('./signup-sync');

exports.onGameCreated = triggers.onGameCreated;
exports.onGameCompleted = triggers.onGameCompleted;
exports.onGameSignupChanged = triggers.onGameSignupChanged;
exports.onGameEventChanged = triggers.onGameEventChanged;
exports.onSignupStatusChanged = triggers.onSignupStatusChanged;

// Signup denormalization sync triggers (for N+1 query optimization)
exports.onGameCreatedSyncSignups = signupSync.onGameCreatedSyncSignups;
exports.onGameUpdatedSyncSignups = signupSync.onGameUpdatedSyncSignups;
exports.onSignupCreatedPopulateGameData = signupSync.onSignupCreatedPopulateGameData;

exports.sendGameReminder = scheduler.sendGameReminder;

exports.startGameEarly = callables.startGameEarly;
exports.notifyHubOnNewGame = callables.notifyHubOnNewGame;
