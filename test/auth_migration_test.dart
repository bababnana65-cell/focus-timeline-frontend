import 'dart:convert';

import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TimelineController? controller;

  tearDown(() {
    controller?.dispose();
    controller = null;
  });

  test('stores and restores formal auth session fields', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    final session = AuthSession(
      userId: 'user_001',
      sessionToken: 'sess_001',
      refreshToken: 'refresh_001',
      issuedAt: DateTime(2026, 4, 18, 9, 0),
      expiresAt: DateTime(2026, 4, 25, 9, 0),
      identityType: 'phone',
      provider: 'sms',
      primaryPhone: '13812345678',
    );

    await storage.saveSession(session);

    final restored = storage.readSession();

    expect(restored, isNotNull);
    expect(restored!.userId, 'user_001');
    expect(restored.sessionToken, 'sess_001');
    expect(restored.refreshToken, 'refresh_001');
    expect(restored.identityType, 'phone');
    expect(restored.provider, 'sms');
    expect(restored.phoneNumber, '13812345678');
    expect(restored.loggedInAt, DateTime(2026, 4, 18, 9, 0));
  });

  test('restores legacy auth session payload into formal auth session model', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'eventTimeline.session': jsonEncode(<String, String>{
        'phoneNumber': '13812345678',
        'loggedInAt': DateTime(2026, 4, 18, 9, 0).toIso8601String(),
      }),
    });

    final storage = AppLocalStorage();
    await storage.init();

    final restored = storage.readSession();

    expect(restored, isNotNull);
    expect(restored!.userId, 'user_13812345678');
    expect(restored.sessionToken, isNotEmpty);
    expect(restored.primaryPhone, '13812345678');
    expect(restored.identityType, 'phone');
    expect(restored.provider, 'sms');
    expect(restored.loggedInAt, DateTime(2026, 4, 18, 9, 0));
  });

  test('mock phone auth service returns formal auth session model', () async {
    final authService = MockPhoneAuthService();

    final challenge = await authService.sendVerificationCode('13812345678');
    expect(challenge.cooldownSeconds, 60);
    expect(challenge.expiresInSeconds, 60);
    final session = await authService.verifyCode(
      phoneNumber: '13812345678',
      code: challenge.debugCode!,
    );

    expect(session.userId, 'user_13812345678');
    expect(session.sessionToken, isNotEmpty);
    expect(session.identityType, 'phone');
    expect(session.provider, 'sms');
    expect(session.phoneNumber, '13812345678');
    expect(session.expiresAt.isAfter(session.issuedAt), isTrue);
  });

  test('invalidates legacy persisted session when http backend mode is enabled', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'eventTimeline.session': jsonEncode(<String, String>{
        'phoneNumber': '13812345678',
        'loggedInAt': DateTime(2026, 4, 18, 9, 0).toIso8601String(),
      }),
    });

    final storage = AppLocalStorage();
    await storage.init();

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
      preferServerRuntimeTopics: true,
    );

    await controller!.initialize();

    expect(controller!.isRegistered, isFalse);
    expect(storage.readSession(), isNull);
    expect(storage.readRetainedCachePolicy()?.userId, 'user_13812345678');
    expect(storage.readRetainedCachePolicy()?.phoneNumber, '13812345678');
  });
}
