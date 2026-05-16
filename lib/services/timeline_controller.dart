import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import '../dto/favorite_timeline_bucket_dto.dart';
import '../dto/followed_topic_dto.dart';
import '../dto/push_device_dto.dart';
import '../dto/topic_timeline_dto.dart';
import '../mappers/followed_topic_mapper.dart';
import '../mappers/recommendation_mapper.dart';
import '../mappers/share_mapper.dart';
import '../mappers/topic_timeline_mapper.dart';
import '../models/auth_models.dart';
import '../models/timeline_creation_models.dart';
import '../models/timeline_models.dart';
import 'app_local_storage.dart';
import 'mock_timeline_repository.dart';
import 'phone_auth_service.dart';
import 'push_device_service.dart';
import 'remote/favorite_timeline_bucket_remote_service.dart';
import 'remote/followed_topic_remote_service.dart';
import 'remote/profile_remote_service.dart';
import 'remote/push_device_remote_service.dart';
import 'remote/recommendation_remote_service.dart';
import 'remote/share_remote_service.dart';
import 'remote/topic_remote_service.dart';
import 'shared_topic_flow_service.dart';
import 'topic_share_service.dart';
import 'timeline_bucketing_service.dart';
import 'timeline_bootstrap_service.dart';
import 'timeline_cleanup_service.dart';
import 'timeline_creation_service.dart';
import 'topic_catalog_service.dart';

enum RecommendationMode {
  personalized,
  hot,
  explore,
  history,
}

enum RecentUpdateReminderMode {
  off,
  majorOnly,
  all,
}

class _DeferredTimelineCreationRequest {
  const _DeferredTimelineCreationRequest({
    required this.request,
  });

  final TopicCreateRequestDto request;
}

class TimelineController extends ChangeNotifier {
  static const int guestFollowLimit = 5;

  TimelineController({
    required TimelineRepository repository,
    required PhoneAuthService authService,
    required AppLocalStorage localStorage,
    required TimelineCreationService creationService,
    PushDeviceService? pushDeviceService,
    PushDeviceRemoteService? pushDeviceRemoteService,
    FollowedTopicRemoteService? followedTopicRemoteService,
    FavoriteTimelineBucketRemoteService? favoriteTimelineBucketRemoteService,
    ProfileRemoteService? profileRemoteService,
    FollowedTopicMapper? followedTopicMapper,
    TopicRemoteService? topicRemoteService,
    TopicTimelineMapper? topicTimelineMapper,
    RecommendationRemoteService? recommendationRemoteService,
    RecommendationMapper? recommendationMapper,
    ShareRemoteService? shareRemoteService,
    ShareMapper? shareMapper,
    TimelineBucketingService? bucketingService,
    TopicCatalogService? topicCatalogService,
    TimelineBootstrapService? bootstrapService,
    TimelineCleanupService? cleanupService,
    SharedTopicFlowService? sharedTopicFlowService,
    TopicShareService? shareService,
    bool preferServerRuntimeTopics = false,
  })  : _repository = repository,
        _authService = authService,
        _localStorage = localStorage,
        _creationService = creationService,
        _pushDeviceService = pushDeviceService ??
            LocalPushDeviceService(localStorage: localStorage),
        _pushDeviceRemoteService =
            pushDeviceRemoteService ?? MockPushDeviceRemoteService(),
        _followedTopicRemoteService = followedTopicRemoteService ??
            MockFollowedTopicRemoteService(repository: repository),
        _favoriteTimelineBucketRemoteService =
            favoriteTimelineBucketRemoteService ??
                MockFavoriteTimelineBucketRemoteService(),
        _profileRemoteService =
            profileRemoteService ?? MockProfileRemoteService(),
        _followedTopicMapper =
            followedTopicMapper ?? const FollowedTopicMapper(),
        _topicRemoteService = topicRemoteService ??
            MockTopicRemoteService(repository: repository),
        _topicTimelineMapper =
            topicTimelineMapper ?? const TopicTimelineMapper(),
        _recommendationRemoteService = recommendationRemoteService ??
            MockRecommendationRemoteService(repository: repository),
        _recommendationMapper =
            recommendationMapper ?? const RecommendationMapper(),
        _shareRemoteService = shareRemoteService ??
            MockShareRemoteService(repository: repository),
        _shareMapper = shareMapper ?? const ShareMapper(),
        _bucketingService =
            bucketingService ?? const TimelineBucketingService(),
        _topicCatalogService =
            topicCatalogService ?? const TopicCatalogService(),
        _bootstrapService =
            bootstrapService ?? const TimelineBootstrapService(),
        _cleanupService = cleanupService ?? const TimelineCleanupService(),
        _sharedTopicFlowService =
            sharedTopicFlowService ?? const SharedTopicFlowService(),
        _shareService = shareService ?? TopicShareService(),
        _preferServerRuntimeTopics = preferServerRuntimeTopics;

  final TimelineRepository _repository;
  final PhoneAuthService _authService;
  final AppLocalStorage _localStorage;
  final TimelineCreationService _creationService;
  final PushDeviceService _pushDeviceService;
  final PushDeviceRemoteService _pushDeviceRemoteService;
  final FollowedTopicRemoteService _followedTopicRemoteService;
  final FavoriteTimelineBucketRemoteService
      _favoriteTimelineBucketRemoteService;
  final ProfileRemoteService _profileRemoteService;
  final FollowedTopicMapper _followedTopicMapper;
  final TopicRemoteService _topicRemoteService;
  final TopicTimelineMapper _topicTimelineMapper;
  final RecommendationRemoteService _recommendationRemoteService;
  final RecommendationMapper _recommendationMapper;
  final ShareRemoteService _shareRemoteService;
  final ShareMapper _shareMapper;
  final TimelineBucketingService _bucketingService;
  final TopicCatalogService _topicCatalogService;
  final TimelineBootstrapService _bootstrapService;
  final TimelineCleanupService _cleanupService;
  final SharedTopicFlowService _sharedTopicFlowService;
  final TopicShareService _shareService;
  final bool _preferServerRuntimeTopics;
  final List<Topic> _trackedTopics = <Topic>[];
  final List<Topic> _recommendedTopics = <Topic>[];
  final List<Topic> _customTopics = <Topic>[];
  final List<Topic> _sharedTopics = <Topic>[];
  final List<Topic> _guestTrackedTopics = <Topic>[];
  final List<Topic> _ownedTopics = <Topic>[];
  final List<Topic> _personalizedRecommendationTopics = <Topic>[];
  final List<Topic> _hotRecommendationTopics = <Topic>[];
  final List<Topic> _exploreRecommendationTopics = <Topic>[];
  final List<Topic> _remoteHistoryTopics = <Topic>[];
  final List<FavoriteTimelineNode> _favoriteTimelineNodes =
      <FavoriteTimelineNode>[];
  final List<String> _userInterestCategoryIds = <String>[];
  final List<FollowedTopicItemDto> _followedTopicItems =
      <FollowedTopicItemDto>[];
  final List<MyTopicItemDto> _ownedTopicItems = <MyTopicItemDto>[];
  final Map<String, List<TimelineEntry>> _entriesByTopic =
      <String, List<TimelineEntry>>{};
  final Map<String, List<TimelineBucket>> _timelineBucketsByTopic =
      <String, List<TimelineBucket>>{};
  final Map<String, TopicTimelineStatsDto> _timelineStatsByTopic =
      <String, TopicTimelineStatsDto>{};
  final Map<String, List<TimelineEntry>> _timelineSearchEntriesByTopic =
      <String, List<TimelineEntry>>{};
  final Map<String, String> _topicStatusById = <String, String>{};
  final Map<String, String> _topicInitializationStateById = <String, String>{};
  final Map<String, TimelineEntry> _trackedTopicLatestEntriesById =
      <String, TimelineEntry>{};
  final Set<String> _followMutationTopicIds = <String>{};
  final Set<String> _topicInitializationRetryIds = <String>{};

  Timer? _resendTimer;
  bool _hasStoredTrackedTopicIds = false;
  List<String> _restoredTrackedTopicIds = const <String>[];
  bool _hasStoredGuestTrackedTopicIds = false;
  List<String> _restoredGuestTrackedTopicIds = const <String>[];
  List<String> _restoredPinnedTopicIds = const <String>[];
  List<String> _restoredHistoryTopicIds = const <String>[];
  String? _restoredSelectedTopicId;
  String? _deferredSharedRoute;
  int _timelineSearchRequestToken = 0;
  bool _hasRemoteRecommendations = false;
  int _loginPromptToken = 0;
  String? _loginPromptReason;
  int _openTopicRequestToken = 0;
  String? _guestKey;
  Topic? _deferredFollowTopic;
  _DeferredTimelineCreationRequest? _deferredTimelineCreationRequest;
  int _deferredTimelineCreationResultToken = 0;
  Topic? _deferredTimelineCreationResultTopic;
  String? _deferredTimelineCreationErrorMessage;
  final Map<String, Timer> _initializationPollTimers = <String, Timer>{};

  bool isBootstrapping = true;
  bool isLoading = false;
  bool isRefreshing = false;
  bool isSendingCode = false;
  bool isVerifyingCode = false;
  bool isGeneratingTimelineDraft = false;
  bool isSavingUserInterests = false;
  bool isSubmittingProfileFeedback = false;
  bool isLoadingMyTopics = false;
  bool _isDisposed = false;

  String? errorMessage;
  String? selectedTopicId;
  String? pendingPhoneNumber;
  String? debugVerificationCode;
  String trackedTopicSearchQuery = '';
  String timelineSearchQuery = '';
  String recommendationSearchQuery = '';
  bool showOnlyMajorNodes = false;
  bool showOnlyFavoriteNodes = false;
  RecentUpdateReminderMode _recentUpdateReminderMode =
      RecentUpdateReminderMode.majorOnly;
  final Map<String, DateTime?> _recentUpdateReminderBaselineByTopicId =
      <String, DateTime?>{};
  bool _hasCapturedRecentUpdateReminderBaseline = false;
  List<String> pinnedTopicIds = <String>[];
  List<String> historyTopicIds = <String>[];
  int resendCountdown = 0;
  int _draftVariation = 0;
  int _pendingSharedTopicToken = 0;

  TimelineSortOrder sortOrder = TimelineSortOrder.chronological;
  RecommendationMode recommendationMode = RecommendationMode.hot;
  AuthSession? session;
  SharedTopicPreview? _pendingSharedTopic;
  UserCapabilitiesDto? _capabilities;
  DateTime? _recommendationsGeneratedAt;
  String? _recommendationRefreshNotice;
  bool _recommendationRefreshNoticeIsError = false;
  String? _trackedTopicsRefreshNotice;
  bool _trackedTopicsRefreshNoticeIsError = false;
  DateTime? _myTopicsGeneratedAt;
  String? _myTopicsRefreshNotice;
  bool _myTopicsRefreshNoticeIsError = false;

  bool get isRegistered => session != null;
  bool get isGuest => !isRegistered;
  String? get guestKey => _guestKey;
  int get preferredHomeShellIndex => 0;
  int get pendingLoginPromptToken => _loginPromptToken;
  String? get pendingLoginPromptReason => _loginPromptReason;
  int get openTopicRequestToken => _openTopicRequestToken;
  int get deferredTimelineCreationResultToken =>
      _deferredTimelineCreationResultToken;
  Topic? get deferredTimelineCreationResultTopic =>
      _deferredTimelineCreationResultTopic;
  String? get deferredTimelineCreationErrorMessage =>
      _deferredTimelineCreationErrorMessage;

  String? get maskedPhoneNumber => session?.maskedPhoneNumber;
  int get guestFollowCount => _trackedTopics.length;
  int get remainingGuestFollowQuota =>
      (guestFollowLimit - guestFollowCount).clamp(0, guestFollowLimit);
  UserCapabilitiesDto? get capabilities => _capabilities;
  int get effectiveFollowLimit =>
      _capabilities?.followLimit ?? (session == null ? guestFollowLimit : 10);
  int? get remainingFollowQuota => _capabilities?.remainingFollowQuota;
  DateTime? get recommendationsGeneratedAt => _recommendationsGeneratedAt;
  String? get recommendationRefreshNotice => _recommendationRefreshNotice;
  bool get recommendationRefreshNoticeIsError =>
      _recommendationRefreshNoticeIsError;
  String? get trackedTopicsRefreshNotice => _trackedTopicsRefreshNotice;
  bool get trackedTopicsRefreshNoticeIsError =>
      _trackedTopicsRefreshNoticeIsError;
  DateTime? get myTopicsGeneratedAt => _myTopicsGeneratedAt;
  String? get myTopicsRefreshNotice => _myTopicsRefreshNotice;
  bool get myTopicsRefreshNoticeIsError => _myTopicsRefreshNoticeIsError;
  bool get hasTrackedTopicsRecentUpdate =>
      _followedTopicItems.any((item) => item.hasRecentUpdate);
  RecentUpdateReminderMode get recentUpdateReminderMode =>
      _recentUpdateReminderMode;
  bool get shouldShowTrackedTopicsRecentUpdateDot =>
      session != null &&
      _followedTopicItems.any(_shouldShowRecentUpdateReminderDot);
  UnmodifiableListView<MyTopicItemDto> get ownedTopicItems =>
      UnmodifiableListView<MyTopicItemDto>(_ownedTopicItems);
  UnmodifiableListView<FavoriteTimelineNode> get favoriteTimelineNodes =>
      UnmodifiableListView<FavoriteTimelineNode>(_favoriteTimelineNodes);
  UnmodifiableListView<String> get userInterestCategoryIds =>
      UnmodifiableListView<String>(_userInterestCategoryIds);

  UnmodifiableListView<Topic> get trackedTopics => UnmodifiableListView(
        _topicCatalogService.orderedTrackedTopics(
          trackedTopics: _trackedTopics,
          pinnedTopicIds: pinnedTopicIds,
          entriesByTopic: _entriesByTopic,
          latestEntriesByTopicId: _trackedTopicLatestEntriesById,
          latestActivityAtByTopicId: _followedTopicLatestNodeTimesById,
        ),
      );

  UnmodifiableListView<Topic> get recommendedTopics =>
      UnmodifiableListView(_recommendedTopics);

  UnmodifiableListView<Topic> get hotRecommendationTopics =>
      UnmodifiableListView(_hotRecommendationTopics);

  Topic? get leadingHotRecommendationTopic {
    if (_hotRecommendationTopics.isNotEmpty) {
      return _hotRecommendationTopics.first;
    }
    for (final topic in _recommendedTopics) {
      if (topic.isHot) {
        return topic;
      }
    }
    for (final topic in allTopics) {
      if (topic.isHot) {
        return topic;
      }
    }
    return null;
  }

  String get createTimelineKeywordHint {
    final topic = leadingHotRecommendationTopic;
    if (topic == null) {
      return '例如：哪吒汽车 资金重组 海外工厂';
    }
    return '例如：${_formatTopicNameAsKeywordHint(topic)}';
  }

  UnmodifiableListView<Topic> get customTopics =>
      UnmodifiableListView(_customTopics);

  UnmodifiableListView<Topic> get sharedTopics =>
      UnmodifiableListView(_sharedTopics);

  SharedTopicPreview? get pendingSharedTopic => _pendingSharedTopic;

  int get pendingSharedTopicToken => _pendingSharedTopicToken;

  List<Topic> get allTopics => _topicCatalogService.allTopics(
        trackedTopics: _trackedTopics,
        recommendedTopics: _recommendedTopics,
        customTopics: _customTopics,
        sharedTopics: _sharedTopics,
        guestTrackedTopics: _guestTrackedTopics,
        ownedTopics: _ownedTopics,
      );

  List<Topic> get timelineSelectionTopics =>
      _topicCatalogService.timelineSelectionTopics(
        trackedTopics: trackedTopics,
        activeTopic: selectedTopic,
      );

  Topic? get selectedTopic => _topicCatalogService.selectedTopic(
        allTopics: allTopics,
        selectedTopicId: selectedTopicId,
      );

  String? get selectedTopicStatus =>
      selectedTopicId == null ? null : _topicStatusById[selectedTopicId!];

