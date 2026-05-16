import '../models/auth_models.dart';
import '../models/timeline_models.dart';
import '../dto/followed_topic_dto.dart';
import 'package:flutter/foundation.dart';
import 'app_session_store.dart';
import 'timeline_preference_store.dart';
import 'topic_cache_store.dart';
import 'dart:math';

class AppLocalStorage {
  AppLocalStorage({
    AppSessionStore? sessionStore,
    TimelinePreferenceStore? preferenceStore,
    TopicCacheStore? topicCacheStore,
  })  : _sessionStore = sessionStore ?? AppSessionStore(),
        _preferenceStore = preferenceStore ?? TimelinePreferenceStore(),
        _topicCacheStore = topicCacheStore ?? TopicCacheStore();

  final AppSessionStore _sessionStore;
  final TimelinePreferenceStore _preferenceStore;
  final TopicCacheStore _topicCacheStore;

  Future<void> init() async {
    await _sessionStore.init();
    await _preferenceStore.init();
    await _topicCacheStore.init();
  }

  Future<void> saveSession(AuthSession session) async {
    await _sessionStore.saveSession(session);
  }

  AuthSession? readSession() {
    return _sessionStore.readSession();
  }

  bool hasPersistedSessionToken() {
    return _sessionStore.hasPersistedSessionToken();
  }

  Future<void> clearSession() async {
    await _sessionStore.clearSession();
  }

  Future<void> saveRetainedCachePolicy({
    required String userId,
    String? primaryPhone,
    required DateTime expiresAt,
  }) async {
    await _sessionStore.saveRetainedCachePolicy(
      userId: userId,
      primaryPhone: primaryPhone,
      expiresAt: expiresAt,
    );
  }

  RetainedCachePolicy? readRetainedCachePolicy() {
    return _sessionStore.readRetainedCachePolicy();
  }

  Future<void> clearRetainedCachePolicy() async {
    await _sessionStore.clearRetainedCachePolicy();
  }

  Future<void> saveTrackedTopicIds(List<String> topicIds) async {
    await _preferenceStore.saveTrackedTopicIds(topicIds);
  }

  List<String> readTrackedTopicIds() {
    return _preferenceStore.readTrackedTopicIds();
  }

  bool hasTrackedTopicIds() {
    return _preferenceStore.hasTrackedTopicIds();
  }

  Future<void> clearTrackedTopicIds() async {
    await _preferenceStore.clearTrackedTopicIds();
  }

  Future<void> saveGuestTrackedTopicIds(List<String> topicIds) async {
    await _preferenceStore.saveGuestTrackedTopicIds(topicIds);
  }

  List<String> readGuestTrackedTopicIds() {
    return _preferenceStore.readGuestTrackedTopicIds();
  }

  bool hasGuestTrackedTopicIds() {
    return _preferenceStore.hasGuestTrackedTopicIds();
  }

  Future<void> clearGuestTrackedTopicIds() async {
    await _preferenceStore.clearGuestTrackedTopicIds();
  }

  Future<void> savePinnedTopicIds(List<String> topicIds) async {
    await _preferenceStore.savePinnedTopicIds(topicIds);
  }

  List<String> readPinnedTopicIds() {
    return _preferenceStore.readPinnedTopicIds();
  }

  Future<void> clearPinnedTopicIds() async {
    await _preferenceStore.clearPinnedTopicIds();
  }

  Future<void> saveHistoryTopicIds(List<String> topicIds) async {
    await _preferenceStore.saveHistoryTopicIds(topicIds);
  }

  List<String> readHistoryTopicIds() {
    return _preferenceStore.readHistoryTopicIds();
  }

  Future<void> clearHistoryTopicIds() async {
    await _preferenceStore.clearHistoryTopicIds();
  }

  Future<void> saveInterestCategoryIds(List<String> categoryIds) async {
    await _preferenceStore.saveInterestCategoryIds(categoryIds);
  }

  List<String> readInterestCategoryIds() {
    return _preferenceStore.readInterestCategoryIds();
  }

  Future<void> saveSelectedTopicId(String? topicId) async {
    await _preferenceStore.saveSelectedTopicId(topicId);
  }

  String? readSelectedTopicId() {
    return _preferenceStore.readSelectedTopicId();
  }

  Future<void> clearSelectedTopicId() async {
    await _preferenceStore.clearSelectedTopicId();
  }

  Future<void> saveSortOrder(TimelineSortOrder sortOrder) async {
    await _preferenceStore.saveSortOrder(sortOrder);
  }

  TimelineSortOrder readSortOrder() {
    return _preferenceStore.readSortOrder();
  }

  Future<String> ensureGuestKey() async {
    final existing = _preferenceStore.readGuestKey();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _generateGuestKey();
    await _preferenceStore.saveGuestKey(generated);
    return generated;
  }

  String? readGuestKey() {
    return _preferenceStore.readGuestKey();
  }

