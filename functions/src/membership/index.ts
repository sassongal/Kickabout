/**
 * Cloud Functions for Kickabout Hub Membership System
 * 
 * This file exports all hub membership-related Cloud Functions.
 */

// Scheduled functions
export { promoteVeterans } from './scheduled/promoteVeterans';

// Trigger functions
export {
    onMembershipChange,
    onChatMessage,
    onGameSignup,
} from './triggers/membershipCounters';

// Export existing functions (add to existing index.ts)