  String? get selectedTopicInitializationState => selectedTopicId == null
      ? null
      : _topicInitializationStateById[selectedTopicId!];

  String? topicStatusFor(String topicId) => _topicStatusById[topicId];

  String? topicInitializationStateFor(String topicId) =>
      _topicInitializationStateById[topicId];

  FollowedTopicItemDto? followedTopicItemFor(String topicId) =>
      _followedTopicItemFor(topicId);

  bool topicHasRecentUpdate(String topicId) =>
      _followedTopicItemFor(topicId)?.hasRecentUpdate ?? false;

  bool shouldShowTopicRecentUpdateDot(String topicId) {
    if (session == null) {
      return false;
    }
    final item = _followedTopicItemFor(topicId);
    return item != null && _shouldShowRecentUpdateReminderDot(item);
  }

  void setRecentUpdateReminderMode(RecentUpdateReminderMode mode) {
    if (_recentUpdateReminderMode == mode) {
      return;
    }
    _recentUpdateReminderMode = mode;
    notifyListeners();
  }

  @visibleForTesting
  void markRecentUpdateReminderBaselineForTest(
    String topicId,
    DateTime? latestAt,
  ) {
    _recentUpdateReminderBaselineByTopicId[topicId] = latestAt;
    _hasCapturedRecentUpdateReminderBaseline = true;
  }

  bool _shouldShowRecentUpdateReminderDot(FollowedTopicItemDto item) {
    if (!item.hasRecentUpdate || !_isPastRecentUpdateReminderBaseline(item)) {
      return false;
    }
    return switch (_recentUpdateReminderMode) {
      RecentUpdateReminderMode.off => false,
      RecentUpdateReminderMode.majorOnly => item.latestNode?.isMajor ?? false,
      RecentUpdateReminderMode.all => true,
    };
  }

  bool _isPastRecentUpdateReminderBaseline(FollowedTopicItemDto item) {
    if (!_recentUpdateReminderBaselineByTopicId.containsKey(item.topicId)) {
      return true;
    }
    final baseline = _recentUpdateReminderBaselineByTopicId[item.topicId];
    final latestAt = item.effectiveLatestEventAt;
    if (baseline == null || latestAt == null) {
      return false;
    }
    return latestAt.isAfter(baseline);
  }

  void _captureInitialRecentUpdateReminderBaselineIfNeeded() {
    if (_hasCapturedRecentUpdateReminderBaseline) {
      return;
    }
    _recentUpdateReminderBaselineByTopicId.clear();
    for (final item in _followedTopicItems) {
      if (item.hasRecentUpdate) {
        _recentUpdateReminderBaselineByTopicId[item.topicId] =
            item.effectiveLatestEventAt;
      }
    }
    _hasCapturedRecentUpdateReminderBaseline = true;
  }

  void _resetRecentUpdateReminderBaseline() {
    _recentUpdateReminderBaselineByTopicId.clear();
    _hasCapturedRecentUpdateReminderBaseline = false;
  }

  String? topicLatestRelevantEventSummary(String topicId) =>
      _followedTopicItemFor(topicId)?.effectiveLatestEventSummary;

  DateTime? topicLatestRelevantEventAt(String topicId) =>
      _followedTopicItemFor(topicId)?.effectiveLatestEventAt;

  TopicTimelineStatsDto? get selectedTimelineStats =>
      selectedTopicId == null ? null : _timelineStatsByTopic[selectedTopicId!];

  Map<String, DateTime?> get _followedTopicLatestNodeTimesById {
    return <String, DateTime?>{
      for (final item in _followedTopicItems)
        item.topicId: item.effectiveLatestEventAt,
    };
  }

  List<Topic> get historyTopics {
    final localHistory = _topicCatalogService.historyTopics(
      historyTopicIds: historyTopicIds,
      allTopics: allTopics,
    );
    if (!_hasRemoteRecommendations) {
      return localHistory;
    }

    final seen = <String>{};
    return <Topic>[
      ..._remoteHistoryTopics.where((topic) => seen.add(topic.id)),
      ...localHistory.where((topic) => seen.add(topic.id)),
    ];
  }

  List<Topic> get visibleTrackedTopics =>
      _topicCatalogService.visibleTrackedTopics(
        query: trackedTopicSearchQuery,
        trackedTopics: trackedTopics,
        entriesByTopic: _entriesByTopic,
        latestEntriesByTopicId: _trackedTopicLatestEntriesById,
      );

  bool get isHistoryRecommendationMode =>
      recommendationMode == RecommendationMode.history;
  bool get isPersonalizedRecommendationMode =>
      recommendationMode == RecommendationMode.personalized;
  bool get isExploreRecommendationMode =>
      recommendationMode == RecommendationMode.explore;

  List<Topic> get searchableRecommendationTopics =>
      _topicCatalogService.searchableRecommendationTopics(
        recommendedTopics: _recommendedTopics,
        trackedTopics: _trackedTopics,
        customTopics: _customTopics,
        sharedTopics: _sharedTopics,
      );

  List<Topic> get recommendationTopics {
    final normalizedQuery = recommendationSearchQuery.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      return searchableRecommendationTopics
          .where((topic) =>
              _topicCatalogService.matchesTopicQuery(topic, normalizedQuery))
          .toList();
    }

    if (recommendationMode == RecommendationMode.history) {
      return historyTopics;
    }

    if (_hasRemoteRecommendations) {
      switch (recommendationMode) {
        case RecommendationMode.personalized:
          return List<Topic>.unmodifiable(_personalizedRecommendationTopics);
        case RecommendationMode.hot:
          return List<Topic>.unmodifiable(_hotRecommendationTopics);
        case RecommendationMode.explore:
          return List<Topic>.unmodifiable(_exploreRecommendationTopics);
        case RecommendationMode.history:
          return historyTopics;
      }
    }

