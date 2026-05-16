import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';

class AppSessionStore {
  static const _sessionKey = 'eventTimeline.session';
  static const _retainedCacheUserIdKey = 'eventTimeline.retainedCache.userId';
  static const _retainedCachePhoneKey = 'eventTimeline.retainedCache.phone';
  static const _retainedCacheExpiresAtKey = 'eventTimeline.retainedCache.expiresAt';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveSession(AuthSession session) async {
    await _prefs?.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  AuthSession? readSession() {
    final raw = _prefs?.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  bool hasPersistedSessionToken() {
    final raw = _prefs?.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return false;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return false;
    }

    final token = decoded['sessionToken'];
    return token is String && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    await _prefs?.remove(_sessionKey);
  }

  Future<void> saveRetainedCachePolicy({
    required String userId,
    String? primaryPhone,
    required DateTime expiresAt,
  }) async {
    await _prefs?.setString(_retainedCacheUserIdKey, userId);
    if (primaryPhone != null && primaryPhone.isNotEmpty) {
      await _prefs?.setString(_retainedCachePhoneKey, primaryPhone);
    } else {
      await _prefs?.remove(_retainedCachePhoneKey);
    }
    await _prefs?.setString(_retainedCacheExpiresAtKey, expiresAt.toIso8601String());
  }

  RetainedCachePolicy? readRetainedCachePolicy() {
    final userId = _prefs?.getString(_retainedCacheUserIdKey);
    final phoneNumber = _prefs?.getString(_retainedCachePhoneKey);
    final expiresAtRaw = _prefs?.getString(_retainedCacheExpiresAtKey);
    if (expiresAtRaw == null || expiresAtRaw.isEmpty) {
      return null;
    }

    final resolvedUserId =
        (userId != null && userId.isNotEmpty) ? userId : _deriveUserId(phoneNumber);
    if (resolvedUserId == null) {
      return null;
    }

    return RetainedCachePolicy(
      userId: resolvedUserId,
      primaryPhone: phoneNumber,
      expiresAt: DateTime.parse(expiresAtRaw),
    );
  }

  Future<void> clearRetainedCachePolicy() async {
    await _prefs?.remove(_retainedCacheUserIdKey);
    await _prefs?.remove(_retainedCachePhoneKey);
    await _prefs?.remove(_retainedCacheExpiresAtKey);
  }

  String? _deriveUserId(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return null;
    }
    return 'user_$phoneNumber';
  }
}

class RetainedCachePolicy {
  const RetainedCachePolicy({
    required this.userId,
    this.primaryPhone,
    required this.expiresAt,
  });

  final String userId;
  final String? primaryPhone;
  final DateTime expiresAt;

  String? get phoneNumber => primaryPhone;
}
