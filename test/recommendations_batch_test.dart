import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:event_timeline/dto/recommendation_dto.dart';
import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/remote/recommendation_remote_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';

void main() {
  TimelineController? controller;

  tearDown(() {
    controller?.dispose();
    controller = null;
  });

  test('projects recommendation modes into personalized, hot, explore, and history', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();

    expect(controller!.recommendationMode, RecommendationMode.personalized);
    expect(controller!.recommendationTopics, isNotEmpty);

    controller!.showHotRecommendations();
    final hotIds = controller!.recommendationTopics.map((topic) => topic.id).toList();

    controller!.showExploreRecommendations();
    final exploreIds = controller!.recommendationTopics.map((topic) => topic.id).toList();

    controller!.showHistoryRecommendations();
    final historyIds = controller!.recommendationTopics.map((topic) => topic.id).toList();

    expect(hotIds, isNotEmpty);
    expect(exploreIds, isNotEmpty);
    expect(historyIds, isNotEmpty);
    expect(exploreIds, isNot(equals(hotIds)));
  });

  test('history recommendation mode prioritizes remote history projection', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      recommendationRemoteService: _HistoryOnlyRecommendationRemoteService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();
    controller!.showHistoryRecommendations();

    expect(
      controller!.recommendationTopics.map((topic) => topic.id).take(2),
      orderedEquals(<String>[SampleData.chipTopic.id, SampleData.aiTopic.id]),
    );
  });

  test('guest follow request is staged locally before login', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();
    controller!.showHotRecommendations();

    final topic = controller!.recommendationTopics.first;
    final initialPromptToken = controller!.pendingLoginPromptToken;

    await controller!.toggleFollow(topic);

    expect(controller!.isFollowing(topic), isTrue);
    expect(controller!.pendingLoginPromptToken, initialPromptToken);
    expect(storage.readGuestTrackedTopicIds(), contains(topic.id));
  });

  test('refresh recommendations keeps existing data when remote refresh fails', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      recommendationRemoteService: _FailingAfterSeedRecommendationRemoteService(
        RecommendationResponseDto(
          sections: <RecommendationSectionDto>[
            const RecommendationSectionDto(
              sectionKey: 'personalized',
              sectionTitle: '你可能关心',
              items: <RecommendationItemDto>[],
            ),
            RecommendationSectionDto(
              sectionKey: 'hot',
              sectionTitle: '当前热门',
              items: <RecommendationItemDto>[
                RecommendationItemDto(
                  topicId: SampleData.aiTopic.id,
                  title: SampleData.aiTopic.name,
                  summary: SampleData.aiTopic.tagline,
                  isFollowed: false,
                  recommendationSource: 'hot',
                  reasonCode: 'GLOBAL_HEAT_UP',
                ),
              ],
            ),
            const RecommendationSectionDto(
              sectionKey: 'explore',
              sectionTitle: '值得看看',
              items: <RecommendationItemDto>[],
            ),
          ],
          history: const <HistoryTopicDto>[],
          generatedAt: DateTime(2026, 4, 21, 9, 0),
        ),
      ),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();
    controller!.showHotRecommendations();
    final originalIds = controller!.recommendationTopics.map((topic) => topic.id).toList();

    await controller!.refreshRecommendations();

    expect(
      controller!.recommendationTopics.map((topic) => topic.id).toList(),
      orderedEquals(originalIds),
    );
    expect(controller!.recommendationRefreshNotice, '刷新失败，已保留当前推荐');
    expect(controller!.recommendationRefreshNoticeIsError, isTrue);
  });
}

class _HistoryOnlyRecommendationRemoteService implements RecommendationRemoteService {
  @override
  Future<RecommendationResponseDto> fetchRecommendations() async {
    return RecommendationResponseDto(
      sections: const <RecommendationSectionDto>[
        RecommendationSectionDto(
          sectionKey: 'personalized',
          sectionTitle: '你可能关心',
          items: <RecommendationItemDto>[],
        ),
        RecommendationSectionDto(
          sectionKey: 'hot',
          sectionTitle: '当前热门',
          items: <RecommendationItemDto>[],
        ),
        RecommendationSectionDto(
          sectionKey: 'explore',
          sectionTitle: '值得看看',
          items: <RecommendationItemDto>[],
        ),
      ],
      history: <HistoryTopicDto>[
        HistoryTopicDto(
          topicId: SampleData.chipTopic.id,
          title: SampleData.chipTopic.name,
          viewedAt: DateTime(2026, 4, 18, 9, 0),
        ),
        HistoryTopicDto(
          topicId: SampleData.aiTopic.id,
          title: SampleData.aiTopic.name,
          viewedAt: DateTime(2026, 4, 18, 8, 0),
        ),
      ],
      generatedAt: DateTime(2026, 4, 18, 9, 5),
    );
  }
}

class _FailingAfterSeedRecommendationRemoteService implements RecommendationRemoteService {
  _FailingAfterSeedRecommendationRemoteService(this.seed);

  final RecommendationResponseDto seed;
  bool _seedServed = false;

  @override
  Future<RecommendationResponseDto> fetchRecommendations() async {
    if (!_seedServed) {
      _seedServed = true;
      return seed;
    }
    throw Exception('temporary failure');
  }
}