    return const <Topic>[];
  }

  bool isFollowMutationInFlight(Topic topic) =>
      _followMutationTopicIds.contains(topic.id);

  List<TimelineBucket> get visibleTimelineBuckets {
    final topicId = selectedTopicId;
    final searching = timelineSearchQuery.trim().isNotEmpty;
    var buckets = searching && topicId != null
        ? _buildTimelineBuckets(
            _timelineSearchEntriesByTopic[topicId] ?? const <TimelineEntry>[])
        : timelineBuckets;
    if (showOnlyFavoriteNodes && topicId != null) {
      buckets = buckets
          .where((bucket) => _favoriteTimelineNodes.any(
                (node) =>
                    node.topicId == topicId && node.overlapsBucket(bucket),
              ))
          .toList();
    }
    if (!showOnlyMajorNodes) {
      return buckets;
    }

    return buckets
        .map((bucket) {
          final entries =
              bucket.entries.where((entry) => entry.isMajor).toList();
          if (entries.isEmpty) {
            return null;
          }

          final headlineEntry = entries.firstWhere(
            (entry) => entry.isMajor,
            orElse: () => entries.first,
          );

          return TimelineBucket(
            id: bucket.id,
            periodStart: bucket.periodStart,
            granularity: bucket.granularity,
            entries: entries,
            label: bucket.label,
            headline: headlineEntry.summary,
          );
        })
        .whereType<TimelineBucket>()
        .toList();
  }

  TimelineEntry? latestEntryForTopic(String topicId) {
    final entries = _entriesByTopic[topicId];
    if (entries != null && entries.isNotEmpty) {
      return _bucketingService.latestEntry(entries);
    }
    return _trackedTopicLatestEntriesById[topicId];
  }

  String favoriteTimelineNodeId({
    required Topic topic,
    required TimelineBucket bucket,
  }) {
    return '${topic.id}:${bucket.id}';
  }

  bool isFavoriteTimelineNode({
    required Topic topic,
    required TimelineBucket bucket,
  }) {
    return _favoriteTimelineNodes.any(
      (node) => node.topicId == topic.id && node.overlapsBucket(bucket),
    );
  }

  Future<void> saveUserInterestCategoryIds(List<String> categoryIds) async {
    final normalized = _normalizeInterestCategoryIds(categoryIds);
    isSavingUserInterests = true;
    notifyListeners();

    try {
      final savedIds = session == null
          ? normalized
          : await _profileRemoteService.saveInterestCategoryIds(normalized);
      _userInterestCategoryIds
        ..clear()
        ..addAll(_normalizeInterestCategoryIds(savedIds));
      await _localStorage.saveInterestCategoryIds(_userInterestCategoryIds);
    } finally {
      isSavingUserInterests = false;
      notifyListeners();
    }
  }

  Future<void> submitProfileFeedback({
    required String message,
    String category = 'suggestion',
  }) async {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      throw Exception('请先填写反馈内容。');
    }

    isSubmittingProfileFeedback = true;
    notifyListeners();
    try {
      await _profileRemoteService.submitFeedback(
        message: normalized,
        category: category,
      );
    } finally {
      isSubmittingProfileFeedback = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavoriteTimelineNode({
    required Topic topic,
    required TimelineBucket bucket,
  }) async {
    final existingNodes = _favoriteTimelineNodes
        .where(
          (node) => node.topicId == topic.id && node.overlapsBucket(bucket),
        )
        .toList();
    final favorited = existingNodes.isEmpty;
    if (session != null) {
      if (favorited) {
        final response = await _favoriteTimelineBucketRemoteService
            .favoriteBucket(_favoriteRequestFor(topic: topic, bucket: bucket));
        _upsertFavoriteTimelineNode(
          _favoriteNodeFromDto(
            response,
            fallbackTopic: topic,
            fallbackBucket: bucket,
          ),
        );
      } else {
        await _favoriteTimelineBucketRemoteService.deleteBucket(
          _favoriteDeleteRequestFor(topic: topic, bucket: bucket),
        );
        _removeFavoriteNodesForBucket(topic: topic, bucket: bucket);
      }
      notifyListeners();
      return favorited;
    }

    final nodeId = favoriteTimelineNodeId(topic: topic, bucket: bucket);
    if (favorited) {
      _favoriteTimelineNodes.insert(
        0,
        _favoriteSnapshotFor(
          nodeId: nodeId,
          topic: topic,
          bucket: bucket,
        ),
      );
    } else {
      final idsToRemove = existingNodes.map((node) => node.id).toSet();
      _favoriteTimelineNodes
          .removeWhere((node) => idsToRemove.contains(node.id));
    }
    await _persistFavoriteTimelineNodes();
    notifyListeners();
    return favorited;
  }

  Future<void> removeFavoriteTimelineNode(String nodeId) async {
    final existingIndex =
        _favoriteTimelineNodes.indexWhere((node) => node.id == nodeId);
    if (existingIndex < 0) {
      return;
    }
    final node = _favoriteTimelineNodes[existingIndex];
    if (session != null) {
      await _favoriteTimelineBucketRemoteService.deleteBucket(
        FavoriteTimelineBucketDeleteRequestDto(
          topicId: node.topicId,
          bucketGranularity: node.bucketGranularity,
          bucketStart: node.bucketStart,
          bucketEnd: node.bucketEnd,
        ),
      );
    }
    _favoriteTimelineNodes.removeAt(existingIndex);
    await _persistFavoriteTimelineNodes();
    notifyListeners();
  }

  void toggleFavoriteNodesOnly() {
    final nextValue = !showOnlyFavoriteNodes;
    showOnlyFavoriteNodes = nextValue;
    if (nextValue) {
      showOnlyMajorNodes = false;
    }
    notifyListeners();
  }

  FavoriteTimelineNode _favoriteSnapshotFor({
    required String nodeId,
    required Topic topic,
    required TimelineBucket bucket,
  }) {
    final primaryEntry = bucket.entries.isEmpty ? null : bucket.entries.first;
    return FavoriteTimelineNode(
      id: nodeId,
      topicId: topic.id,
      topicName: topic.name,
      label: bucket.label,
      headline: bucket.headline,
      summary: primaryEntry?.summary ?? bucket.headline,
      timestamp: primaryEntry?.timestamp ?? bucket.periodStart,
      isMajor: bucket.containsMajorEvent,
      primarySignal: primaryEntry?.primarySignal,
      bucketKey: bucket.id,
      bucketGranularity: bucket.granularity,
      bucketStart: bucket.rangeStart,
      bucketEnd: bucket.rangeEnd,
      savedAt: DateTime.now(),
    );
  }

  FavoriteTimelineBucketRequestDto _favoriteRequestFor({
    required Topic topic,
    required TimelineBucket bucket,
    DateTime? savedAt,
  }) {
    final primaryEntry = bucket.entries.isEmpty ? null : bucket.entries.first;
    return FavoriteTimelineBucketRequestDto(
      topicId: topic.id,
      topicTitle: topic.name,
      topicSummary: topic.tagline,
      bucketKey: bucket.id,
      bucketGranularity: bucket.granularity,
      bucketLabel: bucket.label,
      bucketStart: bucket.rangeStart,
      bucketEnd: bucket.rangeEnd,
      headline: bucket.headline,
      summary: primaryEntry?.summary ?? bucket.headline,
      primarySignal: primaryEntry?.primarySignal,
      containsMajorEvent: bucket.containsMajorEvent,
      savedAt: savedAt,
    );
  }

  FavoriteTimelineBucketDeleteRequestDto _favoriteDeleteRequestFor({
    required Topic topic,
    required TimelineBucket bucket,
  }) {
    return FavoriteTimelineBucketDeleteRequestDto(
      topicId: topic.id,
      bucketGranularity: bucket.granularity,
      bucketStart: bucket.rangeStart,
      bucketEnd: bucket.rangeEnd,
    );
  }

  FavoriteTimelineBucketRequestDto _favoriteRequestFromNode(
    FavoriteTimelineNode node,
  ) {
    return FavoriteTimelineBucketRequestDto(
      topicId: node.topicId,
      topicTitle: node.topicName,
      bucketKey: node.bucketKey,
      bucketGranularity: node.bucketGranularity,
      bucketLabel: node.label,
      bucketStart: node.bucketStart,
      bucketEnd: node.bucketEnd,
      headline: node.headline,
      summary: node.summary,
      primarySignal: node.primarySignal,
      containsMajorEvent: node.isMajor,
      savedAt: node.savedAt,
    );
  }

  FavoriteTimelineNode _favoriteNodeFromDto(
    FavoriteTimelineBucketDto dto, {
    Topic? fallbackTopic,
    TimelineBucket? fallbackBucket,
  }) {
    final topicId = dto.topicId.isEmpty ? fallbackTopic?.id ?? '' : dto.topicId;
    final topicName = dto.topicTitle ??
        fallbackTopic?.name ??
        fallbackBucket?.headline ??
        '收藏专题';
    final fallbackEntry =
        fallbackBucket == null || fallbackBucket.entries.isEmpty
            ? null
            : fallbackBucket.entries.first;
    return FavoriteTimelineNode(
      id: dto.favoriteId.isEmpty ? '$topicId:${dto.bucketKey}' : dto.favoriteId,
      topicId: topicId,
      topicName: topicName,
      label: dto.bucketLabel,
      headline: dto.headline,
      summary: dto.summary.isEmpty
          ? fallbackEntry?.summary ?? dto.headline
          : dto.summary,
      timestamp: fallbackEntry?.timestamp ?? dto.bucketStart,
      isMajor: dto.containsMajorEvent ||
          (fallbackBucket?.containsMajorEvent ?? false),
      primarySignal: dto.primarySignal ?? fallbackEntry?.primarySignal,
      bucketKey: dto.bucketKey,
      bucketGranularity: dto.bucketGranularity,
      bucketStart: dto.bucketStart,
      bucketEnd: dto.bucketEnd,
      savedAt: dto.savedAt,
    );
  }

  void _upsertFavoriteTimelineNode(FavoriteTimelineNode node) {
    final existingIndex = _favoriteTimelineNodes.indexWhere(
      (item) =>
          item.id == node.id ||
          (item.topicId == node.topicId &&
              timelineRangesOverlap(
                item.bucketStart,
                item.bucketEnd,
                node.bucketStart,
                node.bucketEnd,
              )),
    );
    if (existingIndex >= 0) {
      _favoriteTimelineNodes[existingIndex] = node;
      return;
    }
    _favoriteTimelineNodes.insert(0, node);
  }

  void _removeFavoriteNodesForBucket({
    required Topic topic,
    required TimelineBucket bucket,
  }) {
    _favoriteTimelineNodes.removeWhere(
      (node) => node.topicId == topic.id && node.overlapsBucket(bucket),
    );
  }

  void _applyTimelineFavoriteBuckets(
    TopicTimelineResponseDto response,
    List<TimelineBucket> buckets,
  ) {
    if (response.favoriteBuckets.isEmpty) {
      if (session != null) {
        _favoriteTimelineNodes.removeWhere(
          (node) => node.topicId == response.topic.topicId,
        );
      }
      return;
    }

    final incomingNodes = <FavoriteTimelineNode>[];
    for (final favorite in response.favoriteBuckets) {
      final matchingBucket = _matchingFavoriteBucket(favorite, buckets);
      incomingNodes.add(
        _favoriteNodeFromDto(
          favorite,
          fallbackTopic: _topicTimelineMapper.toTopic(response.topic),
          fallbackBucket: matchingBucket,
        ),
      );
    }

    if (session != null) {
      _favoriteTimelineNodes.removeWhere(
        (node) => node.topicId == response.topic.topicId,
      );
    }
    for (final node in incomingNodes) {
      _upsertFavoriteTimelineNode(node);
    }
  }

  TimelineBucket? _matchingFavoriteBucket(
    FavoriteTimelineBucketDto favorite,
    List<TimelineBucket> buckets,
  ) {
    for (final bucket in buckets) {
      if (timelineRangesOverlap(
        favorite.bucketStart,
        favorite.bucketEnd,
        bucket.rangeStart,
        bucket.rangeEnd,
      )) {
        return bucket;
      }
    }
    return null;
  }

  List<TimelineBucket> get timelineBuckets {
    final topic = selectedTopic;
    if (topic == null) {
      return const <TimelineBucket>[];
    }

    final cachedBuckets = _timelineBucketsByTopic[topic.id];
    if (cachedBuckets != null) {
      return _sortBuckets(cachedBuckets);
    }

    final entries = _entriesByTopic[topic.id] ?? const <TimelineEntry>[];
    return _buildTimelineBuckets(entries);
  }

  Future<void> initialize() async {
    isBootstrapping = true;
    notifyListeners();

    final restoredState =
        await _bootstrapService.restoreLocalState(_localStorage);
    _guestKey = await _localStorage.ensureGuestKey();
    _applyRestoredState(restoredState);
    _userInterestCategoryIds
      ..clear()
      ..addAll(_localStorage.readInterestCategoryIds());
    await _invalidateLegacySessionForServerRuntimeIfNeeded();

    if (session != null) {
      await loadInitialData(force: true);
    } else {
      await loadPublicData(force: true);
      await _resolveDeferredSharedRoute();
    }

    isBootstrapping = false;
    notifyListeners();
  }

  bool isValidPhoneNumber(String raw) {
    final normalized = normalizePhoneNumber(raw);
    return RegExp(r'^1\d{10}$').hasMatch(normalized);
  }

  String normalizePhoneNumber(String raw) {
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> sendVerificationCode(String rawPhoneNumber) async {
    final phoneNumber = normalizePhoneNumber(rawPhoneNumber);

    if (!isValidPhoneNumber(phoneNumber)) {
      errorMessage = '请输入正确的 11 位手机号。';
      notifyListeners();
      return;
    }

    if (isSendingCode || resendCountdown > 0) {
      return;
    }

    isSendingCode = true;
    errorMessage = null;
    debugVerificationCode = null;
    pendingPhoneNumber = phoneNumber;
    notifyListeners();

    try {
      final challenge = await _authService.sendVerificationCode(phoneNumber);
      pendingPhoneNumber = challenge.phoneNumber;
      debugVerificationCode = challenge.debugCode;
      _startResendCountdown(challenge.cooldownSeconds);
    } catch (error) {
      errorMessage = '发送短信失败：$error';
    } finally {
      isSendingCode = false;
      notifyListeners();
    }
  }

  Future<void> verifySmsCode({
    required String rawPhoneNumber,
    required String smsCode,
  }) async {
    final phoneNumber = normalizePhoneNumber(rawPhoneNumber);
    final code = smsCode.trim();

    if (!isValidPhoneNumber(phoneNumber)) {
      errorMessage = '请输入正确的 11 位手机号。';
      notifyListeners();
      return;
    }

    if (code.length != 6) {
      errorMessage = '请输入 6 位短信验证码。';
      notifyListeners();
      return;
    }

    isVerifyingCode = true;
    errorMessage = null;
    notifyListeners();

    try {
      final authSession = await _authService.verifyCode(
        phoneNumber: phoneNumber,
        code: code,
      );

      session = authSession;
      await _localStorage.saveSession(authSession);
      final canReuseRetainedCache = await _cleanupService.prepareCacheForLogin(
        _localStorage,
        userId: authSession.userId,
      );
      if (canReuseRetainedCache) {
        final restoredState =
            await _bootstrapService.restoreLocalState(_localStorage);
        _applyRestoredState(restoredState);
      } else {
        _applyLoggedOutState();
        final restoredState =
            await _bootstrapService.restoreLocalState(_localStorage);
        _applyFreshLoginLocalState(
          restoredState,
          authSession: authSession,
        );
      }
      pendingPhoneNumber = null;
      debugVerificationCode = null;
      _stopResendCountdown();
      final activeGuestFollowTopicIds = await _mergeGuestFollowsAfterLogin();
      if (activeGuestFollowTopicIds != null) {
        await _claimGuestTopicsAfterLogin(
          activeGuestFollowTopicIds: activeGuestFollowTopicIds,
        );
      }
      await _mergeGuestFavoriteBucketsAfterLogin();
      await loadInitialData(force: true);
      await _resumeDeferredFollowAfterLogin();
      await _resumeDeferredTimelineCreationAfterLogin();
      _setPendingGuestSyncQuotaMessageIfNeeded();
    } catch (error) {
      errorMessage = '登录失败：$error';
    } finally {
      isVerifyingCode = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final lastSession = session;
    await _disablePushDeviceForCurrentSession();
    discardDeferredFollowTopic();
    discardDeferredTimelineCreation();
    _applyLogoutSessionStatePreservingCurrentContent();
    _stopResendCountdown();
    if (lastSession != null) {
      await _cleanupService.retainCacheForLoggedOutUser(
        _localStorage,
        userId: lastSession.userId,
        primaryPhone: lastSession.primaryPhone,
      );
      await _persistGuestTimelinePreferences();
    } else {
      await _localStorage.clearSession();
    }
    notifyListeners();
  }

  Future<PushTestNotificationResultDto>
      sendTestNotificationForSelectedTopic() async {
    if (session == null) {
      throw StateError('请先登录后再测试推送。');
    }

    final topic = selectedTopic;
    if (topic == null) {
      throw StateError('请先打开一个专题后再测试推送。');
    }

    final summary = topicLatestRelevantEventSummary(topic.id);
    final body = (summary != null && summary.trim().isNotEmpty)
        ? summary.trim()
        : '${topic.name} 出现新的关键节点，可在时间轴里继续查看。';
    _logPushDebug('Sending test notification for topicId=${topic.id}');
    final result = await _pushDeviceRemoteService.sendTestNotification(
      PushTestNotificationRequestDto(
        topicId: topic.id,
        title: '你关注的专题有新动态',
        body: body,
      ),
    );
    _logPushDebug(
      'Test notification response: sentCount=${result.sentCount}, '
      'simulated=${result.simulated}, topicId=${result.topicId}',
    );
    return result;
  }

  Future<void> loadInitialData({bool force = false}) async {
    if (session == null) {
      await loadPublicData(force: force);
      return;
    }

    if (isLoading || (!force && _trackedTopics.isNotEmpty)) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      late final TimelineInitialLoadState initialLoadState;
      try {
        initialLoadState = await _bootstrapService.loadInitialTopicState(
          repository: _repository,
          followedTopicRemoteService: _followedTopicRemoteService,
          followedTopicMapper: _followedTopicMapper,
          localStorage: _localStorage,
          userId: session!.userId,
          customTopics: _customTopics,
          sharedTopics: _sharedTopics,
          entriesByTopic: _entriesByTopic,
          hasStoredTrackedTopicIds: _hasStoredTrackedTopicIds,
          restoredTrackedTopicIds: _restoredTrackedTopicIds,
          restoredPinnedTopicIds: _restoredPinnedTopicIds,
          restoredHistoryTopicIds: _restoredHistoryTopicIds,
          restoredSelectedTopicId: _restoredSelectedTopicId,
          currentSelectedTopicId: selectedTopicId,
          preferServerRuntimeTopics: _preferServerRuntimeTopics,
        );
      } catch (error) {
        _setErrorMessage('加载关注事件列表失败：$error');
        return;
      }

      _trackedTopics
        ..clear()
        ..addAll(initialLoadState.trackedTopics);
      _followedTopicItems
        ..clear()
        ..addAll(initialLoadState.followedTopicItems);
      _captureInitialRecentUpdateReminderBaselineIfNeeded();
      _trackedTopicLatestEntriesById
        ..clear()
        ..addAll(initialLoadState.followedTopicLatestEntriesByTopicId);
      pinnedTopicIds = initialLoadState.pinnedTopicIds;
      historyTopicIds = initialLoadState.historyTopicIds;
      _recommendedTopics
        ..clear()
        ..addAll(initialLoadState.recommendedTopics);
      _hasRemoteRecommendations = false;
      _personalizedRecommendationTopics.clear();
      _hotRecommendationTopics.clear();
      _exploreRecommendationTopics.clear();
      _remoteHistoryTopics.clear();
      selectedTopicId = initialLoadState.selectedTopicId;

      try {
        await _ensureTimelineLoaded(selectedTopicId);
      } catch (error) {
        _setErrorMessage('加载当前时间线失败：$error');
      }
      await _refreshFavoriteTimelineBucketsFromServer();
      await _refreshUserInterestCategoriesFromServer();
      await _loadRecommendations();
      if (recommendationMode != RecommendationMode.history) {
        recommendationMode = _defaultRecommendationModeForCurrentSession();
      }
      await _refreshCapabilities();
      _normalizeSelectedTopicForServerRuntime();
      _warmTrackedTimelines(excludeTopicId: selectedTopicId);
      await _resolveDeferredSharedRoute();
      await _persistTimelinePreferences();
      _restoredTrackedTopicIds = const <String>[];
      _restoredPinnedTopicIds = const <String>[];
      _restoredHistoryTopicIds = const <String>[];
      _restoredSelectedTopicId = null;
    } catch (error) {
      errorMessage = '初始化数据失败：$error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPublicData({bool force = false}) async {
    if (session != null) {
      await loadInitialData(force: force);
      return;
    }

    if (isLoading || (!force && _hasRemoteRecommendations)) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _trackedTopics.clear();
      _followedTopicItems.clear();
      _trackedTopicLatestEntriesById.clear();
      _resetRecentUpdateReminderBaseline();
      pinnedTopicIds = <String>[];
      await _loadRecommendations();
      await _refreshCapabilities();
      _restoreGuestTrackedTopics();
      recommendationMode = _defaultRecommendationModeForCurrentSession();
      _normalizeSelectedTopicForPublicRuntime();
      await _persistLegacyGuestTopicCleanupIfNeeded();
      _warmTrackedTimelines();
      await _resolveDeferredSharedRoute();
    } catch (error) {
      errorMessage = '加载推荐列表失败：$error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _applyRestoredState(TimelineRestoredState restoredState) {
    final restorableGuestTrackedTopicIds = _filterLegacyGuestTopicIds(
      restoredState.restoredGuestTrackedTopicIds,
    );
    final restorableHistoryTopicIds = _filterLegacyGuestTopicIds(
      restoredState.restoredHistoryTopicIds,
    );
    final restorableSelectedTopicId = _filterLegacyGuestTopicId(
      restoredState.restoredSelectedTopicId,
    );
    final restorableGuestTrackedTopics = _filterLegacyGuestTopics(
      restoredState.guestTrackedTopics,
    );
    sortOrder = restoredState.sortOrder;
    session = restoredState.session;
    _hasStoredTrackedTopicIds = restoredState.hasStoredTrackedTopicIds;
    _restoredTrackedTopicIds = restoredState.restoredTrackedTopicIds;
    _hasStoredGuestTrackedTopicIds =
        restoredState.hasStoredGuestTrackedTopicIds;
    _restoredGuestTrackedTopicIds = restorableGuestTrackedTopicIds;
    _restoredPinnedTopicIds = restoredState.restoredPinnedTopicIds;
    _restoredHistoryTopicIds = restorableHistoryTopicIds;
    _restoredSelectedTopicId = restorableSelectedTopicId;
    _customTopics
      ..clear()
      ..addAll(restoredState.customTopics);
    _sharedTopics
      ..clear()
      ..addAll(restoredState.sharedTopics);
    _favoriteTimelineNodes
      ..clear()
      ..addAll(restoredState.favoriteTimelineNodes);
    _guestTrackedTopics
      ..clear()
      ..addAll(restorableGuestTrackedTopics);
    _ownedTopics.clear();
    for (final topic
        in restorableGuestTrackedTopics.where(_isServerManagedTopic)) {
      _cacheTopicRuntimeState(
        topicId: topic.id,
        status: _topicStatusById[topic.id] ?? 'draft',
        initializationState:
            _topicInitializationStateById[topic.id] ?? 'pending',
      );
    }
    _entriesByTopic
      ..clear()
      ..addAll(restoredState.restoredEntriesByTopic);
    _timelineSearchEntriesByTopic.clear();
    _timelineBucketsByTopic.clear();
    _hasRemoteRecommendations = false;
    _personalizedRecommendationTopics.clear();
    _hotRecommendationTopics.clear();
    _exploreRecommendationTopics.clear();
    _remoteHistoryTopics.clear();
    _followedTopicItems.clear();
    _resetRecentUpdateReminderBaseline();
    _ownedTopicItems.clear();
    _trackedTopicLatestEntriesById.clear();
    _topicStatusById.clear();
    _topicInitializationStateById.clear();
    _topicInitializationRetryIds.clear();
    _myTopicsGeneratedAt = null;
    _myTopicsRefreshNotice = null;
    _myTopicsRefreshNoticeIsError = false;
  }

  void _applyLoggedOutState() {
    session = null;
    pendingPhoneNumber = null;
    debugVerificationCode = null;
    errorMessage = null;
    trackedTopicSearchQuery = '';
    timelineSearchQuery = '';
    recommendationSearchQuery = '';
    pinnedTopicIds = <String>[];
    historyTopicIds = <String>[];
    selectedTopicId = null;
    _pendingSharedTopic = null;
    _capabilities = null;
    _trackedTopics.clear();
    _recommendedTopics.clear();
    _customTopics.clear();
    _sharedTopics.clear();
    _guestTrackedTopics.clear();
    _ownedTopics.clear();
    _personalizedRecommendationTopics.clear();
    _hotRecommendationTopics.clear();
    _exploreRecommendationTopics.clear();
    _favoriteTimelineNodes.clear();
    _followedTopicItems.clear();
    _resetRecentUpdateReminderBaseline();
    _ownedTopicItems.clear();
    _entriesByTopic.clear();
    _timelineBucketsByTopic.clear();
    _timelineSearchEntriesByTopic.clear();
    _trackedTopicLatestEntriesById.clear();
    _topicStatusById.clear();
    _topicInitializationStateById.clear();
    _topicInitializationRetryIds.clear();
    isLoadingMyTopics = false;
    _hasStoredTrackedTopicIds = false;
    _restoredTrackedTopicIds = const <String>[];
    _hasStoredGuestTrackedTopicIds = false;
    _restoredGuestTrackedTopicIds = const <String>[];
    _restoredPinnedTopicIds = const <String>[];
    _restoredHistoryTopicIds = const <String>[];
    _restoredSelectedTopicId = null;
    recommendationMode = _defaultRecommendationModeForCurrentSession();
    _hasRemoteRecommendations = false;
    _myTopicsGeneratedAt = null;
    _myTopicsRefreshNotice = null;
    _myTopicsRefreshNoticeIsError = false;
  }

  void _applyLogoutSessionStatePreservingCurrentContent() {
    session = null;
    pendingPhoneNumber = null;
    debugVerificationCode = null;
    errorMessage = null;
    pinnedTopicIds = <String>[];
    _pendingSharedTopic = null;
    _capabilities = null;
    _ownedTopics.clear();
    _ownedTopicItems.clear();
    _favoriteTimelineNodes.clear();
    _resetRecentUpdateReminderBaseline();
    _topicInitializationRetryIds.clear();
    isLoadingMyTopics = false;
    _hasStoredTrackedTopicIds = false;
    _restoredTrackedTopicIds = const <String>[];
    _hasStoredGuestTrackedTopicIds = _trackedTopics.isNotEmpty;
    _restoredGuestTrackedTopicIds =
        _trackedTopics.map((topic) => topic.id).toList(growable: false);
    _restoredPinnedTopicIds = const <String>[];
    _myTopicsGeneratedAt = null;
    _myTopicsRefreshNotice = null;
    _myTopicsRefreshNoticeIsError = false;
    recommendationMode = _defaultRecommendationModeForCurrentSession();
  }

  void _applyFreshLoginLocalState(
    TimelineRestoredState restoredState, {
    required AuthSession authSession,
  }) {
    final restorableGuestTrackedTopicIds = _filterLegacyGuestTopicIds(
      restoredState.restoredGuestTrackedTopicIds,
    );
    final restorableGuestTrackedTopics = _filterLegacyGuestTopics(
      restoredState.guestTrackedTopics,
    );
    sortOrder = restoredState.sortOrder;
    session = authSession;
    _hasStoredTrackedTopicIds = false;
    _restoredTrackedTopicIds = const <String>[];
    _hasStoredGuestTrackedTopicIds =
        restoredState.hasStoredGuestTrackedTopicIds;
    _restoredGuestTrackedTopicIds = restorableGuestTrackedTopicIds;
    _restoredPinnedTopicIds = const <String>[];
    _restoredHistoryTopicIds = const <String>[];
    _restoredSelectedTopicId = null;
    _customTopics
      ..clear()
      ..addAll(restoredState.customTopics);
    _sharedTopics
      ..clear()
      ..addAll(restoredState.sharedTopics);
    _guestTrackedTopics
      ..clear()
      ..addAll(restorableGuestTrackedTopics);
    _ownedTopics.clear();
    _entriesByTopic
      ..clear()
      ..addAll(restoredState.restoredEntriesByTopic);
    _timelineSearchEntriesByTopic.clear();
    _timelineBucketsByTopic.clear();
    _hasRemoteRecommendations = false;
    _personalizedRecommendationTopics.clear();
    _hotRecommendationTopics.clear();
    _exploreRecommendationTopics.clear();
    _remoteHistoryTopics.clear();
    _followedTopicItems.clear();
    _resetRecentUpdateReminderBaseline();
    _ownedTopicItems.clear();
    _trackedTopicLatestEntriesById.clear();
    _topicStatusById.clear();
    _topicInitializationStateById.clear();
    _topicInitializationRetryIds.clear();
    _myTopicsGeneratedAt = null;
    _myTopicsRefreshNotice = null;
    _myTopicsRefreshNoticeIsError = false;
  }

  Future<void> _invalidateLegacySessionForServerRuntimeIfNeeded() async {
    if (!_preferServerRuntimeTopics || session == null) {
      return;
    }
    if (_localStorage.hasPersistedSessionToken()) {
      return;
    }

    final legacySession = session!;
    await _cleanupService.retainCacheForLoggedOutUser(
      _localStorage,
      userId: legacySession.userId,
      primaryPhone: legacySession.primaryPhone,
    );
    _applyLoggedOutState();
  }

  bool _isServerManagedTopic(Topic topic) {
    return _customTopics.every((item) => item.id != topic.id) &&
        _sharedTopics.every((item) => item.id != topic.id) &&
        !topic.id.startsWith('custom-');
  }

  void _applyFollowedTopicMutation(
    FollowMutationResultDto result, {
    Topic? fallbackTopic,
  }) {
    _applyCapabilities(result.capabilities);
    final topicId = result.topicId ?? result.item?.topicId ?? fallbackTopic?.id;
    if (topicId == null) {
      return;
    }

    if (!result.followed) {
      _followedTopicItems.removeWhere((item) => item.topicId == topicId);
      _trackedTopicLatestEntriesById.remove(topicId);
      _recentUpdateReminderBaselineByTopicId.remove(topicId);
      _removeTrackedTopicLocally(fallbackTopic ?? _findTopicById(topicId));
      return;
    }

    final baseItem = result.item ?? _followedTopicItemFor(topicId);
    final item = result.isPinned == null
        ? baseItem
        : baseItem?.copyWith(isPinned: result.isPinned);
    if (item == null) {
      return;
    }

    _upsertFollowedTopicItem(item);
    if (item.hasRecentUpdate &&
        !_recentUpdateReminderBaselineByTopicId.containsKey(topicId)) {
      _recentUpdateReminderBaselineByTopicId[topicId] =
          item.effectiveLatestEventAt;
    }
    final resolvedTopic = _followedTopicMapper.toTopic(
      item,
      fallbackTopic: fallbackTopic ?? _findTopicById(topicId),
    );
    final existingIndex =
        _trackedTopics.indexWhere((trackedTopic) => trackedTopic.id == topicId);
    if (existingIndex >= 0) {
      _trackedTopics[existingIndex] = resolvedTopic;
    } else {
      _trackedTopics.add(resolvedTopic);
    }

    final latestEntry = _followedTopicMapper.toLatestEntry(
      item,
      topic: resolvedTopic,
    );
    if (latestEntry == null) {
      _trackedTopicLatestEntriesById.remove(topicId);
    } else {
      _trackedTopicLatestEntriesById[topicId] = latestEntry;
    }

    if (item.isPinned) {
      pinnedTopicIds = <String>[
        topicId,
        ...pinnedTopicIds.where((pinnedTopicId) => pinnedTopicId != topicId),
      ];
    } else {
      pinnedTopicIds = pinnedTopicIds
          .where((pinnedTopicId) => pinnedTopicId != topicId)
          .toList();
    }
  }

  void _restoreGuestTrackedTopics() {
    final trackedIds = _hasStoredGuestTrackedTopicIds
        ? _filterLegacyGuestTopicIds(_restoredGuestTrackedTopicIds)
        : const <String>[];
    if (trackedIds.isEmpty) {
      return;
    }

    final publicTopics = _topicCatalogService.mergeTopics(
      const <Topic>[],
      _recommendedTopics,
      _customTopics,
      _sharedTopics,
      _guestTrackedTopics,
    );
    final restoredTopics = trackedIds
        .map((topicId) =>
            _topicCatalogService.findTopicById(topicId, publicTopics))
        .whereType<Topic>()
        .toList();

    _trackedTopics
      ..clear()
      ..addAll(restoredTopics);
    for (final topic in restoredTopics.where(_isServerManagedTopic)) {
      _cacheTopicRuntimeState(
        topicId: topic.id,
        status: _topicStatusById[topic.id] ?? 'draft',
        initializationState:
            _topicInitializationStateById[topic.id] ?? 'pending',
      );
    }
  }

  bool _shouldFilterLegacyGuestTopics() =>
      _preferServerRuntimeTopics && session == null;

  bool _isLegacyGuestLocalTopicId(String topicId) =>
      _shouldFilterLegacyGuestTopics() && topicId.startsWith('topic_custom_');

  String? _filterLegacyGuestTopicId(String? topicId) {
    if (topicId == null || topicId.isEmpty) {
      return topicId;
    }
    return _isLegacyGuestLocalTopicId(topicId) ? null : topicId;
  }

  List<String> _filterLegacyGuestTopicIds(Iterable<String> topicIds) {
    if (!_shouldFilterLegacyGuestTopics()) {
      return List<String>.from(topicIds);
    }
    return topicIds
        .where((topicId) => !_isLegacyGuestLocalTopicId(topicId))
        .toList();
  }

  List<Topic> _filterLegacyGuestTopics(Iterable<Topic> topics) {
    if (!_shouldFilterLegacyGuestTopics()) {
      return List<Topic>.from(topics);
    }
    return topics
        .where((topic) => !_isLegacyGuestLocalTopicId(topic.id))
        .toList();
  }

  Future<void> _persistLegacyGuestTopicCleanupIfNeeded() async {
    if (!_shouldFilterLegacyGuestTopics()) {
      return;
    }

    final filteredGuestTrackedTopics =
        _filterLegacyGuestTopics(_guestTrackedTopics);
    final filteredHistoryTopicIds = _filterLegacyGuestTopicIds(historyTopicIds);
    final filteredSelectedTopicId = _filterLegacyGuestTopicId(selectedTopicId);
    final guestTopicsChanged =
        filteredGuestTrackedTopics.length != _guestTrackedTopics.length;
    final historyChanged =
        filteredHistoryTopicIds.length != historyTopicIds.length;
    final selectedChanged = filteredSelectedTopicId != selectedTopicId;

    if (!guestTopicsChanged && !historyChanged && !selectedChanged) {
      return;
    }

    _guestTrackedTopics
      ..clear()
      ..addAll(filteredGuestTrackedTopics);
    _trackedTopics.removeWhere((topic) => _isLegacyGuestLocalTopicId(topic.id));
    historyTopicIds = filteredHistoryTopicIds;
    selectedTopicId = filteredSelectedTopicId;
    await _persistGuestTimelinePreferences();
  }

  void _upsertFollowedTopicItem(FollowedTopicItemDto item) {
    final existingIndex = _followedTopicItems.indexWhere(
      (followedItem) => followedItem.topicId == item.topicId,
    );
    if (existingIndex >= 0) {
      _followedTopicItems[existingIndex] = item;
    } else {
      _followedTopicItems.add(item);
    }
  }

  FollowedTopicItemDto? _followedTopicItemFor(String topicId) {
    for (final item in _followedTopicItems) {
      if (item.topicId == topicId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _markFollowedTopicViewedLocally(String topicId) async {
    final index =
        _followedTopicItems.indexWhere((item) => item.topicId == topicId);
    if (index < 0) {
      return;
    }

    final existing = _followedTopicItems[index];
    if (!existing.hasRecentUpdate && (existing.unreadSignalCount ?? 0) == 0) {
      return;
    }
    _recentUpdateReminderBaselineByTopicId[topicId] =
        existing.effectiveLatestEventAt;

    _followedTopicItems[index] = existing.copyWith(
      hasRecentUpdate: false,
      unreadSignalCount: 0,
      lastViewedAt: DateTime.now(),
    );
    await _persistFollowedTopicCacheMirror();
    notifyListeners();
  }

  Topic? _findTopicById(String topicId) {
    for (final topic in allTopics) {
      if (topic.id == topicId) {
        return topic;
      }
    }
    return null;
  }

  void _removeTrackedTopicLocally(Topic? topic) {
    final targetTopic = topic ??
        (selectedTopicId == null ? null : _findTopicById(selectedTopicId!));
    if (targetTopic == null) {
      return;
    }
    final existingIndex =
        _trackedTopics.indexWhere((item) => item.id == targetTopic.id);
    if (existingIndex < 0) {
      return;
    }

    _trackedTopics.removeAt(existingIndex);
    pinnedTopicIds.removeWhere((topicId) => topicId == targetTopic.id);
    if (selectedTopicId == targetTopic.id) {
      final remainingTopics = _topicCatalogService.allTopics(
        trackedTopics: _trackedTopics,
        recommendedTopics: _recommendedTopics,
        customTopics: _customTopics,
        sharedTopics: _sharedTopics,
        guestTrackedTopics: _guestTrackedTopics,
      );
      final canKeepCurrentTopic =
          remainingTopics.any((item) => item.id == targetTopic.id);
      _setSelectedTopicId(canKeepCurrentTopic
          ? targetTopic.id
          : (trackedTopics.isNotEmpty ? trackedTopics.first.id : null));
    }
  }

  Future<void> refreshTimeline() async {
    final topic = selectedTopic;
    if (topic == null) {
      return;
    }

    isRefreshing = true;
    errorMessage = null;
    notifyListeners();

    try {
      _entriesByTopic.remove(topic.id);
      _timelineSearchEntriesByTopic.remove(topic.id);
      await _ensureTimelineLoaded(topic.id);
      if (timelineSearchQuery.trim().isNotEmpty) {
        _seedTimelineSearchEntries(topic.id, timelineSearchQuery);
        await _searchTimelineForSelectedTopic(timelineSearchQuery);
      }
    } catch (error) {
      errorMessage = '刷新失败：$error';
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> selectTopic(Topic topic, {bool trackHistory = true}) async {
    _setSelectedTopicId(topic.id);
    if (trackHistory) {
      historyTopicIds =
          _topicCatalogService.recordViewedTopic(topic.id, historyTopicIds);
    }
    notifyListeners();
    await _ensureTimelineLoaded(topic.id);
    await _markFollowedTopicViewedLocally(topic.id);
    if (timelineSearchQuery.trim().isNotEmpty) {
      _seedTimelineSearchEntries(topic.id, timelineSearchQuery);
      await _searchTimelineForSelectedTopic(timelineSearchQuery);
    }
    await _persistTimelinePreferences();
    notifyListeners();
  }

  Future<void> openTopicById(
    String topicId, {
    bool trackHistory = true,
    bool requestShellNavigation = true,
  }) async {
    Topic? topic = _findTopicById(topicId);
    if (topic == null) {
      final detail = await _topicRemoteService.fetchTopicDetail(topicId);
      _syncTopicDetail(detail);
      topic = _findTopicById(topicId) ?? _topicTimelineMapper.toTopic(detail);
      if (_findTopicById(topicId) == null) {
        _trackedTopics
            .removeWhere((trackedTopic) => trackedTopic.id == topicId);
        _trackedTopics.add(topic);
      }
      notifyListeners();
    }

    await selectTopic(topic, trackHistory: trackHistory);
    if (requestShellNavigation) {
      _openTopicRequestToken += 1;
      notifyListeners();
    }
  }

  void toggleSortOrder() {
    sortOrder = sortOrder == TimelineSortOrder.chronological
        ? TimelineSortOrder.reverseChronological
        : TimelineSortOrder.chronological;
    unawaited(_localStorage.saveSortOrder(sortOrder));
    notifyListeners();
  }

  bool isFollowing(Topic topic) =>
      _trackedTopics.any((item) => item.id == topic.id);

  bool isPinned(Topic topic) => pinnedTopicIds.contains(topic.id);

  void setTrackedTopicSearchQuery(String value) {
    if (trackedTopicSearchQuery == value) {
      return;
    }
    trackedTopicSearchQuery = value;
    notifyListeners();
  }

  void setTimelineSearchQuery(String value) {
    if (timelineSearchQuery == value) {
      return;
    }
    timelineSearchQuery = value;
    if (value.trim().isEmpty) {
      final topicId = selectedTopicId;
      if (topicId != null) {
        _timelineSearchEntriesByTopic.remove(topicId);
      }
      _timelineSearchRequestToken += 1;
      notifyListeners();
      return;
    }
    final topicId = selectedTopicId;
    if (topicId != null) {
      _seedTimelineSearchEntries(topicId, value);
    }
    notifyListeners();
    unawaited(_searchTimelineForSelectedTopic(value));
  }

  void toggleMajorNodesOnly() {
    final nextValue = !showOnlyMajorNodes;
    showOnlyMajorNodes = nextValue;
    if (nextValue) {
      showOnlyFavoriteNodes = false;
    }
    notifyListeners();
  }

  void setRecommendationSearchQuery(String value) {
    if (recommendationSearchQuery == value) {
      return;
    }
    recommendationSearchQuery = value;
    notifyListeners();
  }

  void showPersonalizedRecommendations() {
    if (recommendationMode == RecommendationMode.personalized) {
      return;
    }

    recommendationMode = RecommendationMode.personalized;
    notifyListeners();
  }

  void showHotRecommendations() {
    if (recommendationMode == RecommendationMode.hot) {
      return;
    }

    recommendationMode = RecommendationMode.hot;
    notifyListeners();
  }

  void showExploreRecommendations() {
    if (recommendationMode == RecommendationMode.explore) {
      return;
    }

    recommendationMode = RecommendationMode.explore;
    notifyListeners();
  }

  void showHistoryRecommendations() {
    if (recommendationMode == RecommendationMode.history) {
      return;
    }

    recommendationMode = RecommendationMode.history;
    notifyListeners();
  }

  Future<void> loadRecommendations() async {
    await _loadRecommendations();
    notifyListeners();
  }

  Future<void> refreshRecommendations() async {
    await _loadRecommendations(
      preserveExistingOnFailure: true,
      showErrorOnFailure: true,
      showFeedbackOnSuccess: true,
    );
    notifyListeners();
  }

  Future<void> refreshTrackedTopics() async {
    var refreshFailed = false;
    Object? refreshError;

    if (session != null) {
      try {
        await _refreshFollowedTopicsFromServer();
      } catch (error) {
        refreshFailed = true;
        refreshError = error;
      }
    }

    final trackedTopicIds = _trackedTopics
        .where(_isServerManagedTopic)
        .map((topic) => topic.id)
        .toList(growable: false);

    for (final topicId in trackedTopicIds) {
      final previousEntries = _entriesByTopic[topicId];
      final previousBuckets = _timelineBucketsByTopic[topicId];
      final previousSearchEntries = _timelineSearchEntriesByTopic[topicId];
      _entriesByTopic.remove(topicId);
      _timelineBucketsByTopic.remove(topicId);
      _timelineSearchEntriesByTopic.remove(topicId);

      try {
        await _ensureTimelineLoaded(topicId);
      } catch (error) {
        refreshFailed = true;
        refreshError ??= error;
        if (previousEntries != null) {
          _entriesByTopic[topicId] = previousEntries;
        }
        if (previousBuckets != null) {
          _timelineBucketsByTopic[topicId] = previousBuckets;
        }
        if (previousSearchEntries != null) {
          _timelineSearchEntriesByTopic[topicId] = previousSearchEntries;
        }
      }
    }

    if (refreshFailed) {
      _trackedTopicsRefreshNoticeIsError = true;
      _trackedTopicsRefreshNotice = '刷新关注列表失败，已保留当前内容';
      if (refreshError != null) {
        _setErrorMessage('刷新关注列表失败：$refreshError');
      }
    } else {
      _trackedTopicsRefreshNoticeIsError = false;
      _trackedTopicsRefreshNotice =
          '已刷新关注列表 · ${_formatRecommendationGeneratedAt(DateTime.now())}';
      await _persistTimelinePreferences();
    }
    notifyListeners();
  }

  bool isTopicInitializationRetryInFlight(String topicId) {
    return _topicInitializationRetryIds.contains(topicId);
  }

  Future<void> loadMyTopics({bool force = false}) async {
    if (session == null) {
      _ownedTopics.clear();
      _ownedTopicItems.clear();
      _myTopicsGeneratedAt = null;
      isLoadingMyTopics = false;
      notifyListeners();
      return;
    }

    if (isLoadingMyTopics || (!force && _ownedTopicItems.isNotEmpty)) {
      return;
    }

    isLoadingMyTopics = true;
    notifyListeners();

    try {
      final response = await _topicRemoteService.fetchMyTopics();
      _applyMyTopicsResponse(response);
    } catch (error) {
      _myTopicsRefreshNoticeIsError = true;
      _myTopicsRefreshNotice = '加载我的专题失败';
      _setErrorMessage('加载我的专题失败：$error');
    } finally {
      isLoadingMyTopics = false;
      notifyListeners();
    }
  }

  void _setSelectedTopicId(String? topicId) {
    final topicChanged = selectedTopicId != topicId;
    selectedTopicId = topicId;
    if (topicChanged) {
      showOnlyMajorNodes = false;
      showOnlyFavoriteNodes = false;
    }
  }

  Future<void> refreshMyTopics() async {
    if (session == null) {
      return;
    }

    try {
      final response = await _topicRemoteService.fetchMyTopics();
      _applyMyTopicsResponse(
        response,
        showFeedbackOnSuccess: true,
      );
    } catch (error) {
      _myTopicsRefreshNoticeIsError = true;
      _myTopicsRefreshNotice = '刷新我的专题失败，已保留当前内容';
      _setErrorMessage('刷新我的专题失败：$error');
    }
    notifyListeners();
  }

  Future<void> retryTopicInitialization(String topicId) async {
    if (session == null || _topicInitializationRetryIds.contains(topicId)) {
      return;
    }

    _topicInitializationRetryIds.add(topicId);
    notifyListeners();

    try {
      final result =
          await _topicRemoteService.retryTopicInitialization(topicId);
      _cacheTopicRuntimeState(
        topicId: result.topicId,
        status: result.status,
        initializationState: result.initializationState,
      );
      final itemIndex =
          _ownedTopicItems.indexWhere((item) => item.topicId == result.topicId);
      if (itemIndex >= 0) {
        final current = _ownedTopicItems[itemIndex];
        _ownedTopicItems[itemIndex] = MyTopicItemDto(
          topicId: current.topicId,
          title: current.title,
          summary: current.summary,
          status: result.status,
          kind: current.kind,
          visibility: current.visibility,
          initializationState: result.initializationState,
          updatedAt: DateTime.now(),
          isFollowed: current.isFollowed,
        );
      }
      _entriesByTopic.remove(result.topicId);
      _timelineBucketsByTopic.remove(result.topicId);
      _timelineSearchEntriesByTopic.remove(result.topicId);
      if (selectedTopicId == result.topicId) {
        await _ensureTimelineLoaded(result.topicId);
      }
      _myTopicsRefreshNoticeIsError = false;
      _myTopicsRefreshNotice =
          '已重新发起初始化 · ${_formatRecommendationGeneratedAt(DateTime.now())}';
    } catch (error) {
      _myTopicsRefreshNoticeIsError = true;
      _myTopicsRefreshNotice = '重试初始化失败，请稍后再试';
      rethrow;
    } finally {
      _topicInitializationRetryIds.remove(topicId);
      notifyListeners();
    }
  }

  Future<void> toggleFollow(Topic topic) async {
    if (_followMutationTopicIds.contains(topic.id)) {
      return;
    }

    if (session == null) {
      await _toggleGuestFollow(topic);
      return;
    }

    if (!_ensureSignedInForPersistentAction('登录后即可关注专题，并在不同设备间同步。')) {
      return;
    }

    _followMutationTopicIds.add(topic.id);
    notifyListeners();

    final existingIndex =
        _trackedTopics.indexWhere((item) => item.id == topic.id);
    try {
      if (existingIndex >= 0) {
        await removeTrackedTopic(topic);
        return;
      }

      if (_isServerManagedTopic(topic) && session != null) {
        final result = await _followedTopicRemoteService.followTopic(
          userId: session!.userId,
          topicId: topic.id,
        );
        _applyFollowedTopicMutation(result, fallbackTopic: topic);
        _setSelectedTopicId(topic.id);
        notifyListeners();
        await _persistFollowedTopicCacheMirror();
        await _persistTimelinePreferences();
        try {
          await _ensureTimelineLoaded(topic.id);
        } catch (_) {
          // 关注状态以服务端 mutation 为准，时间线预取失败不回滚关注结果。
        }
        notifyListeners();
        return;
      }

      if (!_ensureTrackedTopicQuotaAvailable()) {
        queueDeferredFollowTopic(topic);
        return;
      }

      _sharedTopics.removeWhere((item) => item.id == topic.id);
      if (topic.id.startsWith('custom-') &&
          _customTopics.every((item) => item.id != topic.id)) {
        _customTopics.add(topic);
      }
      _trackedTopics.add(topic);
      _setSelectedTopicId(topic.id);
      notifyListeners();
      await _persistCustomTimelines();
      await _persistSharedTopics();
      await _persistTimelinePreferences();
      try {
        await _ensureTimelineLoaded(topic.id);
      } catch (_) {
        // 本地专题允许先关注，时间线稍后再同步。
      }
      notifyListeners();
    } catch (error) {
      if (await _recoverFollowMutationConflict(error, topic)) {
        return;
      }
      _handleFollowMutationError(error);
    } finally {
      _followMutationTopicIds.remove(topic.id);
      notifyListeners();
    }
  }

  Future<void> removeTrackedTopic(Topic topic) async {
    final existingIndex =
        _trackedTopics.indexWhere((item) => item.id == topic.id);
    if (existingIndex < 0) {
      return;
    }

    try {
      if (_isServerManagedTopic(topic) && session != null) {
        final result = await _followedTopicRemoteService.unfollowTopic(
          userId: session!.userId,
          topicId: topic.id,
        );
        _applyFollowedTopicMutation(result, fallbackTopic: topic);
        await _persistFollowedTopicCacheMirror();
        await _persistTimelinePreferences();
        await _retryPendingGuestSyncAfterQuotaChange();
        notifyListeners();
        return;
      }

      _removeTrackedTopicLocally(topic);
      await _persistGuestTimelinePreferences();
      notifyListeners();
    } catch (error) {
      _handleFollowMutationError(error);
    }
  }

  Future<TimelineDraft> expandTimelineKeywords(
    String keywords, {
    String? categoryHint,
    TopicDefinition? currentDefinition,
    TopicDefinition? removedDefinition,
    TimelineDirectionCandidate? selectedDirection,
    TimelineExpansionProgressCallback? onProgress,
  }) async {
    final normalized = keywords.trim();
    if (normalized.isEmpty) {
      throw Exception('请先输入关键词。');
    }

    isGeneratingTimelineDraft = true;
    errorMessage = null;
    notifyListeners();

    try {
      final draft = await _creationService.expandKeywords(
        normalized,
        variation: _draftVariation,
        categoryHint: categoryHint,
        interestCategoryIds: _userInterestCategoryIds,
        currentDefinition: currentDefinition,
        removedDefinition: removedDefinition,
        selectedDirection: selectedDirection,
        onProgress: onProgress,
      );
      _draftVariation += 1;
      return draft;
    } finally {
      isGeneratingTimelineDraft = false;
      notifyListeners();
    }
  }

  Future<List<TimelineDirectionCandidate>> suggestTimelineDirections(
    String keywords, {
    String? categoryHint,
  }) async {
    final normalized = keywords.trim();
    if (normalized.isEmpty) {
      throw Exception('请先输入关键词。');
    }

    isGeneratingTimelineDraft = true;
    errorMessage = null;
    notifyListeners();

    try {
      return await _creationService.suggestDirections(
        normalized,
        categoryHint: categoryHint,
        interestCategoryIds: _userInterestCategoryIds,
      );
    } finally {
      isGeneratingTimelineDraft = false;
      notifyListeners();
    }
  }

  Future<Topic> createTimelineFromDraft(
    TimelineDraft draft, {
    DateTime? startDate,
  }) async {
    if (!_ensureTrackedTopicQuotaAvailable()) {
      throw Exception(_trackedTopicLimitReachedMessage());
    }

    return _createTimelineRemotelyFromRequest(
      _buildTopicCreateRequest(
        draft,
        startDate: startDate ?? draft.startDate,
      ),
    );
  }

  Future<Topic> createTimelineFromDirection({
    required String keywords,
    required TimelineDirectionCandidate candidate,
  }) async {
    if (!_ensureTrackedTopicQuotaAvailable()) {
      throw Exception(_trackedTopicLimitReachedMessage());
    }

    return _createTimelineRemotelyFromRequest(
      _buildTopicCreateRequestFromDirection(
        keywords: keywords,
        candidate: candidate,
      ),
    );
  }

  void queueDeferredTimelineCreation(
    TimelineDraft draft, {
    DateTime? startDate,
  }) {
    _deferredTimelineCreationRequest = _DeferredTimelineCreationRequest(
      request: _buildTopicCreateRequest(
        draft,
        startDate: startDate ?? draft.startDate,
      ),
    );
    _deferredTimelineCreationErrorMessage = null;
    _deferredTimelineCreationResultTopic = null;
  }

  void queueDeferredTimelineCreationFromDirection({
    required String keywords,
    required TimelineDirectionCandidate candidate,
  }) {
    _deferredTimelineCreationRequest = _DeferredTimelineCreationRequest(
      request: _buildTopicCreateRequestFromDirection(
        keywords: keywords,
        candidate: candidate,
      ),
    );
    _deferredTimelineCreationErrorMessage = null;
    _deferredTimelineCreationResultTopic = null;
  }

  void queueDeferredFollowTopic(Topic topic) {
    _deferredFollowTopic = topic;
  }

  void discardDeferredFollowTopic() {
    _deferredFollowTopic = null;
  }

  void discardDeferredTimelineCreation() {
    _deferredTimelineCreationRequest = null;
    _deferredTimelineCreationErrorMessage = null;
    _deferredTimelineCreationResultTopic = null;
  }

  Future<Topic> _createTimelineRemotelyFromRequest(
    TopicCreateRequestDto request,
  ) async {
    final isGuestCreate = session == null;
    final result = await _topicRemoteService.createTopic(
      request,
    );
    if (!isGuestCreate) {
      _applyCapabilities(result.capabilities);
    }

    final topic = _topicTimelineMapper.toTopic(result.topic);
    _cacheTopicRuntimeState(
      topicId: topic.id,
      status: result.topic.status,
      initializationState:
          result.initializationState ?? result.topic.initializationState,
    );
    if (!isGuestCreate && result.topic.kind == 'user_created') {
      final ownedTopicItem = MyTopicItemDto(
        topicId: result.topic.topicId,
        title: result.topic.title,
        summary: result.topic.summary,
        status: result.topic.status ?? 'draft',
        kind: result.topic.kind ?? 'user_created',
        visibility: result.topic.visibility ?? 'private',
        initializationState: result.initializationState ??
            result.topic.initializationState ??
            'pending',
        updatedAt: DateTime.now(),
        isFollowed: result.followed,
      );
      final ownedIndex = _ownedTopicItems
          .indexWhere((item) => item.topicId == ownedTopicItem.topicId);
      if (ownedIndex >= 0) {
        _ownedTopicItems[ownedIndex] = ownedTopicItem;
      } else {
        _ownedTopicItems.insert(0, ownedTopicItem);
      }
      final ownedTopicIndex =
          _ownedTopics.indexWhere((item) => item.id == topic.id);
      if (ownedTopicIndex >= 0) {
        _ownedTopics[ownedTopicIndex] = topic;
      } else {
        _ownedTopics.insert(0, topic);
      }
    }

    _entriesByTopic.remove(topic.id);
    _timelineBucketsByTopic.remove(topic.id);
    _timelineSearchEntriesByTopic.remove(topic.id);
    _trackedTopicLatestEntriesById.remove(topic.id);
    _sharedTopics.removeWhere((item) => item.id == topic.id);
    _customTopics.removeWhere((item) => item.id == topic.id);
    _upsertGuestTrackedTopic(topic);
    if (isGuestCreate) {
      await _trackGuestCreatedTopicId(topic.id);
    }

    if (result.followed) {
      final trackedIndex =
          _trackedTopics.indexWhere((item) => item.id == topic.id);
      if (trackedIndex >= 0) {
        _trackedTopics[trackedIndex] = topic;
      } else {
        _trackedTopics.add(topic);
      }
      if (isGuestCreate) {
        await _persistGuestTimelinePreferences();
      } else {
        _upsertFollowedTopicItem(
          FollowedTopicItemDto(
            followId: 'created-${topic.id}',
            topicId: topic.id,
            title: topic.name,
            summary: topic.tagline,
            isPinned: false,
            followedAt: DateTime.now(),
            hasRecentUpdate: false,
          ),
        );
        await _persistFollowedTopicCacheMirror();
      }
    } else {
      final recommendedIndex =
          _recommendedTopics.indexWhere((item) => item.id == topic.id);
      if (recommendedIndex >= 0) {
        _recommendedTopics[recommendedIndex] = topic;
      } else {
        _recommendedTopics.add(topic);
      }
    }

    _setSelectedTopicId(topic.id);
    await _persistTimelinePreferences();
    notifyListeners();
    await _ensureTimelineLoaded(topic.id);
    notifyListeners();
    if (_isTopicInitializing(topic.id)) {
      _scheduleInitializingTopicPoll(topic.id);
    }
    return topic;
  }

  Future<void> _resumeDeferredTimelineCreationAfterLogin() async {
    final request = _deferredTimelineCreationRequest;
    if (request == null || session == null) {
      return;
    }

    _deferredTimelineCreationRequest = null;
    _deferredTimelineCreationResultTopic = null;
    _deferredTimelineCreationErrorMessage = null;

    try {
      final topic = await _createTimelineRemotelyFromRequest(request.request);
      _deferredTimelineCreationResultTopic = topic;
    } catch (error) {
      final normalizedError = '$error'.replaceFirst('Exception: ', '');
      _deferredTimelineCreationErrorMessage = normalizedError;
      _setErrorMessage(normalizedError);
    } finally {
      _deferredTimelineCreationResultToken += 1;
      notifyListeners();
    }
  }

  Future<void> _resumeDeferredFollowAfterLogin() async {
    final topic = _deferredFollowTopic;
    final currentSession = session;
    if (topic == null || currentSession == null) {
      return;
    }

    _deferredFollowTopic = null;

    try {
      final resolvedTopic = _findTopicById(topic.id) ?? topic;
      if (_trackedTopics.any((item) => item.id == resolvedTopic.id)) {
        return;
      }

      final result = await _followedTopicRemoteService.followTopic(
        userId: currentSession.userId,
        topicId: resolvedTopic.id,
      );
      _applyFollowedTopicMutation(result, fallbackTopic: resolvedTopic);
      await _persistFollowedTopicCacheMirror();
      await _persistTimelinePreferences();
      try {
        await _ensureTimelineLoaded(resolvedTopic.id);
      } catch (_) {
        // 登录后自动补关注时，时间线预取失败不回滚关注结果。
      }
      await _loadRecommendations();
      notifyListeners();
    } catch (error) {
      final recovered = await _recoverFollowMutationConflict(error, topic);
      if (!recovered) {
        _handleFollowMutationError(error);
      }
    }
  }

  TopicCreateRequestDto _buildTopicCreateRequest(
    TimelineDraft draft, {
    required DateTime startDate,
  }) {
    return TopicCreateRequestDto(
      title: draft.topicName,
      summary: draft.tagline,
      startDate: startDate,
      keywords: draft.keywords,
      definition: TopicDefinitionDto(
        coreKeywords: draft.definition.coreKeywords,
        extendedKeywords: draft.definition.relatedKeywords,
        excludedKeywords: draft.definition.excludedKeywords,
        trackingDirection: draft.trackingDirection,
        trackingQuestion: draft.trackingQuestion,
        topicObject: draft.topicObject,
        topicScope: draft.topicScope,
        timelineType: draft.timelineType,
        timelineFocus: draft.timelineFocus,
        nodeSelectionPolicy: draft.nodeSelectionPolicy,
        startDateConfidence: draft.startDateConfidence,
        timelineTypeConfidence: draft.timelineTypeConfidence,
        sourceEvidenceCount: draft.sourceEvidenceCount,
        recentActivityStatus: draft.recentActivityStatus,
        recentEvidenceCount: draft.recentEvidenceCount,
        latestRelevantSourceAt: draft.latestRelevantSourceAt,
        trackingViability: draft.trackingViability,
        trackingViabilityReason: draft.trackingViabilityReason,
      ),
    );
  }

  TopicCreateRequestDto _buildTopicCreateRequestFromDirection({
    required String keywords,
    required TimelineDirectionCandidate candidate,
  }) {
    final title = candidate.title.trim().isEmpty
        ? keywords.trim()
        : candidate.title.trim();
    final summary = candidate.trackingDirection.trim().isEmpty
        ? (candidate.reason.trim().isEmpty ? title : candidate.reason.trim())
        : candidate.trackingDirection.trim();
    final coreKeywords = _keywordTokensForCreate(keywords);
    final topicObject = candidate.topicObject.trim();
    if (topicObject.isNotEmpty && !coreKeywords.contains(topicObject)) {
      coreKeywords.add(topicObject);
    }
    if (coreKeywords.isEmpty && title.isNotEmpty) {
      coreKeywords.add(title);
    }

    return TopicCreateRequestDto(
      title: title,
      summary: summary,
      keywords: keywords.trim(),
      selectedDirection: candidate,
      definition: TopicDefinitionDto(
        coreKeywords: coreKeywords.take(6).toList(growable: false),
        extendedKeywords: const <String>[],
        excludedKeywords: const <String>[],
        trackingDirection: candidate.trackingDirection,
        trackingQuestion: candidate.trackingQuestion,
        topicObject: candidate.topicObject,
        topicScope: candidate.topicScope,
        timelineType: candidate.timelineType,
        timelineFocus: candidate.title,
        startDateConfidence: 'medium',
        timelineTypeConfidence: candidate.timelineTypeConfidence,
        sourceEvidenceCount: candidate.sourceEvidenceCount,
        recentActivityStatus: candidate.recentActivityStatus,
        recentEvidenceCount: candidate.recentEvidenceCount,
        latestRelevantSourceAt: candidate.latestRelevantSourceAt,
        trackingViability: candidate.trackingViability,
        trackingViabilityReason: candidate.reason,
      ),
    );
  }

  List<String> _keywordTokensForCreate(String value) {
    final seen = <String>{};
    final tokens = value
        .split(RegExp(r'[\s,，、;；/|]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);
    return <String>[
      for (final token in tokens)
        if (seen.add(token)) token,
    ];
  }

  bool _isTopicInitializing(String topicId) {
    final state = topicInitializationStateFor(topicId);
    final status = topicStatusFor(topicId);
    if (state == 'failed' || state == 'ready') {
      return false;
    }
    return state == 'pending' ||
        state == 'running' ||
        (status == 'draft' && (state == null || state.isEmpty));
  }

  void _scheduleInitializingTopicPoll(String topicId) {
    if (_isDisposed ||
        !_isTopicInitializing(topicId) ||
        _initializationPollTimers.containsKey(topicId)) {
      return;
    }
    _initializationPollTimers[topicId] = Timer(const Duration(seconds: 2), () {
      _initializationPollTimers.remove(topicId);
      unawaited(_refreshInitializingTopic(topicId));
    });
  }

  Future<void> _refreshInitializingTopic(String topicId) async {
    if (_isDisposed || !_isTopicInitializing(topicId)) {
      return;
    }
    try {
      _entriesByTopic.remove(topicId);
      _timelineBucketsByTopic.remove(topicId);
      _timelineSearchEntriesByTopic.remove(topicId);
      await _ensureTimelineLoaded(topicId);
      notifyListeners();
    } catch (error) {
      _setErrorMessage('刷新初始化状态失败：$error');
    }
    _scheduleInitializingTopicPoll(topicId);
  }

  Future<bool> pinTopic(Topic topic) async {
    if (_trackedTopics.every((item) => item.id != topic.id) ||
        pinnedTopicIds.contains(topic.id)) {
      return false;
    }
    if (!_ensureSignedInForPersistentAction('登录后即可置顶专题，并在不同设备间同步。')) {
      return false;
    }
    if (_isServerManagedTopic(topic) && session != null) {
      final result = await _followedTopicRemoteService.pinTopic(
        userId: session!.userId,
        topicId: topic.id,
      );
      _applyFollowedTopicMutation(result, fallbackTopic: topic);
      await _persistFollowedTopicCacheMirror();
      await _persistTimelinePreferences();
      notifyListeners();
      return true;
    }
    pinnedTopicIds = <String>[topic.id, ...pinnedTopicIds];
    await _persistTimelinePreferences();
    notifyListeners();
    return true;
  }

  Future<bool> unpinTopic(Topic topic) async {
    if (!pinnedTopicIds.contains(topic.id)) {
      return false;
    }
    if (!_ensureSignedInForPersistentAction('登录后即可调整置顶状态，并在不同设备间同步。')) {
      return false;
    }
    if (_isServerManagedTopic(topic) && session != null) {
      final result = await _followedTopicRemoteService.unpinTopic(
        userId: session!.userId,
        topicId: topic.id,
      );
      _applyFollowedTopicMutation(result, fallbackTopic: topic);
      await _persistFollowedTopicCacheMirror();
      await _persistTimelinePreferences();
      notifyListeners();
      return true;
    }
    pinnedTopicIds =
        pinnedTopicIds.where((topicId) => topicId != topic.id).toList();
    await _persistTimelinePreferences();
    notifyListeners();
    return true;
  }

  Future<String> buildShareMessage(Topic topic) async {
    if (_isServerManagedTopic(topic)) {
      final shareResult =
          await _shareRemoteService.createShare(topicId: topic.id);
      return _shareService.buildResolvedShareMessage(
        topicName: topic.name,
        shareUrl: shareResult.shareUrl,
      );
    }

    final entries = _entriesByTopic[topic.id] ?? const <TimelineEntry>[];
    return _shareService.buildShareMessage(topic: topic, entries: entries);
  }

  Future<void> handleIncomingRoute(String rawRoute) async {
    final normalizedRoute = rawRoute.trim();
    if (normalizedRoute.isEmpty || normalizedRoute == '/') {
      return;
    }

    final parsed = _shareService.parseIncomingRoute(rawRoute);
    if (parsed == null) {
      _setErrorMessage('分享链接无效或已损坏。', notify: true);
      return;
    }

    if (parsed.isShareToken) {
      _deferredSharedRoute = null;
      await _consumeResolvedShare(parsed.shareToken!);
      return;
    }

    if (parsed.isImportedPayload) {
      _deferredSharedRoute = null;
      await _consumeImportedSharedTopic(parsed);
      return;
    }

    _deferredSharedRoute = rawRoute;
    await _resolveDeferredSharedRoute();
  }

  Future<void> dismissPendingSharedTopic() async {
    if (_pendingSharedTopic == null) {
      return;
    }

    _pendingSharedTopic = null;
    notifyListeners();
  }

  Future<void> openPendingSharedTopic({required bool follow}) async {
    final preview = _pendingSharedTopic;
    if (preview == null) {
      return;
    }

    final openPlan = _sharedTopicFlowService.buildOpenPlan(
      preview: preview,
      follow: follow,
      allTopics: allTopics,
      historyTopicIds: historyTopicIds,
      isFollowing: isFollowing,
      hasCustomTopic: (topicId) =>
          _customTopics.any((item) => item.id == topicId),
    );

    final shouldRemoteFollow = follow &&
        preview.allowFollow &&
        !preview.alreadyFollowing &&
        session != null &&
        _isServerManagedTopic(openPlan.topic);

    if (shouldRemoteFollow) {
      try {
        final result = await _followedTopicRemoteService.followTopic(
          userId: session!.userId,
          topicId: openPlan.topic.id,
        );
        _applyFollowedTopicMutation(result, fallbackTopic: openPlan.topic);
        await _persistFollowedTopicCacheMirror();
      } catch (error) {
        final recovered =
            await _recoverFollowMutationConflict(error, openPlan.topic);
        if (!recovered) {
          _setErrorMessage('关注状态更新失败：$error', notify: true);
          return;
        }
      }
    }

    if (openPlan.shouldRemoveFromShared) {
      _sharedTopics.removeWhere((item) => item.id == openPlan.topic.id);
    }
    if (openPlan.shouldAddToCustom) {
      _customTopics.add(openPlan.topic);
    }
    if (openPlan.shouldAddToTracked && !shouldRemoteFollow) {
      _trackedTopics.add(openPlan.topic);
      await _persistCustomTimelines();
      await _persistSharedTopics();
    }

    final resolvedTopic = _findTopicById(openPlan.topic.id) ?? openPlan.topic;
    _setSelectedTopicId(resolvedTopic.id);
    _pendingSharedTopic = null;
    historyTopicIds = _topicCatalogService.recordViewedTopic(
        resolvedTopic.id, historyTopicIds);
    await _ensureTimelineLoaded(resolvedTopic.id);
    await _persistTimelinePreferences();
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void showError(String message) {
    _setErrorMessage(message, notify: true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _resendTimer?.cancel();
    for (final timer in _initializationPollTimers.values) {
      timer.cancel();
    }
    _initializationPollTimers.clear();
    super.dispose();
  }

  Future<void> _ensureTimelineLoaded(String? topicId) async {
    if (topicId == null || _entriesByTopic.containsKey(topicId)) {
      return;
    }
    if (!_isServerManagedTopicId(topicId)) {
      _entriesByTopic[topicId] =
          _entriesByTopic[topicId] ?? const <TimelineEntry>[];
      _timelineBucketsByTopic.remove(topicId);
      _timelineStatsByTopic.remove(topicId);
      return;
    }

    final response = await _topicRemoteService.fetchTopicTimeline(topicId);
    _syncTopicDetail(response.topic);
    _timelineStatsByTopic[topicId] = response.stats;
    _entriesByTopic[topicId] = _topicTimelineMapper.toTimelineEntries(response);
    final buckets = _topicTimelineMapper.toTimelineBuckets(response);
    _timelineBucketsByTopic[topicId] = buckets;
    _applyTimelineFavoriteBuckets(response, buckets);
  }

  Future<void> _searchTimelineForSelectedTopic(String query) async {
    final topicId = selectedTopicId;
    if (topicId == null) {
      return;
    }

    final normalizedQuery = query.trim();
    final requestToken = ++_timelineSearchRequestToken;
    if (normalizedQuery.isEmpty) {
      _timelineSearchEntriesByTopic.remove(topicId);
      return;
    }

    try {
      final response = await _topicRemoteService.searchTimeline(
        topicId: topicId,
        query: normalizedQuery,
      );
      if (!_isTimelineSearchResultCurrent(
        requestToken: requestToken,
        topicId: topicId,
        query: normalizedQuery,
      )) {
        return;
      }

      _timelineSearchEntriesByTopic[topicId] =
          _topicTimelineMapper.toSearchTimelineEntries(response);
    } catch (_) {
      if (!_isServerManagedTopicId(topicId)) {
        await _ensureTimelineLoaded(topicId);
        if (!_isTimelineSearchResultCurrent(
          requestToken: requestToken,
          topicId: topicId,
          query: normalizedQuery,
        )) {
          return;
        }

        final normalizedLowerQuery = normalizedQuery.toLowerCase();
        final fallbackEntries =
            (_entriesByTopic[topicId] ?? const <TimelineEntry>[])
                .where((entry) => _topicCatalogService.matchesEntryQuery(
                    entry, normalizedLowerQuery))
                .toList();
        _timelineSearchEntriesByTopic[topicId] = fallbackEntries;
      }
    }

    notifyListeners();
  }

  void _seedTimelineSearchEntries(String topicId, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      _timelineSearchEntriesByTopic.remove(topicId);
      return;
    }

    final provisionalEntries =
        (_entriesByTopic[topicId] ?? const <TimelineEntry>[])
            .where((entry) =>
                _topicCatalogService.matchesEntryQuery(entry, normalizedQuery))
            .toList();
    _timelineSearchEntriesByTopic[topicId] = provisionalEntries;
  }

  bool _isTimelineSearchResultCurrent({
    required int requestToken,
    required String topicId,
    required String query,
  }) {
    return requestToken == _timelineSearchRequestToken &&
        topicId == selectedTopicId &&
        query == timelineSearchQuery.trim();
  }

  List<TimelineBucket> _buildTimelineBuckets(List<TimelineEntry> entries) {
    final buckets = _bucketingService.makeBuckets(entries, DateTime.now());
    return _sortBuckets(buckets);
  }

  List<TimelineBucket> _sortBuckets(List<TimelineBucket> buckets) {
    final sortedBuckets = List<TimelineBucket>.from(buckets);
    sortedBuckets.sort(
      (a, b) => sortOrder == TimelineSortOrder.chronological
          ? a.periodStart.compareTo(b.periodStart)
          : b.periodStart.compareTo(a.periodStart),
    );
    return sortedBuckets;
  }

  void _syncTopicDetail(TopicDetailDto topicDetailDto) {
    final mappedTopic = _topicTimelineMapper.toTopic(topicDetailDto);
    _cacheTopicRuntimeState(
      topicId: mappedTopic.id,
      status: topicDetailDto.status,
      initializationState: topicDetailDto.initializationState,
    );

    void replaceTopic(List<Topic> topics) {
      final index = topics.indexWhere((item) => item.id == mappedTopic.id);
      if (index >= 0) {
        final existing = topics[index];
        topics[index] = Topic(
          id: mappedTopic.id,
          name: mappedTopic.name,
          tagline: mappedTopic.tagline,
          followerCount: existing.followerCount,
          isHot: existing.isHot,
          definition: mappedTopic.definition ?? existing.definition,
          primaryCategory:
              mappedTopic.primaryCategory ?? existing.primaryCategory,
          categories: mappedTopic.categories.isNotEmpty
              ? mappedTopic.categories
              : existing.categories,
          categoryConfidence:
              mappedTopic.categoryConfidence ?? existing.categoryConfidence,
        );
      }
    }

    replaceTopic(_trackedTopics);
    replaceTopic(_recommendedTopics);
    replaceTopic(_customTopics);
    replaceTopic(_sharedTopics);
    replaceTopic(_guestTrackedTopics);
    replaceTopic(_ownedTopics);

    final ownedItemIndex =
        _ownedTopicItems.indexWhere((item) => item.topicId == mappedTopic.id);
    if (ownedItemIndex >= 0) {
      final existing = _ownedTopicItems[ownedItemIndex];
      _ownedTopicItems[ownedItemIndex] = MyTopicItemDto(
        topicId: existing.topicId,
        title: mappedTopic.name,
        summary: mappedTopic.tagline,
        status: topicDetailDto.status ?? existing.status,
        kind: topicDetailDto.kind ?? existing.kind,
        visibility: topicDetailDto.visibility ?? existing.visibility,
        initializationState:
            topicDetailDto.initializationState ?? existing.initializationState,
        updatedAt: existing.updatedAt,
        isFollowed: topicDetailDto.isFollowed,
        primaryCategory:
            mappedTopic.primaryCategory ?? existing.primaryCategory,
        categories: mappedTopic.categories.isNotEmpty
            ? mappedTopic.categories
            : existing.categories,
        categoryConfidence:
            mappedTopic.categoryConfidence ?? existing.categoryConfidence,
      );
    }
  }

  void _cacheTopicRuntimeState({
    required String topicId,
    String? status,
    String? initializationState,
  }) {
    if (status != null && status.isNotEmpty) {
      _topicStatusById[topicId] = status;
    }
    if (initializationState != null && initializationState.isNotEmpty) {
      _topicInitializationStateById[topicId] = initializationState;
    }
  }

  void _upsertGuestTrackedTopic(Topic topic) {
    final index = _guestTrackedTopics.indexWhere((item) => item.id == topic.id);
    if (index >= 0) {
      _guestTrackedTopics[index] = topic;
    } else {
      _guestTrackedTopics.add(topic);
    }
  }

  void _warmTrackedTimelines({String? excludeTopicId}) {
    final remainingTopicIds = _trackedTopics
        .map((topic) => topic.id)
        .where((topicId) => topicId != excludeTopicId)
        .toList();
    if (remainingTopicIds.isEmpty) {
      return;
    }

    unawaited(_loadTrackedTimelinesInBackground(remainingTopicIds));
  }

  Future<void> _loadTrackedTimelinesInBackground(List<String> topicIds) async {
    var hasUpdates = false;
    for (final topicId in topicIds) {
      if (_entriesByTopic.containsKey(topicId)) {
        continue;
      }
      try {
        await _ensureTimelineLoaded(topicId);
        hasUpdates = true;
      } catch (_) {
        continue;
      }
    }
    if (hasUpdates && !_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> _loadRecommendations({
    bool preserveExistingOnFailure = false,
    bool showErrorOnFailure = false,
    bool showFeedbackOnSuccess = false,
  }) async {
    try {
      final response =
          await _recommendationRemoteService.fetchRecommendations();
      final projection = _recommendationMapper.project(
        response,
        existingTopics: _topicCatalogService.mergeTopics(
          _trackedTopics,
          _recommendedTopics,
          _customTopics,
          _sharedTopics,
          _guestTrackedTopics,
          _ownedTopics,
        ),
      );
      _hasRemoteRecommendations = true;
      _personalizedRecommendationTopics
        ..clear()
        ..addAll(projection.personalizedTopics);
      _hotRecommendationTopics
        ..clear()
        ..addAll(projection.hotTopics);
      _exploreRecommendationTopics
        ..clear()
        ..addAll(projection.exploreTopics);
      _remoteHistoryTopics
        ..clear()
        ..addAll(projection.historyTopics);
      _recommendedTopics
        ..clear()
        ..addAll(projection.mergedTopics);
      _trackedTopicLatestEntriesById.addAll(projection.latestEntriesByTopicId);
      historyTopicIds = <String>[
        ...historyTopicIds,
        ...projection.remoteHistoryTopicIds
            .where((topicId) => !historyTopicIds.contains(topicId)),
      ];
      _recommendationsGeneratedAt = projection.generatedAt;
      if (showFeedbackOnSuccess) {
        _recommendationRefreshNoticeIsError = false;
        _recommendationRefreshNotice = projection.generatedAt == null
            ? '推荐已刷新'
            : '已刷新 · ${_formatRecommendationGeneratedAt(projection.generatedAt!)}';
      }
    } catch (error) {
      if (showErrorOnFailure) {
        _recommendationRefreshNoticeIsError = true;
        _recommendationRefreshNotice = '刷新失败，已保留当前推荐';
      }
      if (preserveExistingOnFailure) {
        return;
      }
      if (!_hasRemoteRecommendations) {
        return;
      }
      _hasRemoteRecommendations = false;
      _personalizedRecommendationTopics.clear();
      _hotRecommendationTopics.clear();
      _exploreRecommendationTopics.clear();
      _remoteHistoryTopics.clear();
    }
  }

  String _formatRecommendationGeneratedAt(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Future<void> openOwnedTopic(String topicId) async {
    Topic? topic = _findTopicById(topicId);
    if (topic == null) {
      for (final ownedTopic in _ownedTopics) {
        if (ownedTopic.id == topicId) {
          topic = ownedTopic;
          break;
        }
      }
    }
    if (topic == null) {
      return;
    }
    await selectTopic(topic);
  }

  void _applyMyTopicsResponse(
    MyTopicListDto response, {
    bool showFeedbackOnSuccess = false,
  }) {
    final items = List<MyTopicItemDto>.from(response.items)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _ownedTopicItems
      ..clear()
      ..addAll(items);
    _ownedTopics
      ..clear()
      ..addAll(items.map(_mapOwnedTopicItemToTopic));
    for (final item in items) {
      _cacheTopicRuntimeState(
        topicId: item.topicId,
        status: item.status,
        initializationState: item.initializationState,
      );
    }
    _myTopicsGeneratedAt = response.generatedAt;
    if (showFeedbackOnSuccess) {
      _myTopicsRefreshNoticeIsError = false;
      _myTopicsRefreshNotice = response.generatedAt == null
          ? '已刷新我的专题'
          : '已刷新我的专题 · ${_formatRecommendationGeneratedAt(response.generatedAt!)}';
    }
  }

  Topic _mapOwnedTopicItemToTopic(MyTopicItemDto item) {
    return Topic(
      id: item.topicId,
      name: item.title,
      tagline: item.summary,
      followerCount: 0,
      isHot: false,
    );
  }

  void _normalizeSelectedTopicForServerRuntime() {
    if (!_preferServerRuntimeTopics) {
      return;
    }

    final selectedId = selectedTopicId;
    final serverSelectableTopics = <Topic>[
      ..._trackedTopics,
      ..._recommendedTopics.where(
        (topic) => _trackedTopics.every((tracked) => tracked.id != topic.id),
      ),
    ];
    if (serverSelectableTopics.isEmpty) {
      return;
    }

    if (selectedId != null &&
        serverSelectableTopics.any((topic) => topic.id == selectedId)) {
      return;
    }

    _setSelectedTopicId(serverSelectableTopics.first.id);
  }

  void _normalizeSelectedTopicForPublicRuntime() {
    final publicTopics = _topicCatalogService.mergeTopics(
      _trackedTopics,
      _recommendedTopics,
      _customTopics,
      _sharedTopics,
      _guestTrackedTopics,
      _ownedTopics,
    );
    if (publicTopics.isEmpty) {
      _setSelectedTopicId(null);
      return;
    }

    final selectedId = selectedTopicId;
    if (selectedId != null &&
        publicTopics.any((topic) => topic.id == selectedId)) {
      return;
    }

    _setSelectedTopicId(publicTopics.first.id);
  }

  RecommendationMode _defaultRecommendationModeForCurrentSession() {
    if (_personalizedRecommendationTopics.isNotEmpty && session != null) {
      return RecommendationMode.personalized;
    }
    if (_hotRecommendationTopics.isNotEmpty) {
      return RecommendationMode.hot;
    }
    if (_exploreRecommendationTopics.isNotEmpty) {
      return RecommendationMode.explore;
    }
    return RecommendationMode.hot;
  }

  Future<void> _toggleGuestFollow(Topic topic) async {
    _followMutationTopicIds.add(topic.id);
    notifyListeners();

    try {
      final existingIndex =
          _trackedTopics.indexWhere((item) => item.id == topic.id);
      if (existingIndex >= 0) {
        _removeTrackedTopicLocally(topic);
        await _persistGuestTimelinePreferences();
        notifyListeners();
        return;
      }

      if (!_ensureTrackedTopicQuotaAvailable()) {
        if (_isServerManagedTopic(topic)) {
          queueDeferredFollowTopic(topic);
        }
        return;
      }

      _sharedTopics.removeWhere((item) => item.id == topic.id);
      if (topic.id.startsWith('custom-') &&
          _customTopics.every((item) => item.id != topic.id)) {
        _customTopics.add(topic);
      }
      _trackedTopics.add(topic);
      _setSelectedTopicId(topic.id);
      notifyListeners();
      await _persistCustomTimelines();
      await _persistSharedTopics();
      await _persistGuestTimelinePreferences();
      try {
        await _ensureTimelineLoaded(topic.id);
      } catch (_) {
        // 游客关注本地先落盘，时间线预取失败不影响关注结果。
      }
      notifyListeners();
    } catch (error) {
      _setErrorMessage('关注状态更新失败：$error', notify: true);
    } finally {
      _followMutationTopicIds.remove(topic.id);
      notifyListeners();
    }
  }

  bool _ensureSignedInForPersistentAction(String message) {
    if (session != null) {
      return true;
    }
    _promptLogin(message);
    return false;
  }

  bool _ensureTrackedTopicQuotaAvailable() {
    if (_trackedTopics.length < effectiveFollowLimit) {
      return true;
    }

    final message = _trackedTopicLimitReachedMessage();
    if (isGuest) {
      _promptLogin(message);
    } else {
      _setErrorMessage(message, notify: true);
    }
    return false;
  }

  String _trackedTopicLimitReachedMessage() {
    if (isGuest) {
      return '游客最多可关注 5 个专题，登录后可关注更多。';
    }

    final limit = effectiveFollowLimit;
    if (limit >= 50 || _capabilities?.accountTier == 'pro') {
      return '已达到当前套餐关注上限。';
    }

    return '当前最多可关注 $limit 个专题，升级后可关注更多。';
  }

  void _promptLogin(String message) {
    _setErrorMessage(message);
    _loginPromptReason = message;
    _loginPromptToken += 1;
    notifyListeners();
  }

  void clearLoginPrompt() {
    _loginPromptReason = null;
  }

  void _handleFollowMutationError(Object error) {
    final raw = error.toString();
    if (raw.contains('UPGRADE_REQUIRED_FOR_MORE_FOLLOWS')) {
      _setErrorMessage('当前最多可关注 10 个专题，升级后可关注更多。', notify: true);
      return;
    }
    if (raw.contains('FOLLOW_LIMIT_REACHED')) {
      _setErrorMessage('已达到当前套餐关注上限。', notify: true);
      return;
    }
    if (raw.contains('AUTH_REQUIRED')) {
      _promptLogin('登录后即可关注专题，并在不同设备间同步。');
      return;
    }
    if (raw.contains('TOPIC_ALREADY_FOLLOWED')) {
      _setErrorMessage('该专题已在你的关注列表中。', notify: true);
      return;
    }
    if (raw.contains('TOPIC_NOT_FOLLOWED')) {
      _setErrorMessage('该专题当前未关注。', notify: true);
      return;
    }
    _setErrorMessage('关注状态更新失败：$error', notify: true);
  }

  Future<bool> _recoverFollowMutationConflict(Object error, Topic topic) async {
    final raw = error.toString();
    if (!raw.contains('TOPIC_ALREADY_FOLLOWED')) {
      return false;
    }

    try {
      await _refreshFollowedTopicsFromServer();
      await _loadRecommendations();
    } catch (_) {
      if (_trackedTopics.every((item) => item.id != topic.id)) {
        _trackedTopics.add(topic);
      }
    }

    _setSelectedTopicId(topic.id);
    await _persistTimelinePreferences();
    notifyListeners();
    _setErrorMessage('该专题已在你的关注列表中，已同步关注状态。', notify: true);
    return true;
  }

  Future<void> _refreshCapabilities() async {
    try {
      final nextCapabilities =
          await _followedTopicRemoteService.fetchCapabilities(
        userId: session?.userId,
      );
      _applyCapabilities(nextCapabilities);
    } catch (_) {
      if (_capabilities != null) {
        return;
      }
      _capabilities = UserCapabilitiesDto(
        authenticated: session != null,
        accountTier: session == null ? 'guest' : 'free',
        followLimit: session == null ? guestFollowLimit : 10,
        followCount: session == null ? null : _trackedTopics.length,
        remainingFollowQuota:
            session == null ? null : (10 - _trackedTopics.length).clamp(0, 10),
      );
    }
  }

  void _applyCapabilities(UserCapabilitiesDto? capabilities) {
    if (capabilities == null) {
      return;
    }
    _capabilities = capabilities;
  }

  Future<void> _refreshFollowedTopicsFromServer() async {
    final currentSession = session;
    if (currentSession == null) {
      return;
    }

    final followedTopicsDto =
        await _followedTopicRemoteService.fetchFollowedTopics(
      userId: currentSession.userId,
    );
    _followedTopicItems
      ..clear()
      ..addAll(followedTopicsDto.items);
    _captureInitialRecentUpdateReminderBaselineIfNeeded();

    final existingTopics = _topicCatalogService.mergeTopics(
      _trackedTopics,
      _recommendedTopics,
      _customTopics,
      _sharedTopics,
      _guestTrackedTopics,
    );
    final remoteTrackedTopics = _followedTopicMapper.toTopics(
      followedTopicsDto.items,
      existingTopics: existingTopics,
    );
    final localOnlyTrackedTopics =
        _trackedTopics.where((topic) => !_isServerManagedTopic(topic)).toList();

    _trackedTopics
      ..clear()
      ..addAll(remoteTrackedTopics)
      ..addAll(
        localOnlyTrackedTopics.where(
          (topic) => remoteTrackedTopics
              .every((remoteTopic) => remoteTopic.id != topic.id),
        ),
      );

    final latestEntriesByTopicId =
        _followedTopicMapper.toLatestEntriesByTopicId(
      followedTopicsDto.items,
      topics: _trackedTopics,
    );
    _trackedTopicLatestEntriesById
      ..clear()
      ..addAll(latestEntriesByTopicId);

    final remotePinnedTopicIds =
        _followedTopicMapper.pinnedTopicIds(followedTopicsDto.items);
    final localOnlyPinnedTopicIds =
        pinnedTopicIds.where((topicId) => !_isServerManagedTopicId(topicId));
    pinnedTopicIds = <String>[
      ...remotePinnedTopicIds,
      ...localOnlyPinnedTopicIds.where(
        (topicId) =>
            !remotePinnedTopicIds.contains(topicId) &&
            _trackedTopics.any((topic) => topic.id == topicId),
      ),
    ];

    await _persistFollowedTopicCacheMirror();
  }

  Future<void> _disablePushDeviceForCurrentSession() async {
    if (session == null) {
      return;
    }

    try {
      final deviceId = await _pushDeviceService.ensureDeviceId();
      await _pushDeviceRemoteService.disableDevice(
        PushDeviceDisableRequestDto(deviceId: deviceId),
      );
      _logPushDebug(
          'Push device disabled: deviceId=${_maskDebugValue(deviceId)}');
    } catch (error) {
      _logPushDebug('Push device disable failed: $error');
    }
  }

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

  Future<List<String>?> _mergeGuestFollowsAfterLogin() async {
    final currentSession = session;
    if (currentSession == null) {
      return null;
    }
    final guestTopicIds = _localStorage.readGuestTrackedTopicIds();
    if (guestTopicIds.isEmpty) {
      return const <String>[];
    }

    try {
      final mergeResult = await _followedTopicRemoteService.mergeGuestFollows(
        userId: currentSession.userId,
        guestTopicIds: guestTopicIds,
      );
      _applyCapabilities(mergeResult.toCapabilities());
      final followLimitSkippedTopicIds = _orderedTopicIds(
        sourceTopicIds: guestTopicIds,
        topicIdsToKeep: mergeResult.followLimitSkippedTopicIds.toSet(),
      );
      await _replacePendingGuestTrackedTopicIds(followLimitSkippedTopicIds);
      if (followLimitSkippedTopicIds.isNotEmpty) {
        _setErrorMessage(
          '账号关注已满，部分游客关注暂未同步。取消一些关注后可继续同步。',
        );
      } else if (mergeResult.skippedTopicIds.isNotEmpty) {
        _setErrorMessage(
          '已合并 ${mergeResult.mergedTopicIds.length} 个专题，另有 ${mergeResult.skippedTopicIds.length} 个未加入。',
        );
      }
      return <String>[
        ...mergeResult.mergedTopicIds,
        ...mergeResult.alreadyFollowedTopicIds,
        ...followLimitSkippedTopicIds,
      ];
    } catch (error) {
      _setErrorMessage('游客关注同步失败：$error');
      return null;
    }
  }

  Future<void> _mergeGuestFavoriteBucketsAfterLogin() async {
    final currentSession = session;
    if (currentSession == null) {
      return;
    }
    final guestFavorites = _localStorage.readFavoriteTimelineNodes();
    if (guestFavorites.isEmpty) {
      return;
    }

    try {
      await _favoriteTimelineBucketRemoteService.mergeGuestBuckets(
        FavoriteTimelineBucketMergeRequestDto(
          items: guestFavorites.map(_favoriteRequestFromNode).toList(),
        ),
      );
      await _localStorage.saveFavoriteTimelineNodes(
        const <FavoriteTimelineNode>[],
      );
      _favoriteTimelineNodes.clear();
    } catch (error) {
      _setErrorMessage('收藏同步失败：$error');
    }
  }

  Future<void> _refreshFavoriteTimelineBucketsFromServer() async {
    if (session == null) {
      return;
    }
    try {
      final response = await _favoriteTimelineBucketRemoteService.fetchBuckets(
        limit: 100,
      );
      _favoriteTimelineNodes
        ..clear()
        ..addAll(response.items.map(_favoriteNodeFromDto));
    } catch (error) {
      _setErrorMessage('加载收藏节点失败：$error');
    }
  }

  Future<void> _refreshUserInterestCategoriesFromServer() async {
    if (session == null) {
      return;
    }
    try {
      final remoteCategoryIds =
          await _profileRemoteService.fetchInterestCategoryIds();
      _userInterestCategoryIds
        ..clear()
        ..addAll(_normalizeInterestCategoryIds(remoteCategoryIds));
      await _localStorage.saveInterestCategoryIds(_userInterestCategoryIds);
    } catch (_) {
      // 兴趣偏好不应阻断首页、关注列表或时间轴加载。
    }
  }

  Future<void> _claimGuestTopicsAfterLogin({
    required List<String> activeGuestFollowTopicIds,
  }) async {
    final currentSession = session;
    if (currentSession == null) {
      return;
    }

    final guestCreatedTopicIds = _localStorage.readGuestCreatedTopicIds();
    if (guestCreatedTopicIds.isEmpty) {
      return;
    }
    final activeGuestFollowTopicIdSet = activeGuestFollowTopicIds.toSet();
    final claimTopicIds = guestCreatedTopicIds
        .where(activeGuestFollowTopicIdSet.contains)
        .toList(growable: false);
    if (claimTopicIds.isEmpty) {
      await _localStorage.clearGuestCreatedTopicIds();
      return;
    }

    try {
      final claimResult = await _followedTopicRemoteService.claimGuestTopics(
        userId: currentSession.userId,
        topicIds: claimTopicIds,
      );
      _applyCapabilities(claimResult.toCapabilities());
      final followLimitSkippedTopicIds = _orderedTopicIds(
        sourceTopicIds: claimTopicIds,
        topicIdsToKeep: claimResult.followLimitSkippedTopicIds.toSet(),
      );
      await _replacePendingGuestCreatedTopicIds(followLimitSkippedTopicIds);

      if (followLimitSkippedTopicIds.isNotEmpty) {
        _setErrorMessage(
          '账号关注已满，部分游客关注暂未同步。取消一些关注后可继续同步。',
        );
      } else if (claimResult.skippedTopicIds.isNotEmpty) {
        _setErrorMessage(
          '已认领 ${claimResult.claimedTopicIds.length} 个专题，另有 ${claimResult.skippedTopicIds.length} 个未认领。',
        );
      }
    } catch (error) {
      _setErrorMessage('游客专题认领失败：$error');
    }
  }

  Future<void> _retryPendingGuestSyncAfterQuotaChange() async {
    if (session == null || _localStorage.readGuestTrackedTopicIds().isEmpty) {
      return;
    }

    final activeGuestFollowTopicIds = await _mergeGuestFollowsAfterLogin();
    if (activeGuestFollowTopicIds == null) {
      return;
    }
    await _claimGuestTopicsAfterLogin(
      activeGuestFollowTopicIds: activeGuestFollowTopicIds,
    );
    await loadInitialData(force: true);
    _setPendingGuestSyncQuotaMessageIfNeeded();
  }

  void _setPendingGuestSyncQuotaMessageIfNeeded() {
    if (session == null || _localStorage.readGuestTrackedTopicIds().isEmpty) {
      return;
    }
    _setErrorMessage(
      '账号关注已满，部分游客关注暂未同步。取消一些关注后可继续同步。',
    );
  }

  Future<void> _replacePendingGuestTrackedTopicIds(
    List<String> topicIds,
  ) async {
    if (topicIds.isEmpty) {
      await _localStorage.clearGuestTrackedTopicIds();
      _hasStoredGuestTrackedTopicIds = false;
      _restoredGuestTrackedTopicIds = const <String>[];
      return;
    }

    await _localStorage.saveGuestTrackedTopicIds(topicIds);
    _hasStoredGuestTrackedTopicIds = true;
    _restoredGuestTrackedTopicIds = List<String>.from(topicIds);
  }

  Future<void> _replacePendingGuestCreatedTopicIds(
    List<String> topicIds,
  ) async {
    if (topicIds.isEmpty) {
      await _localStorage.clearGuestCreatedTopicIds();
      return;
    }

    await _localStorage.saveGuestCreatedTopicIds(topicIds);
  }

  List<String> _orderedTopicIds({
    required List<String> sourceTopicIds,
    required Set<String> topicIdsToKeep,
  }) {
    return sourceTopicIds
        .where(topicIdsToKeep.contains)
        .toSet()
        .toList(growable: false);
  }

  bool _isServerManagedTopicId(String topicId) {
    final topic = _topicCatalogService.findTopicById(topicId, allTopics);
    if (topic == null) {
      return !topicId.startsWith('custom-');
    }
    return _isServerManagedTopic(topic);
  }

  Future<void> _resolveDeferredSharedRoute() async {
    final deferredRoute = _deferredSharedRoute;
    if (deferredRoute == null) {
      return;
    }

    final parsed = _shareService.parseIncomingRoute(deferredRoute);
    if (parsed == null) {
      _deferredSharedRoute = null;
      _setErrorMessage('分享链接无效或已损坏。', notify: true);
      return;
    }

    if (parsed.isShareToken) {
      _deferredSharedRoute = null;
      await _consumeResolvedShare(parsed.shareToken!);
      return;
    }

    if (parsed.isImportedPayload) {
      _deferredSharedRoute = null;
      await _consumeImportedSharedTopic(parsed);
      return;
    }

    final preview = _sharedTopicFlowService.resolveReferencePreview(
      parsed: parsed,
      allTopics: allTopics,
      isFollowing: isFollowing,
    );
    if (preview == null) {
      _deferredSharedRoute = null;
      _setErrorMessage('分享的时间线暂时不可用。', replace: false, notify: true);
      return;
    }

    _deferredSharedRoute = null;
    _presentPendingSharedTopic(preview);
  }

  Future<void> _consumeResolvedShare(String shareToken) async {
    try {
      final resolvedShare = await _shareRemoteService.resolveShare(shareToken);
      _syncTopicDetail(resolvedShare.topic);
      _presentPendingSharedTopic(
          _shareMapper.toSharedTopicPreview(resolvedShare));
    } catch (error) {
      _setErrorMessage('分享的时间线暂时不可用：$error', replace: false, notify: true);
    }
  }

  Future<void> _consumeImportedSharedTopic(ParsedTopicShare parsed) async {
    final resolution = _sharedTopicFlowService.resolveImportedShare(
      parsed: parsed,
      allTopics: allTopics,
      recommendedTopics: _recommendedTopics,
      customTopics: _customTopics,
      isFollowing: isFollowing,
    );
    if (resolution == null) {
      _setErrorMessage('分享的时间线内容无法解析。', replace: false, notify: true);
      return;
    }

    _entriesByTopic[resolution.topic.id] = resolution.sortedEntries;

    if (resolution.shouldStageAsShared) {
      _sharedTopics.removeWhere((topic) => topic.id == resolution.topic.id);
      _sharedTopics.add(resolution.topic);
      await _persistSharedTopics();
    }

    _presentPendingSharedTopic(resolution.preview);
  }

  void _presentPendingSharedTopic(SharedTopicPreview preview) {
    _pendingSharedTopic = preview;
    _pendingSharedTopicToken += 1;
    notifyListeners();
  }

  void _setErrorMessage(
    String message, {
    bool replace = true,
    bool notify = false,
  }) {
    if (!replace && errorMessage != null && errorMessage!.isNotEmpty) {
      return;
    }
    errorMessage = message;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _persistTimelinePreferences() async {
    await _localStorage.saveSortOrder(sortOrder);
    if (session == null) {
      await _localStorage.saveGuestTrackedTopicIds(
          _trackedTopics.map((topic) => topic.id).toList());
      _hasStoredGuestTrackedTopicIds = true;
    } else {
      await _localStorage.saveTrackedTopicIds(
          _trackedTopics.map((topic) => topic.id).toList());
      _hasStoredTrackedTopicIds = true;
      await _localStorage.savePinnedTopicIds(pinnedTopicIds);
    }
    await _localStorage.saveHistoryTopicIds(historyTopicIds);
    await _localStorage.saveSelectedTopicId(selectedTopicId);
  }

  Future<void> _persistGuestTimelinePreferences() async {
    await _persistTimelinePreferences();
    await _localStorage.saveGuestTrackedTopics(_guestTrackedTopics);
  }

  Future<void> _trackGuestCreatedTopicId(String topicId) async {
    final topicIds = <String>{
      ..._localStorage.readGuestCreatedTopicIds(),
      topicId,
    }.toList(growable: false);
    await _localStorage.saveGuestCreatedTopicIds(topicIds);
  }

  Future<void> _persistFollowedTopicCacheMirror() async {
    await _localStorage.saveFollowedTopicSnapshot(
      FollowedTopicListDto(
        items: List<FollowedTopicItemDto>.from(_followedTopicItems),
        generatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _persistCustomTimelines() async {
    await _localStorage.saveCustomTopics(_customTopics);
    await _localStorage.saveCustomEntries(
      <String, List<TimelineEntry>>{
        for (final topic in _customTopics)
          if (_entriesByTopic.containsKey(topic.id))
            topic.id: _entriesByTopic[topic.id]!,
      },
    );
  }

  Future<void> _persistSharedTopics() async {
    await _localStorage.saveSharedTopics(_sharedTopics);
    await _localStorage.saveSharedEntries(
      <String, List<TimelineEntry>>{
        for (final topic in _sharedTopics)
          if (_entriesByTopic.containsKey(topic.id))
            topic.id: _entriesByTopic[topic.id]!,
      },
    );
  }

  Future<void> _persistFavoriteTimelineNodes() async {
    if (session != null) {
      return;
    }
    await _localStorage.saveFavoriteTimelineNodes(_favoriteTimelineNodes);
  }

  void _startResendCountdown(int seconds) {
    _stopResendCountdown();
    resendCountdown = seconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCountdown <= 1) {
        _stopResendCountdown();
        notifyListeners();
        return;
      }
      resendCountdown -= 1;
      notifyListeners();
    });
  }

  void _stopResendCountdown() {
    _resendTimer?.cancel();
    _resendTimer = null;
    resendCountdown = 0;
  }
}

List<String> _normalizeInterestCategoryIds(List<String> categoryIds) {
  final seen = <String>{};
  return <String>[
    for (final id in categoryIds)
      if (id.trim().isNotEmpty && seen.add(id.trim())) id.trim(),
  ];
}

String _formatTopicNameAsKeywordHint(Topic topic) {
  final coreKeywords = topic.definition?.coreKeywords
      .map((keyword) => _normalizeKeywordHintToken(keyword))
      .where((keyword) => keyword.isNotEmpty)
      .take(3)
      .toList();
  if (coreKeywords != null && coreKeywords.isNotEmpty) {
    return coreKeywords.join(' ');
  }

  final rawName = topic.name.trim();
  final splitTokens = rawName
      .split(RegExp(r'[\s，,、/|]+'))
      .map((token) => _normalizeKeywordHintToken(token))
      .where((token) => token.isNotEmpty)
      .toList();
  if (splitTokens.length > 1) {
    return splitTokens.take(4).join(' ');
  }

  final compactName = _normalizeKeywordHintToken(rawName);
  final segmentedTokens = _splitCompactKeywordHint(compactName);
  if (segmentedTokens.isEmpty) {
    return rawName;
  }
  return segmentedTokens.join(' ');
}

String _normalizeKeywordHintToken(String token) {
  var normalized = token.trim();
  if (normalized.isEmpty) {
    return '';
  }

  const trailingFillers = <String>[
    '最新进展',
    '总体进展',
    '最新动态',
    '时间线',
    '情况',
    '动态',
    '进展',
  ];

  var changed = true;
  while (changed && normalized.isNotEmpty) {
    changed = false;
    for (final filler in trailingFillers) {
      if (normalized == filler) {
        return '';
      }
      if (normalized.endsWith(filler) && normalized.length > filler.length) {
        normalized =
            normalized.substring(0, normalized.length - filler.length).trim();
        changed = true;
        break;
      }
    }
  }

  return normalized;
}

List<String> _splitCompactKeywordHint(String compactName) {
  if (compactName.isEmpty) {
    return const <String>[];
  }

  const suffixTerms = <String>[
    '商业化落地',
    '出海授权',
    '交易平台',
    '登月计划',
    '供应链',
    '价格战',
    '融资潮',
    '航运',
    '新政',
    '试点',
  ];

  for (final suffix in suffixTerms) {
    if (compactName.endsWith(suffix) && compactName.length > suffix.length) {
      final prefix =
          compactName.substring(0, compactName.length - suffix.length);
      return <String>[prefix, suffix];
    }
  }

  return <String>[compactName];
}
