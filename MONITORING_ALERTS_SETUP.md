# 📊 Monitoring & Alerts Setup Guide

## Overview
This guide helps you set up monitoring and alerts for Kattrick's Cloud Functions and Firestore.

---

## Option 1: Firebase Console (Quick & Easy)

### Function Error Alerts

1. Open [Firebase Console - Functions](https://console.firebase.google.com/project/kickabout-ddc06/functions)
2. Click on any function
3. Click "Metrics" tab
4. Review:
   - **Invocations**: Total calls
   - **Execution time**: Performance
   - **Error rate**: Failures
   - **Memory usage**: Resource usage

### View Logs

```bash
# Watch all function logs
firebase functions:log --project kickabout-ddc06

# Watch specific function
firebase functions:log --only searchVenues --project kickabout-ddc06

# Follow logs in real-time
firebase functions:log --follow --project kickabout-ddc06
```

---

## Option 2: Google Cloud Monitoring (Advanced)

### Create Error Rate Alert

1. Go to [Cloud Console - Monitoring](https://console.cloud.google.com/monitoring/alerting?project=kickabout-ddc06)
2. Click "Create Policy"
3. Configure:
   - **Resource type**: Cloud Function
   - **Metric**: `Executions` > `Error rate`
   - **Condition**: `When any time series violates`
   - **Threshold**: `> 5%` for `1 minute`
4. Add notification channel (email, SMS, Slack)
5. Click "Create Policy"

### Create High Memory Usage Alert

1. Create Policy
2. Configure:
   - **Resource type**: Cloud Function
   - **Metric**: `Memory utilization`
   - **Condition**: `> 80%` for `5 minutes`
3. Add notification
4. Save

### Create Slow Response Alert

1. Create Policy
2. Configure:
   - **Resource type**: Cloud Function
   - **Metric**: `Execution time`
   - **Condition**: `> 10 seconds` (adjust per function)
3. Add notification
4. Save

---

## Option 3: Rate Limit Monitoring

### Watch Rate Limit Logs

```bash
# Filter for rate limit events
firebase functions:log --project kickabout-ddc06 | grep "Rate limit"

# Watch for exceeded limits (warnings)
firebase functions:log --project kickabout-ddc06 | grep "Rate limit exceeded"
```

### Create Rate Limit Alert

1. Go to Cloud Console - Monitoring
2. Create Log-based Alert:
   - **Log filter**:
     ```
     resource.type="cloud_function"
     jsonPayload.message="Rate limit exceeded"
     ```
   - **Threshold**: `> 10` occurrences in `1 minute`
3. Add notification
4. Save

---

## Option 4: Firestore Monitoring

### Check Firestore Usage

1. Open [Firebase Console - Firestore](https://console.firebase.google.com/project/kickabout-ddc06/firestore)
2. Click "Usage" tab
3. Monitor:
   - **Document reads**: Should stay under quota
   - **Document writes**: Track costs
   - **Storage**: Total data size

### Create Firestore Alert

1. Cloud Console - Monitoring
2. Create Alert:
   - **Metric**: `Firestore/Document reads`
   - **Condition**: `> 1,000,000` per day (adjust based on your quota)
3. Add notification
4. Save

---

## Notification Channels

### Email Notifications

1. Go to [Cloud Console - Notification Channels](https://console.cloud.google.com/monitoring/alerting/notifications?project=kickabout-ddc06)
2. Click "Add new"
3. Select "Email"
4. Enter email address
5. Verify email
6. Save

### Slack Notifications (Optional)

1. Go to Notification Channels
2. Click "Add new"
3. Select "Slack"
4. Follow setup wizard
5. Connect Slack workspace
6. Choose channel
7. Save

---

## Key Metrics to Monitor

### Critical Alerts (Set up immediately)
- ⚠️ Function error rate > 5%
- ⚠️ Rate limit exceeded > 10/minute
- ⚠️ Firestore reads > quota

### Important Alerts (Set up soon)
- Memory usage > 80%
- Execution time > 10s
- Daily active users spike

### Nice-to-Have Alerts
- Low user engagement
- Cost spike
- Storage near quota

---

## Testing Alerts

### Test Function Error Alert

```bash
# Trigger an intentional error
firebase functions:shell

# In shell:
searchVenues({ invalidData: true })
```

### Test Rate Limit Alert

```bash
# Make 15 rapid requests to trigger rate limit
# Use the test_rate_limiting.md guide
```

---

## Automated Monitoring Script

Create a simple monitoring script:

```bash
#!/bin/bash
# monitor.sh

echo "🔍 Checking Firebase Functions status..."

# Check for errors in last 5 minutes
firebase functions:log --project kickabout-ddc06 --limit 100 | grep "error" > /tmp/errors.log

ERROR_COUNT=$(wc -l < /tmp/errors.log)

if [ $ERROR_COUNT -gt 5 ]; then
  echo "⚠️ WARNING: $ERROR_COUNT errors in last 5 minutes!"
  cat /tmp/errors.log
else
  echo "✅ All systems operational ($ERROR_COUNT errors)"
fi
```

Run it periodically:
```bash
# Run every 5 minutes
watch -n 300 ./monitor.sh
```

---

## Dashboard Setup (Optional)

### Create Custom Dashboard

1. Go to [Cloud Console - Dashboards](https://console.cloud.google.com/monitoring/dashboards?project=kickabout-ddc06)
2. Click "Create Dashboard"
3. Name it "Kattrick Functions"
4. Add charts:
   - Function invocations (line chart)
   - Error rate (gauge)
   - Memory usage (line chart)
   - Execution time (heatmap)
   - Rate limit events (counter)
5. Save

---

## Useful Commands

```bash
# Check function status
firebase functions:list --project kickabout-ddc06

# Check recent logs
firebase functions:log --limit 50 --project kickabout-ddc06

# Monitor specific function
firebase functions:log --only searchVenues --follow --project kickabout-ddc06

# Check Firestore usage
firebase firestore:metrics --project kickabout-ddc06
```

---

## Cost Monitoring

### Set Budget Alert

1. Go to [Cloud Console - Billing](https://console.cloud.google.com/billing)
2. Select your project
3. Click "Budgets & alerts"
4. Click "Create budget"
5. Set budget: $50/month (adjust as needed)
6. Set alerts at: 50%, 90%, 100%
7. Save

---

## Success Criteria

- [ ] Email notifications configured
- [ ] Error rate alert created
- [ ] Rate limit monitoring active
- [ ] Logs reviewed regularly
- [ ] Budget alert set up
- [ ] Dashboard created (optional)

---

**Status:** ✅ Guide complete - follow steps above to enable alerts
**Next Step:** Test alerts and verify notifications work

