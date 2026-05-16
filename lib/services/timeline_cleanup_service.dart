import '../models/timeline_models.dart';
import 'app_local_storage.dart';

class TimelineCleanupService {
  const TimelineCleanupService();

  static const Duration retainedCacheDuration = Duration(days: 7);

  Future<void> retainCacheForLoggedOutUser(
    AppLocalStorage localStorage, {
    required String userId,
    String? primaryPhone,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    await localStorage.clearSession();
    await localStorage.saveRetainedCachePolicy(
      userId: userId,
      primaryPhone: primaryPhone,
      expiresAt: currentTime.add(retainedCacheDuration),
    );
  }

  Future<bool> prepareCacheForLogin(
    AppLocalStorage localStorage, {
    required String userId,
    DateTime? now,
  }) async {
    final policy = localStorage.readRetainedCachePolicy();
    if (policy == null) {
      return false;
    }

    final currentTime = now ?? DateTime.now();
    final canReuse = policy.userId == userId && !policy.expiresAt.isBefore(currentTime);

    if (!canReuse) {
      await clearTimelineCache(localStorage);
    }

    await localStorage.clearRetainedCachePolicy();
    return canReuse;
  }

  Future<void> clearTimelineCache(AppLocalStorage localStorage) async {
    await localStorage.clearFollowedTopicSnapshot();
    await localStorage.clearTrackedTopicIds();
    await localStorage.clearPinnedTopicIds();
    await localStorage.clearHistoryTopicIds();
    await localStorage.clearSelectedTopicId();
    await localStorage.saveCustomTopics(const <Topic>[]);
    await localStorage.saveCustomEntries(const <String, List<TimelineEntry>>{});
    await localStorage.clearSharedTopics();
    await localStorage.clearSharedEntries();
  }
}
