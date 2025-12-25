const { warn } = require('firebase-functions/logger');

// Optional Sentry - only load if available
let Sentry = null;
let sentryDsn = null;
let sentryInitialized = false;

// Check if @sentry/node is available before requiring it
try {
  // Try to require @sentry/node - if it fails, Sentry is not available
  require.resolve('@sentry/node');
  Sentry = require('@sentry/node');
  
  // Only define secret if Sentry is available
  const { defineSecret } = require('firebase-functions/params');
  sentryDsn = defineSecret('SENTRY_DSN');
} catch (e) {
  // @sentry/node not available or not installed - monitoring disabled
  warn('[monitoring] @sentry/node not available; monitoring disabled.');
  // Create a dummy object that mimics defineSecret but doesn't require the secret
  sentryDsn = {
    value: () => null,
    _isDummy: true, // Flag to indicate this is a dummy object
  };
}

function initSentry() {
  if (sentryInitialized || !Sentry || !sentryDsn) return;
  
  try {
    const dsn = sentryDsn.value();
    if (!dsn) {
      warn('[monitoring] SENTRY_DSN is not set; skipping Sentry init.');
      return;
    }

    Sentry.init({
      dsn,
      tracesSampleRate: 0,
    });
    sentryInitialized = true;
  } catch (e) {
    warn('[monitoring] Failed to initialize Sentry:', e.message);
  }
}

function captureException(error, context = {}) {
  if (!Sentry) return;
  initSentry();
  if (!sentryInitialized) return;

  try {
    const { functionName, extra } = context;
    Sentry.captureException(error, {
      tags: functionName ? { function: functionName } : undefined,
      extra,
    });
  } catch (e) {
    warn('[monitoring] Failed to capture exception:', e.message);
  }
}

async function flushSentry(timeoutMs = 2000) {
  if (!Sentry || !sentryInitialized) return;
  try {
    await Sentry.flush(timeoutMs);
  } catch (e) {
    warn('[monitoring] Failed to flush Sentry:', e.message);
  }
}

module.exports = {
  sentryDsn, // Return dummy object if Sentry not available
  captureException,
  flushSentry,
};
