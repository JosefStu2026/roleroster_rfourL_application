# RoleRoster

RoleRoster is a Flutter + Firebase group management and task tracking app for small teams. It supports group creation, member roles, task assignment, notifications, profile updates, and group lifecycle actions such as archive and delete.

## App Details

- Cross-platform Flutter app for Android, iOS, web, and desktop targets supported by Flutter.
- Firebase-backed features:
	- Authentication
	- Firestore data storage
	- Profile photo uploads with Firebase Storage
	- Push notifications with Firebase Cloud Messaging
	- Server-side notification delivery via Cloud Functions
- Built for private group use, such as a small team or class project.

## How To Try The App

### Option 1: Install the APK on an Android device

Use the built debug APK:

[RoleRoster_RfourL.apk]([build/app/outputs/flutter-apk/app-debug.apk](https://drive.google.com/file/d/1WQWGCnL4eGuyavfJf62Ghtff-X56Jxvi/view?usp=sharing))

Steps:

1. Download the APK file from this workspace or share it to your phone through Drive, OneDrive, Telegram, or USB.
2. On the device, allow installs from unknown apps for the app you used to open the file.
3. Open the APK file and install it.
4. Sign in or create an account.
5. Create a group, add members, assign tasks, and test notifications.

How to download it:

1. Click the `app-debug.apk` link above.
2. In the file viewer, use the download/save option if available, or open the APK location in your file explorer and copy the file to a shareable folder.
3. Send that APK file to the other Android devices.

### Option 2: Run from the Flutter project

If you want to run the app locally during development:

```bash
flutter pub get
flutter run
```

## Quick Test Checklist

1. Install the APK on at least two Android devices.
2. Create accounts for each tester.
3. Create one group with a leader and at least one member.
4. Confirm user profile data and FCM tokens are written to Firestore.
5. Create a task or trigger a notification and verify that other devices receive the push.

## Notes

- If you use Google sign-in on Android, make sure the Firebase Android app configuration and SHA-1 fingerprint are set correctly.
- If notifications are not arriving, confirm Cloud Functions are deployed and each device has a valid FCM token.
- The app is intended for private sharing among a small group and does not require Play Store distribution.
