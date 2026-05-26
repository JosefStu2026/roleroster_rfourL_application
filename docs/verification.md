Verification checklist — Profile photo upload & local FCM

This document lists manual steps and quick checks to verify profile image upload and receiving a local FCM message.

Prerequisites
- A Firebase project configured for this app and the web/android platforms.
- The app running locally (emulator, device, or web) with a signed-in user.
- Firebase Cloud Messaging enabled in the Firebase console.

1) Profile photo upload (gallery and camera)
- Open the app and sign in as a user.
- Go to Profile (tap avatar in header or Profile screen).
- Tap the avatar and choose "Take a photo".
  - Expect: Camera opens, you can capture, then the image uploads.
  - App shows a snackbar "Photo updated!" when complete.
  - The new photo is visible in the Profile screen and app header (if shown).
- Tap the avatar and choose "Choose from gallery".
  - Expect: Gallery picker opens, choose a picture.
  - App shows snackbar and updates avatar.
- Verify Firestore: open `users/{uid}` document and check the `photoUrl` field holds a valid Firebase Storage URL.
- Verify Hive cache: in the app data directory (or using code), check the `profiles` box contains an entry keyed by UID with the same URL.

2) Push token and notifications enabling
- With a logged-in user, go to Settings → Notifications.
- Toggle "Enable Push Notifications" on.
  - Expect: The UI toggles on immediately.
  - The user's Firestore document should have `notificationsEnabled: true` and `fcmToken` set.
- Toggle it off.
  - Expect: `notificationsEnabled` set to false and `fcmToken` removed from the Firestore document.

3) Token refresh handling
- With notifications enabled, retrieve the current token in the settings screen (it is displayed under "FCM Token").
- In the Firebase console or using a test utility, force a token rotation (or uninstall/reinstall the app); confirm the user's `fcmToken` field updates to the new token.

4) Receiving a local FCM message (foreground)
- With the app open on the device, send a test message to the specific token from Firebase Console: Cloud Messaging → Send your first message → Target: "Token" → paste token shown in Settings.
- Press Send.
- Expect: Foreground `onMessage` listener prints/logs the incoming message (log shown in console) and the app shows any UI you implement for foreground messages (currently logs only).

5) In-app notifications UI & badge
- Create a sample notification record in Firestore under `notifications/{id}` with `recipientId` equal to the test user's UID.
  - Fields: `recipientId`, `title`, `body`, `createdAt` (ISO string), `readAt` (omit to mark unread), `taskId`, `groupId`, `actorId`, `actorName`, `type`.
- In the app, open Dashboard; the notification bell should show a red badge with the unread count.
- Open Notifications screen; you should see the new notification listed and be able to tap it to mark as read (badge should decrement).

Developer tips
- Use `flutter run -d chrome` for quick web testing (Google sign-in + small file flow).
- Use `flutter logs` or debugger console to see message logs from `FcmService`.
- To send messages programmatically, use Firebase Admin SDK or `curl` to FCM HTTP v1 endpoint.

Notes
- This checklist is manual to avoid adding heavy integration test dependencies. If you want an automated e2e test, I can add an `integration_test` setup that exercises picking a bundled image and invoking a test FCM message flow (requires additional test Firebase credentials).