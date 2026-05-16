import '../dto/followed_topic_dto.dart';
import '../mappers/followed_topic_mapper.dart';
import '../models/auth_models.dart';
import '../models/timeline_models.dart';
import 'app_local_storage.dart';
import 'mock_timeline_repository.dart';
import 'remote/followed_topic_remote_service.dart';
import 'topic_catalog_service.dart';

class TimelineBootstrapService {
  const TimelineBootstrapService({
    TopicCatalogService? topicCatalogService,
  }) : _topicCatalogService =
            topicCatalogService ?? const TopicCatalogService();

  final TopicCatalogService _topicCatalogService;

  Future<TimelineRestoredState> restoreLocalState(
      AppLocalStorage localStorage) async {
    await localStorage.init();
    return TimelineRestoredState(
      sortOrder: localStorage.readSortOrder(),
      session: localStorage.readSession(),
      hasStoredTrackedTopicIds: localStorage.hasTrackedTopicIds(),
      restoredTrackedTopicIds: localStorage.readTrackedTopicIds(),
      hasStoredGuestTrackedTopicIds: localStorage.hasGuestTrackedTopicIds(),
      restoredGuestTrackedTopicIds: localStorage.readGuestTrackedTopicIds(),
      restoredPinnedTopicIds: localStorage.readPinnedTopicIds(),
      restoredHistoryTopicIds: localStorage.readHistoryTopicIds(),
      restoredSelectedTopicId: localStorage.readSelectedTopicId(),
      guestTrackedTopics: localStorage.readGuestTrackedTopics(),
      customTopics: localStorage.readCustomTopics(),
      sharedTopics: localStorage.readSharedTopics(),
      favoriteTimelineNodes: localStorage.readFavoriteTimelineNodes(),
      restoredEntriesByTopic: <String, List<TimelineEntry>>{
        ...localStorage.readCustomEntries(),
        ...localStorage.readSharedEntries(),
      },
    );
  }

  Future<TimelineInitialLoadState> loadInitialTopicState({
    required TimelineRepository repository,
    required FollowedTopicRemoteService followedTopicRemoteService,
    required FollowedTopicMapper followedTopicMapper,
    required AppLocalStorage localStorage,
    required String userId,
    required List<Topic> customTopics,
    required List<Topic> sharedTopics,
    required Map<String, List<TimelineEntry>> entriesByTopic,
    required bool hasStoredTrackedTopicIds,
    required List<String> restoredTrackedTopicIds,
    required List<String> restoredPinnedTopicIds,
    required List<String> restoredHistoryTopicIds,
    required String? restoredSelectedTopicId,
    required String? currentSelectedTopicId,
    bool preferServerRuntimeTopics = false,
  }) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      repository.fetchTrackedTopics(),
      repository.fetchRecommendedTopics(),
    ]);
    final repoTracked = results[0] as List<Topic>;
    final repositoryRecommendedTopics = results[1] as List<Topic>;
    final recommendedTopics = preferServerRuntimeTopics
        ? const <Topic>[]
        : repositoryRecommendedTopics;

    final existingTopics = preferServerRuntimeTopics
        ? _topicCatalogService.mergeTopics(
            const <Topic>[],
            const <Topic>[],
            customTopics,
            sharedTopics,
            const <Topic>[],
          )
        : _topicCatalogService.mergeTopics(
            repoTracked,
            recommendedTopics,
            customTopics,
            sharedTopics,
            const <Topic>[],
          );
    final cachedFollowedSnapshot = localStorage.readFollowedTopicSnapshot();
    FollowedTopicListDto? followedTopicsDto;

    try {
      followedTopicsDto = await followedTopicRemoteService.fetchFollowedTopics(
        userId: userId,
      );
      await localStorage.saveFollowedTopicSnapshot(followedTopicsDto);
    } catch (_) {
      followedTopicsDto = cachedFollowedSnapshot?.payload;
    }

    final usingLegacyFallback = followedTopicsDto == null;
    final remoteTrackedTopics = usingLegacyFallback
        ? repoTracked
        : followedTopicMapper.toTopics(
            followedTopicsDto.items,
            existingTopics: existingTopics,
          );
    final remotePinnedTopicIds = usingLegacyFallback
        ? const <String>[]
        : followedTopicMapper.pinnedTopicIds(followedTopicsDto.items);
    final latestEntriesByTopicId = usingLegacyFallback
        ? const <String, TimelineEntry>{}
        : followedTopicMapper.toLatestEntriesByTopicId(
            followedTopicsDto.items,
            topics: remoteTrackedTopics,
          );
    final latestActivityAtByTopicId = usingLegacyFallback
        ? const <String, DateTime?>{}
        : <String, DateTime?>{
            for (final item in followedTopicsDto.items)
              item.topicId: item.latestRelevantEventAt,
          };

    final allFetchedTopics = _topicCatalogService.mergeTopics(
      remoteTrackedTopics,
      recommendedTopics,
      customTopics,
      sharedTopics,
      const <Topic>[],
    );

    final locallyPersistedTopics = _topicCatalogService.mergeTopics(
      const <Topic>[],
      const <Topic>[],
      customTopics,
      sharedTopics,
      const <Topic>[],
    );

    final trackedTopics = <Topic>[
      ...remoteTrackedTopics,
    ];
    if (hasStoredTrackedTopicIds) {
      trackedTopics.addAll(
        (preferServerRuntimeTopics ? locallyPersistedTopics : allFetchedTopics)
            .where(
          (topic) =>
              restoredTrackedTopicIds.contains(topic.id) &&
              remoteTrackedTopics
                  .every((remoteTopic) => remoteTopic.id != topic.id),
        ),
      );
    } else {
      trackedTopics.addAll(
        customTopics.where(
          (topic) => remoteTrackedTopics
              .every((remoteTopic) => remoteTopic.id != topic.id),
        ),
      );
    }

    if (usingLegacyFallback &&
        !hasStoredTrackedTopicIds &&
        trackedTopics.isEmpty &&
        allFetchedTopics.isNotEmpty) {
      trackedTopics.add(
          repoTracked.isNotEmpty ? repoTracked.first : allFetchedTopics.first);
    }

    final orderedRemotePinnedTopicIds = <String>[
      ...restoredPinnedTopicIds
          .where((topicId) => remotePinnedTopicIds.contains(topicId)),
      ...remotePinnedTopicIds.where(
          (topicId) => restoredPinnedTopicIds.contains(topicId) == false),
    ];
    final pinnedTopicIds = <String>[
      ...orderedRemotePinnedTopicIds,
      ...restoredPinnedTopicIds.where(
        (topicId) =>
            remotePinnedTopicIds.contains(topicId) == false &&
            trackedTopics.any((topic) => topic.id == topicId),
      ),
    ]
        .where((topicId) => trackedTopics.any((topic) => topic.id == topicId))
        .toList();
    final historyTopicIds = restoredHistoryTopicIds
        .where(
            (topicId) => allFetchedTopics.any((topic) => topic.id == topicId))
        .toList();

    final serverSelectableTopics = _topicCatalogService.mergeTopics(
      remoteTrackedTopics,
      recommendedTopics,
      const <Topic>[],
      const <Topic>[],
      const <Topic>[],
    );
    final selectedValidationPool =
        preferServerRuntimeTopics ? serverSelectableTopics : allFetchedTopics;
    final selectedStillValid = currentSelectedTopicId != null &&
        selectedValidationPool
            .any((topic) => topic.id == currentSelectedTopicId);

    String? selectedTopicId = currentSelectedTopicId;
    if (restoredSelectedTopicId != null &&
        selectedValidationPool
            .any((topic) => topic.id == restoredSelectedTopicId)) {
      selectedTopicId = restoredSelectedTopicId;
    } else if (!selectedStillValid) {
      final orderedTrackedTopics = _topicCatalogService.orderedTrackedTopics(
        trackedTopics: trackedTopics,
        pinnedTopicIds: pinnedTopicIds,
        entriesByTopic: entriesByTopic,
        latestEntriesByTopicId: latestEntriesByTopicId,
        latestActivityAtByTopicId: latestActivityAtByTopicId,
      );
      selectedTopicId = orderedTrackedTopics.isNotEmpty
          ? orderedTrackedTopics.first.id
          : (allFetchedTopics.isNotEmpty ? allFetchedTopics.first.id : null);
    }

    return TimelineInitialLoadState(
      trackedTopics: trackedTopics,
      recommendedTopics: recommendedTopics,
      pinnedTopicIds: pinnedTopicIds,
      historyTopicIds: historyTopicIds,
      selectedTopicId: selectedTopicId,
      followedTopicItems:
          followedTopicsDto?.items ?? const <FollowedTopicItemDto>[],
      followedTopicLatestEntriesByTopicId: latestEntriesByTopicId,
    );
  }
}

