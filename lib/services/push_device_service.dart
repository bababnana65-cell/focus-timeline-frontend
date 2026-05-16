import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'app_local_storage.dart';

const String _defaultPushAppVersion = String.fromEnvironment(
  'TIMELINESS_APP_VERSION',
  defaultValue: '0.1.0+1',
);

void _logPushDebug(String message) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('[push] $message');
}

String _maskDebugValue(String value) {
  if (value.length <= 16) {
    return value;
  }
  final prefix = value.substring(0, 8);
  final suffix = value.substring(value.length - 6);
  return '$prefix...$suffix';
}

class PushDevicePayload {
  const PushDevicePayload({
    required this.deviceId,
    required this.platform,
    required this.pushToken,
    required this.appVersion,
    required this.enabled,
  });

  final String deviceId;
  final String platform;
  final String pushToken;
  final String appVersion;
  final bool enabled;
}

abstract class PushDeviceService {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<PushDevicePayload?> prepareDevicePayload();

  Future<String> ensureDeviceId();

  Future<String?> consumeInitialTopicId();

  Stream<String> get openedTopicIds;

  void dispose();
}

PushDeviceService createPushDeviceService({
  required AppLocalStorage localStorage,
}) {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    return FirebasePushDeviceService(localStorage: localStorage);
  }

  return LocalPushDeviceService(localStorage: localStorage);
}

class LocalPushDeviceService implements PushDeviceService {
  LocalPushDeviceService({
    required AppLocalStorage localStorage,
  }) : _localStorage = localStorage;

  final AppLocalStorage _localStorage;

  @override
  Stream<String> get openedTopicIds => const Stream<String>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    return true;
  }

  @override
  Future<PushDevicePayload?> prepareDevicePayload() async {
    final granted = await requestPermission();
    if (!granted) {
      return null;
    }

    final deviceId = await _localStorage.ensurePushDeviceId();
    final pushToken = await _localStorage.ensurePushDeviceToken();
    return PushDevicePayload(
      deviceId: deviceId,
      platform: _resolvePlatform(),
      pushToken: pushToken,
      appVersion: _defaultPushAppVersion,
      enabled: true,
    );
  }

  @override
  Future<String> ensureDeviceId() {
    return _localStorage.ensurePushDeviceId();
  }

  @override
  Future<String?> consumeInitialTopicId() async {
    return null;
  }

  @override
  void dispose() {}

  String _resolvePlatform() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows => 'windows',
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}

class FirebasePushDeviceService implements PushDeviceService {
  FirebasePushDeviceService({
    required AppLocalStorage localStorage,
  }) : _localStorage = localStorage;

  final AppLocalStorage _localStorage;
  final StreamController<String> _openedTopicIdsController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  AuthorizationStatus _authorizationStatus = AuthorizationStatus.notDetermined;
  String? _initialTopicId;
  bool _initialized = false;

