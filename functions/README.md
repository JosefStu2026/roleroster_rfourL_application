Firebase Functions for RoleRoster (due-date checks + FCM)

Files:
- index.js: contains two functions:
  - `sendFcmOnNotification`: Firestore onCreate trigger for `notifications/{id}` that reads recipient's `fcmToken` and sends FCM via Admin SDK.
  - `scheduledDueDateCheck`: Pub/Sub scheduled function (every hour) that finds groups with `dueAt` <= now and `archived == false`, creates per-member notification docs and attempts to send FCM immediately.

Deploy steps (assumes Firebase CLI authenticated and project selected):

1. cd functions
2. npm install
3. firebase deploy --only functions

Notes:
- The functions use string ISO dates for `dueAt` (ISO8601). Ensure `dueAt` values are stored in ISO format (e.g., `2026-05-26T12:00:00.000Z`).
- Ensure Firestore indexes allow the scheduled query (`where('archived', '==', false)` + `where('dueAt', '<=', nowIso)`). If Firestore requires a composite index, deploy the index via the console or `firestore.indexes.json`.
- Cloud Scheduler must be enabled in the project; the Firebase deploy will create the schedule.