class TimelineRestoredState {
  const TimelineRestoredState({
    required this.sortOrder,
    required this.session,
    required this.hasStoredTrackedTopicIds,
    required this.restoredTrackedTopicIds,
    required this.hasStoredGuestTrackedTopicIds,
    required this.restoredGuestTrackedTopicIds,
    required this.restoredPinnedTopicIds,
    required this.restoredHistoryTopicIds,
    required this.restoredSelectedTopicId,
    required this.guestTrackedTopics,
    required this.customTopics,
    required this.sharedTopics,
    required this.favoriteTimelineNodes,
    required this.restoredEntriesByTopic,
  });

  final TimelineSortOrder sortOrder;
  final AuthSession? session;
  final bool hasStoredTrackedTopicIds;
  final List<String> restoredTrackedTopicIds;
  final bool hasStoredGuestTrackedTopicIds;
  final List<String> restoredGuestTrackedTopicIds;
  final List<String> restoredPinnedTopicIds;
  final List<String> restoredHistoryTopicIds;
  final String? restoredSelectedTopicId;
  final List<Topic> guestTrackedTopics;
  final List<Topic> customTopics;
  final List<Topic> sharedTopics;
  final List<FavoriteTimelineNode> favoriteTimelineNodes;
  final Map<String, List<TimelineEntry>> restoredEntriesByTopic;
}

class TimelineInitialLoadState {
  const TimelineInitialLoadState({
    required this.trackedTopics,
    required this.recommendedTopics,
    required this.pinnedTopicIds,
    required this.historyTopicIds,
    required this.selectedTopicId,
    required this.followedTopicItems,
    required this.followedTopicLatestEntriesByTopicId,
  });

  final List<Topic> trackedTopics;
  final List<Topic> recommendedTopics;
  final List<String> pinnedTopicIds;
  final List<String> historyTopicIds;
  final String? selectedTopicId;
  final List<FollowedTopicItemDto> followedTopicItems;
  final Map<String, TimelineEntry> followedTopicLatestEntriesByTopicId;
}