  @override
  Stream<String> get openedTopicIds => _openedTopicIdsController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await Firebase.initializeApp();
    _logPushDebug('Firebase initialized on ${_resolvePlatform()}');
    final settings = await FirebaseMessaging.instance.requestPermission();
    _authorizationStatus = settings.authorizationStatus;
    _logPushDebug(
        'Notification permission: ${settings.authorizationStatus.name}');

    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // Android ignores this; keep iOS-compatible setup without failing init.
    }

    final token = await _tryGetToken('initialization');
    if (token != null && token.isNotEmpty) {
      await _localStorage.savePushDeviceToken(token);
      _logPushDebug('FCM token acquired: ${_maskDebugValue(token)}');
    } else {
      _logPushDebug('FCM token is empty after initialization');
    }

    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      if (token.isEmpty) {
        return;
      }
      unawaited(_localStorage.savePushDeviceToken(token));
      _logPushDebug('FCM token refreshed: ${_maskDebugValue(token)}');
    });

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      (message) {
        _logPushDebug(
          'Foreground push received: ${_describeMessageForDebug(message)}',
        );
      },
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _logPushDebug(
        'Initial notification payload: '
        '${_describeMessageForDebug(initialMessage)}',
      );
    }
    _initialTopicId = _extractTopicId(initialMessage);
    if (_initialTopicId != null && _initialTopicId!.isNotEmpty) {
      _logPushDebug('Initial notification topicId=$_initialTopicId');
    } else if (initialMessage != null) {
      _logPushDebug('Initial notification has no routable topicId');
    }

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        _logPushDebug(
          'Notification opened payload: ${_describeMessageForDebug(message)}',
        );
        final topicId = _extractTopicId(message);
        if (topicId == null || topicId.isEmpty) {
          _logPushDebug('Notification opened without routable topicId');
          return;
        }
        _logPushDebug('Notification opened app with topicId=$topicId');
        _openedTopicIdsController.add(topicId);
      },
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (!_initialized) {
      await initialize();
    }
    return _authorizationStatus == AuthorizationStatus.authorized ||
        _authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<PushDevicePayload?> prepareDevicePayload() async {
    final granted = await requestPermission();
    if (!granted) {
      _logPushDebug(
          'Push device payload skipped: notification permission not granted');
      return null;
    }

    final deviceId = await _localStorage.ensurePushDeviceId();
    final currentToken = await _tryGetToken('payload preparation');
    if (currentToken == null || currentToken.isEmpty) {
      _logPushDebug('Push device payload skipped: FCM token missing');
      return null;
    }
    await _localStorage.savePushDeviceToken(currentToken);
    _logPushDebug(
      'Prepared push payload deviceId=${_maskDebugValue(deviceId)}, '
      'token=${_maskDebugValue(currentToken)}',
    );

    return PushDevicePayload(
      deviceId: deviceId,
      platform: _resolvePlatform(),
      pushToken: currentToken,
      appVersion: _defaultPushAppVersion,
      enabled: true,
    );
  }

  @override
  Future<String> ensureDeviceId() {
    return _localStorage.ensurePushDeviceId();
  }

  @override
  Future<String?> consumeInitialTopicId() async {
    final topicId = _initialTopicId;
    _initialTopicId = null;
    return topicId;
  }

  @override
  void dispose() {
    unawaited(_tokenRefreshSubscription?.cancel());
    unawaited(_foregroundMessageSubscription?.cancel());
    unawaited(_openedAppSubscription?.cancel());
    unawaited(_openedTopicIdsController.close());
  }

  String? _extractTopicId(RemoteMessage? message) {
    if (message == null) {
      return null;
    }

    final data = message.data;
    final directTopicId = (data['topicId'] ??
            data['topic_id'] ??
            data['topicID'] ??
            data['topic-id'] ??
            data['topic'])
        ?.toString();
    if (directTopicId != null && directTopicId.isNotEmpty) {
      return directTopicId;
    }

    final rawRoute = (data['route'] ??
            data['deepLink'] ??
            data['deep_link'] ??
            data['url'] ??
            data['link'])
        ?.toString();
    if (rawRoute == null || rawRoute.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(rawRoute);
    if (uri == null) {
      return null;
    }

    final queryTopicId =
        uri.queryParameters['topicId'] ?? uri.queryParameters['topic_id'];
    if (queryTopicId != null && queryTopicId.isNotEmpty) {
      return queryTopicId;
    }

    final segments = uri.pathSegments;
    final topicSegmentIndex = segments.indexWhere(
      (segment) => segment == 'topic' || segment == 'topics',
    );
    if (topicSegmentIndex >= 0 && topicSegmentIndex + 1 < segments.length) {
      final pathTopicId = segments[topicSegmentIndex + 1];
      if (pathTopicId.isNotEmpty) {
        return pathTopicId;
      }
    }

    return null;
  }

  String _describeMessageForDebug(RemoteMessage message) {
    final title = message.notification?.title;
    final body = message.notification?.body;
    return 'messageId=${message.messageId}, '
        'data=${message.data}, '
        'title=$title, body=$body';
  }

  Future<String?> _tryGetToken(String phase) async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      _logPushDebug('FCM token unavailable during $phase: $error');
      return null;
    }
  }

  String _resolvePlatform() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.windows => 'windows',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
