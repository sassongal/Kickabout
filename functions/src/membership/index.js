/**
 * Cloud Functions for Kickabout Hub Membership System
 * 
 * This file exports all hub membership-related Cloud Functions.
 */

// Scheduled functions
const promoteVeterans = require('../scheduled/promoteVeterans');
exports.promoteVeterans = promoteVeterans.promoteVeterans;

// Trigger functions
const membershipCounters = require('../triggers/membershipCounters');
exports.onMembershipChange = membershipCounters.onMembershipChange;
exports.onChatMessage = membershipCounters.onChatMessage;
exports.onGameSignup = membershipCounters.onGameSignup;
