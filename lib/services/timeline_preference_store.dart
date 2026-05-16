import 'package:shared_preferences/shared_preferences.dart';

import '../models/timeline_models.dart';

class TimelinePreferenceStore {
  static const _trackedTopicsKey = 'eventTimeline.trackedTopics';
  static const _guestTrackedTopicsKey = 'eventTimeline.guestTrackedTopics';
  static const _pinnedTopicsKey = 'eventTimeline.pinnedTopics';
  static const _historyTopicsKey = 'eventTimeline.historyTopics';
  static const _selectedTopicKey = 'eventTimeline.selectedTopic';
  static const _sortOrderKey = 'eventTimeline.sortOrder';
  static const _guestKeyKey = 'eventTimeline.guestKey';
  static const _guestCreatedTopicIdsKey = 'eventTimeline.guestCreatedTopicIds';
  static const _interestCategoryIdsKey =
      'eventTimeline.userInterestCategoryIds';
  static const _pushDeviceIdKey = 'eventTimeline.pushDeviceId';
  static const _pushDeviceTokenKey = 'eventTimeline.pushDeviceToken';
  static const _legacyPinnedTopicKey = 'eventTimeline.pinnedTopic';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveTrackedTopicIds(List<String> topicIds) async {
    await _prefs?.setStringList(_trackedTopicsKey, topicIds);
  }

  List<String> readTrackedTopicIds() {
    return _prefs?.getStringList(_trackedTopicsKey) ?? const <String>[];
  }

  bool hasTrackedTopicIds() {
    return _prefs?.containsKey(_trackedTopicsKey) ?? false;
  }

  Future<void> clearTrackedTopicIds() async {
    await _prefs?.remove(_trackedTopicsKey);
  }

  Future<void> saveGuestTrackedTopicIds(List<String> topicIds) async {
    if (topicIds.isEmpty) {
      await _prefs?.remove(_guestTrackedTopicsKey);
      return;
    }
    await _prefs?.setStringList(_guestTrackedTopicsKey, topicIds);
  }

  List<String> readGuestTrackedTopicIds() {
    return _prefs?.getStringList(_guestTrackedTopicsKey) ?? const <String>[];
  }

  bool hasGuestTrackedTopicIds() {
    return _prefs?.containsKey(_guestTrackedTopicsKey) ?? false;
  }

  Future<void> clearGuestTrackedTopicIds() async {
    await _prefs?.remove(_guestTrackedTopicsKey);
  }

  Future<void> savePinnedTopicIds(List<String> topicIds) async {
    if (topicIds.isEmpty) {
      await _prefs?.remove(_pinnedTopicsKey);
      return;
    }
    await _prefs?.setStringList(_pinnedTopicsKey, topicIds);
  }

  List<String> readPinnedTopicIds() {
    final pinnedTopics = _prefs?.getStringList(_pinnedTopicsKey);
    if (pinnedTopics != null) {
      return pinnedTopics;
    }

    final legacyPinnedTopic = _prefs?.getString(_legacyPinnedTopicKey);
    if (legacyPinnedTopic == null || legacyPinnedTopic.isEmpty) {
      return const <String>[];
    }

    return <String>[legacyPinnedTopic];
  }

  Future<void> clearPinnedTopicIds() async {
    await _prefs?.remove(_pinnedTopicsKey);
    await _prefs?.remove(_legacyPinnedTopicKey);
  }

  Future<void> saveHistoryTopicIds(List<String> topicIds) async {
    if (topicIds.isEmpty) {
      await _prefs?.remove(_historyTopicsKey);
      return;
    }
    await _prefs?.setStringList(_historyTopicsKey, topicIds);
  }

  List<String> readHistoryTopicIds() {
    return _prefs?.getStringList(_historyTopicsKey) ?? const <String>[];
  }

  Future<void> clearHistoryTopicIds() async {
    await _prefs?.remove(_historyTopicsKey);
  }

  Future<void> saveSelectedTopicId(String? topicId) async {
    if (topicId == null || topicId.isEmpty) {
      await _prefs?.remove(_selectedTopicKey);
      return;
    }
    await _prefs?.setString(_selectedTopicKey, topicId);
  }

  String? readSelectedTopicId() {
    return _prefs?.getString(_selectedTopicKey);
  }

  Future<void> clearSelectedTopicId() async {
    await _prefs?.remove(_selectedTopicKey);
  }

  Future<void> saveSortOrder(TimelineSortOrder sortOrder) async {
    await _prefs?.setString(_sortOrderKey, sortOrder.name);
  }

  TimelineSortOrder readSortOrder() {
    final raw = _prefs?.getString(_sortOrderKey);
    for (final order in TimelineSortOrder.values) {
      if (order.name == raw) {
        return order;
      }
    }
    return TimelineSortOrder.chronological;
  }

  Future<void> saveGuestKey(String guestKey) async {
    await _prefs?.setString(_guestKeyKey, guestKey);
  }

  String? readGuestKey() {
    return _prefs?.getString(_guestKeyKey);
  }

  Future<void> saveGuestCreatedTopicIds(List<String> topicIds) async {
    if (topicIds.isEmpty) {
      await _prefs?.remove(_guestCreatedTopicIdsKey);
      return;
    }
    await _prefs?.setStringList(_guestCreatedTopicIdsKey, topicIds);
  }

  List<String> readGuestCreatedTopicIds() {
    return _prefs?.getStringList(_guestCreatedTopicIdsKey) ?? const <String>[];
  }

  Future<void> clearGuestCreatedTopicIds() async {
    await _prefs?.remove(_guestCreatedTopicIdsKey);
  }

  Future<void> saveInterestCategoryIds(List<String> categoryIds) async {
    if (categoryIds.isEmpty) {
      await _prefs?.remove(_interestCategoryIdsKey);
      return;
    }
    await _prefs?.setStringList(_interestCategoryIdsKey, categoryIds);
  }

  List<String> readInterestCategoryIds() {
    return _prefs?.getStringList(_interestCategoryIdsKey) ?? const <String>[];
  }

  Future<void> savePushDeviceId(String deviceId) async {
    await _prefs?.setString(_pushDeviceIdKey, deviceId);
  }

  String? readPushDeviceId() {
    return _prefs?.getString(_pushDeviceIdKey);
  }

  Future<void> savePushDeviceToken(String pushToken) async {
    await _prefs?.setString(_pushDeviceTokenKey, pushToken);
  }

  String? readPushDeviceToken() {
    return _prefs?.getString(_pushDeviceTokenKey);
  }
}
