import 'package:event_timeline/dto/topic_timeline_dto.dart';
import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/remote/topic_remote_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  AuthSession buildSession() {
    return AuthSession(
      userId: 'user_13812345678',
      sessionToken: 'sess_001',
      issuedAt: DateTime(2026, 4, 18, 9, 0),
      expiresAt: DateTime(2026, 4, 25, 9, 0),
      identityType: 'phone',
      provider: 'sms',
      primaryPhone: '13812345678',
    );
  }

  test('loads selected timeline from topic remote DTO and maps stable link ids', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    expect(controller.timelineBuckets, isNotEmpty);
    final allEntries = controller.timelineBuckets.expand((bucket) => bucket.entries).toList();
    expect(allEntries, isNotEmpty);
    expect(allEntries.every((entry) => entry.id.startsWith('link-')), isTrue);
    expect(controller.selectedTopic?.name, isNotEmpty);
  });

  test('does not fall back to repository timeline for server managed topics when topic remote fetch fails', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      topicRemoteService: _FailingTopicRemoteService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    expect(controller.timelineBuckets, isEmpty);
    expect(controller.errorMessage, contains('加载当前时间线失败'));
  });

  test('mock topic remote service exposes half-flat timeline dto and search result', () async {
    final service = MockTopicRemoteService(
      repository: MockTimelineRepository(),
    );

    final response = await service.fetchTopicTimeline(SampleData.aiTopic.id);
    expect(response.topic.topicId, SampleData.aiTopic.id);
    expect(response.stats.entryCount, greaterThan(0));
    expect(response.filters.supportsMajorOnly, isTrue);
    expect(response.entries.first.topicEventLinkId, startsWith('link-'));
    expect(response.entries.first.bucketGranularity, isNotEmpty);

    final search = await service.searchTimeline(
      topicId: SampleData.aiTopic.id,
      query: '发布',
    );
    expect(search.topicId, SampleData.aiTopic.id);
    expect(search.items, isNotEmpty);
    expect(search.items.first.topicEventLinkId, startsWith('link-'));
  });

  test('timeline search uses remote DTO path and preserves topicEventLinkId mapping', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();
    await controller.selectTopic(
      controller.allTopics.firstWhere((topic) => topic.id == SampleData.aiTopic.id),
    );

    controller.setTimelineSearchQuery('发布');
    for (var attempt = 0; attempt < 20; attempt += 1) {
      if (controller.visibleTimelineBuckets.isNotEmpty) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    final searchEntries = controller.visibleTimelineBuckets.expand((bucket) => bucket.entries).toList();
    expect(searchEntries, isNotEmpty);
    expect(searchEntries.every((entry) => entry.id.startsWith('link-')), isTrue);
  });
}

class _FailingTopicRemoteService implements TopicRemoteService {
  @override
  Future<TopicCreateResultDto> createTopic(TopicCreateRequestDto request) async {
    throw Exception('remote unavailable');
  }

  @override
  Future<MyTopicListDto> fetchMyTopics() async {
    throw Exception('remote unavailable');
  }

  @override
  Future<TopicDetailDto> fetchTopicDetail(String topicId) async {
    throw Exception('remote unavailable');
  }

  @override
  Future<TopicTimelineResponseDto> fetchTopicTimeline(String topicId) async {
    throw Exception('remote unavailable');
  }

  @override
  Future<TopicInitializationRetryResultDto> retryTopicInitialization(String topicId) async {
    throw Exception('remote unavailable');
  }

  @override
  Future<TimelineSearchResultDto> searchTimeline({
    required String topicId,
    required String query,
  }) async {
    throw Exception('remote unavailable');
  }
}