  Future<String> ensurePushDeviceId() async {
    final existing = _preferenceStore.readPushDeviceId();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _generateStableKey(_devicePrefix());
    await _preferenceStore.savePushDeviceId(generated);
    return generated;
  }

  String? readPushDeviceId() {
    return _preferenceStore.readPushDeviceId();
  }

  Future<void> savePushDeviceId(String deviceId) async {
    await _preferenceStore.savePushDeviceId(deviceId);
  }

  Future<String> ensurePushDeviceToken() async {
    final existing = _preferenceStore.readPushDeviceToken();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _generateStableKey(_pushTokenPrefix());
    await _preferenceStore.savePushDeviceToken(generated);
    return generated;
  }

  String? readPushDeviceToken() {
    return _preferenceStore.readPushDeviceToken();
  }

  Future<void> savePushDeviceToken(String pushToken) async {
    await _preferenceStore.savePushDeviceToken(pushToken);
  }

  Future<void> saveGuestCreatedTopicIds(List<String> topicIds) async {
    await _preferenceStore.saveGuestCreatedTopicIds(topicIds);
  }

  List<String> readGuestCreatedTopicIds() {
    return _preferenceStore.readGuestCreatedTopicIds();
  }

  Future<void> clearGuestCreatedTopicIds() async {
    await _preferenceStore.clearGuestCreatedTopicIds();
  }

  Future<void> saveFollowedTopicSnapshot(FollowedTopicListDto payload) async {
    await _topicCacheStore.saveFollowedTopicSnapshot(payload);
  }

  FollowedTopicCacheSnapshot? readFollowedTopicSnapshot() {
    return _topicCacheStore.readFollowedTopicSnapshot();
  }

  Future<void> clearFollowedTopicSnapshot() async {
    await _topicCacheStore.clearFollowedTopicSnapshot();
  }

  Future<void> saveGuestTrackedTopics(List<Topic> topics) async {
    await _topicCacheStore.saveGuestTrackedTopics(topics);
  }

  List<Topic> readGuestTrackedTopics() {
    return _topicCacheStore.readGuestTrackedTopics();
  }

  Future<void> clearGuestTrackedTopics() async {
    await _topicCacheStore.clearGuestTrackedTopics();
  }

  Future<void> saveCustomTopics(List<Topic> topics) async {
    await _topicCacheStore.saveCustomTopics(topics);
  }

  List<Topic> readCustomTopics() {
    return _topicCacheStore.readCustomTopics();
  }

  Future<void> saveCustomEntries(
      Map<String, List<TimelineEntry>> entriesByTopic) async {
    await _topicCacheStore.saveCustomEntries(entriesByTopic);
  }

  Map<String, List<TimelineEntry>> readCustomEntries() {
    return _topicCacheStore.readCustomEntries();
  }

  Future<void> saveSharedTopics(List<Topic> topics) async {
    await _topicCacheStore.saveSharedTopics(topics);
  }

  List<Topic> readSharedTopics() {
    return _topicCacheStore.readSharedTopics();
  }

  Future<void> clearSharedTopics() async {
    await _topicCacheStore.clearSharedTopics();
  }

  Future<void> saveSharedEntries(
      Map<String, List<TimelineEntry>> entriesByTopic) async {
    await _topicCacheStore.saveSharedEntries(entriesByTopic);
  }

  Map<String, List<TimelineEntry>> readSharedEntries() {
    return _topicCacheStore.readSharedEntries();
  }

  Future<void> clearSharedEntries() async {
    await _topicCacheStore.clearSharedEntries();
  }

  Future<void> saveFavoriteTimelineNodes(
    List<FavoriteTimelineNode> nodes,
  ) async {
    await _topicCacheStore.saveFavoriteTimelineNodes(nodes);
  }

  List<FavoriteTimelineNode> readFavoriteTimelineNodes() {
    return _topicCacheStore.readFavoriteTimelineNodes();
  }

  String _generateGuestKey() {
    return _generateStableKey('guest');
  }

  String _devicePrefix() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android-device',
      TargetPlatform.iOS => 'ios-device',
      TargetPlatform.windows => 'windows-device',
      TargetPlatform.macOS => 'macos-device',
      TargetPlatform.linux => 'linux-device',
      TargetPlatform.fuchsia => 'fuchsia-device',
    };
  }

  String _pushTokenPrefix() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android-push',
      TargetPlatform.iOS => 'ios-push',
      TargetPlatform.windows => 'windows-push',
      TargetPlatform.macOS => 'macos-push',
      TargetPlatform.linux => 'linux-push',
      TargetPlatform.fuchsia => 'fuchsia-push',
    };
  }

  String _generateStableKey(String prefix) {
    final random = Random();
    final millis = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final suffix = List<String>.generate(
      4,
      (_) => random.nextInt(0x10000).toRadixString(16).padLeft(4, '0'),
    ).join();
    return '$prefix-$millis-$suffix';
  }
}
