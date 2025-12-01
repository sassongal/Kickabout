/* eslint-disable max-len */
/**
 * Scheduled Function: Game Attendance Reminders
 * Gap Analysis #5: Attendance Confirmation System
 * 
 * Sends FCM notifications 2 hours before game starts
 * Users can confirm/cancel attendance in the app
 * 
 * Runs: Every 30 minutes
 */

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { info, error } = require('firebase-functions/logger');
const { getUserFCMTokens } = require('./src/utils');

const db = getFirestore();
const messaging = getMessaging();

exports.scheduledGameReminders = onSchedule(
  {
    schedule: 'every 30 minutes',
    timeZone: 'Asia/Jerusalem',
    region: 'us-central1',
    memory: '512MiB',
  },
  async (event) => {
    info('Running scheduledGameReminders...');
    const now = new Date();
    
    // ✅ Find games starting in 1.5-2.5 hours (2h ± 30min window)
    const oneAndHalfHoursFromNow = new Date(now.getTime() + 1.5 * 60 * 60 * 1000);
    const twoAndHalfHoursFromNow = new Date(now.getTime() + 2.5 * 60 * 60 * 1000);
    
    try {
      const gamesSnapshot = await db
        .collection('games')
        .where('status', '==', 'teamSelection')
        .where('gameDate', '>=', oneAndHalfHoursFromNow)
        .where('gameDate', '<=', twoAndHalfHoursFromNow)
        .limit(100)
        .get();

      if (gamesSnapshot.empty) {
        info('No games found for 2-hour reminders');
        return null;
      }

      info(`Found ${gamesSnapshot.size} games for 2-hour reminders`);

      const reminderPromises = gamesSnapshot.docs.map(async (gameDoc) => {
        const gameId = gameDoc.id;
        const game = gameDoc.data();

        try {
          // Check if organizer enabled attendance reminders
          if (game.enableAttendanceReminder === false) {
            info(`Attendance reminders disabled for game ${gameId}`);
            return;
          }

          // Check if reminder already sent (prevent duplicates)
          if (game.reminderSent2Hours) {
            info(`Reminder already sent for game ${gameId}`);
            return;
          }

          // Get participants (signed up players) from signups subcollection
          const signupsSnapshot = await db
            .collection('games')
            .doc(gameId)
            .collection('signups')
            .get();
          
          const participants = signupsSnapshot.docs.map(doc => doc.id);
          if (participants.length === 0) {
            info(`No participants for game ${gameId}`);
            return;
          }

          // Get venue name
          const venueName = game.venueName || 'המגרש';

          // Get Hub name
          let hubName = 'האב שלך';
          try {
            const hubDoc = await db.collection('hubs').doc(game.hubId).get();
            if (hubDoc.exists) {
              hubName = hubDoc.data().name || hubName;
            }
          } catch (err) {
            info(`Could not fetch hub name for game ${gameId}:`, err);
          }

          // ✅ Fetch FCM tokens in PARALLEL using helper
          const tokenArrays = await Promise.all(
            participants.map((userId) => getUserFCMTokens(userId))
          );
          const tokens = tokenArrays.flat();

          if (tokens.length === 0) {
            info(`No FCM tokens found for game ${gameId}`);
            // Mark as sent anyway to avoid retries
            await gameDoc.ref.update({
              reminderSent2Hours: true,
            });
            return;
          }

          const uniqueTokens = [...new Set(tokens)];

          // ✅ Send reminder notification
          const message = {
            notification: {
              title: '⚽ תזכורת משחק - מתחיל בעוד שעתיים!',
              body: `${hubName} • ${venueName}\nאשר הגעה באפליקציה`,
            },
            tokens: uniqueTokens,
            data: {
              type: 'game_reminder_2h',
              gameId: gameId,
              hubId: game.hubId,
              action: 'confirm_attendance',
            },
            android: {
              priority: 'high',
            },
            apns: {
              headers: {
                'apns-priority': '10',
              },
            },
          };

          const response = await messaging.sendEachForMulticast(message);
          info(`Sent 2h reminder for game ${gameId} to ${response.successCount}/${uniqueTokens.length} devices`);

          // Mark reminder as sent
          await gameDoc.ref.update({
            reminderSent2Hours: true,
            reminderSent2HoursAt: new Date(),
          });

        } catch (err) {
          error(`Failed to send reminder for game ${gameId}:`, err);
        }
      });

      await Promise.all(reminderPromises);

      info(`Completed sending 2-hour reminders for ${gamesSnapshot.size} games`);
      return null;
    } catch (err) {
      error('Error in scheduledGameReminders:', err);
      throw err;
    }
  }
);

