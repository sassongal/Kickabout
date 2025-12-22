const Sentry = require('@sentry/node');
const { warn } = require('firebase-functions/logger');
const { defineSecret } = require('firebase-functions/params');

const sentryDsn = defineSecret('SENTRY_DSN');
let sentryInitialized = false;

function initSentry() {
  if (sentryInitialized) return;
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
}

function captureException(error, context = {}) {
  initSentry();
  if (!sentryInitialized) return;

  const { functionName, extra } = context;
  Sentry.captureException(error, {
    tags: functionName ? { function: functionName } : undefined,
    extra,
  });
}

async function flushSentry(timeoutMs = 2000) {
  if (!sentryInitialized) return;
  await Sentry.flush(timeoutMs);
}

module.exports = {
  sentryDsn,
  captureException,
  flushSentry,
};
