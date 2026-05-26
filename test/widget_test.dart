import 'package:firebase_core/firebase_core.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roleroster_rfourl_application/firebase_options.dart';
import 'package:roleroster_rfourl_application/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await fb.Firebase.initializeApp(options: _testFirebaseOptions());
    await tester.pumpWidget(const RoleRosterApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

fb.FirebaseOptions _testFirebaseOptions() {
  final options = DefaultFirebaseOptions.currentPlatform;
  return fb.FirebaseOptions(
    apiKey: options.apiKey,
    appId: options.appId,
    messagingSenderId: options.messagingSenderId,
    projectId: options.projectId,
    authDomain: options.authDomain,
    storageBucket: options.storageBucket,
    measurementId: options.measurementId,
    iosClientId: options.iosClientId,
    iosBundleId: options.iosBundleId,
  );
}
