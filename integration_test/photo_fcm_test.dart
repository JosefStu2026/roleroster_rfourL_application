import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import 'package:roleroster_rfourl_application/providers/profile_provider.dart';
import 'package:roleroster_rfourl_application/services/profile_service.dart';
// auth_service not required for this mocked test
import 'package:roleroster_rfourl_application/services/fcm_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile upload + FCM flow (mocked)', () {
    setUpAll(() async {
      final dir = Directory.systemTemp.createTempSync('rr_test');
      Hive.init(dir.path);
      // ensure box opened/clean
      final box = await Hive.openBox('profiles');
      await box.clear();
    });

    tearDownAll(() async {
      try {
        await Hive.box('profiles').close();
      } catch (_) {}
    });

    test('ProfileProvider.changePhoto persists URL to Hive', () async {
      // Mock ProfileService
      final mockService = _MockProfileService();
      final provider = ProfileProvider(profileService: mockService);

      final url = await provider.changePhoto('test-uid', fromCamera: false);

      expect(url, 'https://example.com/test-avatar.jpg');

      final box = Hive.box('profiles');
      expect(url, isNotNull);
      expect(box.get('test-uid'), 'https://example.com/test-avatar.jpg');
    });

    test('MockAuthService save/remove token', () async {
      final mockAuth = _MockAuthService();
      final mockFcm = _MockFcmService();

      final token = await mockFcm.getToken() ?? 'mock-token';
      await mockAuth.saveFcmToken('test-uid', token);
      expect(mockAuth.savedToken, 'test-uid:mock-token');

      await mockAuth.removeFcmToken('test-uid');
      expect(mockAuth.savedToken, '');
    });
  });
}

class _MockProfileService extends ProfileService {
  @override
  Future<String?> changeProfilePhoto(String uid,
      {required bool fromCamera}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 'https://example.com/test-avatar.jpg';
  }
}

class _MockAuthService {
  String savedToken = '';

  Future<void> saveFcmToken(String uid, String token) async {
    savedToken = '$uid:$token';
  }

  Future<void> removeFcmToken(String uid) async {
    savedToken = '';
  }
}

class _MockFcmService implements FcmService {
  @override
  Future<void> init() async {}

  @override
  Future<String?> getToken() async => 'mock-token';
}
