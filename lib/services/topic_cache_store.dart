import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../dto/followed_topic_dto.dart';
import '../models/timeline_models.dart';

class TopicCacheStore {
  static const _followedTopicsSnapshotKey =
      'eventTimeline.followedTopics.snapshot';
  static const _guestTrackedTopicsSnapshotKey =
      'eventTimeline.guestTrackedTopics.snapshot';
  static const _customTopicsKey = 'eventTimeline.customTopics';
  static const _customEntriesKey = 'eventTimeline.customEntries';
  static const _sharedTopicsKey = 'eventTimeline.sharedTopics';
  static const _sharedEntriesKey = 'eventTimeline.sharedEntries';
  static const _favoriteTimelineNodesKey =
      'eventTimeline.favoriteTimelineNodes';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveFollowedTopicSnapshot(FollowedTopicListDto payload) async {
    final snapshot = FollowedTopicCacheSnapshot(
      payload: payload,
      cachedAt: DateTime.now(),
    );
    await _prefs?.setString(
      _followedTopicsSnapshotKey,
      jsonEncode(snapshot.toJson()),
    );
  }

  FollowedTopicCacheSnapshot? readFollowedTopicSnapshot() {
    final raw = _prefs?.getString(_followedTopicsSnapshotKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return FollowedTopicCacheSnapshot.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> clearFollowedTopicSnapshot() async {
    await _prefs?.remove(_followedTopicsSnapshotKey);
  }

  Future<void> saveGuestTrackedTopics(List<Topic> topics) async {
    await _saveTopics(_guestTrackedTopicsSnapshotKey, topics);
  }

  List<Topic> readGuestTrackedTopics() {
    return _readTopics(_guestTrackedTopicsSnapshotKey);
  }

  Future<void> clearGuestTrackedTopics() async {
    await _prefs?.remove(_guestTrackedTopicsSnapshotKey);
  }

  Future<void> saveCustomTopics(List<Topic> topics) async {
    await _saveTopics(_customTopicsKey, topics);
  }

  List<Topic> readCustomTopics() {
    return _readTopics(_customTopicsKey);
  }

  Future<void> saveCustomEntries(
      Map<String, List<TimelineEntry>> entriesByTopic) async {
    await _saveEntries(_customEntriesKey, entriesByTopic);
  }

  Map<String, List<TimelineEntry>> readCustomEntries() {
    return _readEntries(_customEntriesKey);
  }

  Future<void> saveSharedTopics(List<Topic> topics) async {
    await _saveTopics(_sharedTopicsKey, topics);
  }

  List<Topic> readSharedTopics() {
    return _readTopics(_sharedTopicsKey);
  }

  Future<void> clearSharedTopics() async {
    await _prefs?.remove(_sharedTopicsKey);
  }

  Future<void> saveSharedEntries(
      Map<String, List<TimelineEntry>> entriesByTopic) async {
    await _saveEntries(_sharedEntriesKey, entriesByTopic);
  }

  Map<String, List<TimelineEntry>> readSharedEntries() {
    return _readEntries(_sharedEntriesKey);
  }

  Future<void> clearSharedEntries() async {
    await _prefs?.remove(_sharedEntriesKey);
  }

  Future<void> saveFavoriteTimelineNodes(
    List<FavoriteTimelineNode> nodes,
  ) async {
    final payload = nodes.map((node) => node.toJson()).toList();
    if (payload.isEmpty) {
      await _prefs?.remove(_favoriteTimelineNodesKey);
      return;
    }
    await _prefs?.setString(_favoriteTimelineNodesKey, jsonEncode(payload));
  }

  List<FavoriteTimelineNode> readFavoriteTimelineNodes() {
    final raw = _prefs?.getString(_favoriteTimelineNodesKey);
    if (raw == null || raw.isEmpty) {
      return const <FavoriteTimelineNode>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) =>
            FavoriteTimelineNode.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveTopics(String key, List<Topic> topics) async {
    final payload = topics.map((topic) => topic.toJson()).toList();
    if (payload.isEmpty) {
      await _prefs?.remove(key);
      return;
    }
    await _prefs?.setString(key, jsonEncode(payload));
  }

  List<Topic> _readTopics(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) {
      return const <Topic>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Topic.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveEntries(
    String key,
    Map<String, List<TimelineEntry>> entriesByTopic,
  ) async {
    final payload = entriesByTopic.map(
      (topicId, entries) => MapEntry(
        topicId,
        entries.map((entry) => entry.toJson()).toList(),
      ),
    );
    if (payload.isEmpty) {
      await _prefs?.remove(key);
      return;
    }
    await _prefs?.setString(key, jsonEncode(payload));
  }

  Map<String, List<TimelineEntry>> _readEntries(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) {
      return const <String, List<TimelineEntry>>{};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (topicId, value) => MapEntry(
        topicId,
        (value as List<dynamic>)
            .map((item) => TimelineEntry.fromJson(item as Map<String, dynamic>))
            .toList(),
      ),
    );
  }
}
