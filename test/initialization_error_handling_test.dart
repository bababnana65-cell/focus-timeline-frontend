import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TimelineController? controller;

  tearDown(() {
    controller?.dispose();
    controller = null;
  });

  test('shows a specific error when initial topic loading fails', () async {
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
      repository: _ConfigurableTimelineRepository(
        trackedTopicsError: Exception('topics api down'),
      ),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();

    expect(controller!.errorMessage, contains('加载关注事件列表失败'));
    expect(controller!.trackedTopics, isEmpty);
    expect(controller!.recommendedTopics, isEmpty);
    expect(controller!.isLoading, isFalse);
    expect(controller!.isBootstrapping, isFalse);
  });

  test('shows a specific error when the selected timeline fails to load', () async {
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
      repository: _ConfigurableTimelineRepository(
        trackedTopics: <Topic>[SampleData.aiTopic],
        recommendedTopics: <Topic>[SampleData.aiTopic, SampleData.chipTopic],
        timelineErrors: <String, Object>{
          SampleData.aiTopic.id: Exception('timeline api down'),
        },
      ),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();

    expect(controller!.trackedTopics.map((topic) => topic.id), contains(SampleData.aiTopic.id));
    expect(controller!.selectedTopicId, SampleData.aiTopic.id);
    expect(controller!.latestEntryForTopic(SampleData.aiTopic.id), isNull);
    expect(controller!.errorMessage, contains('加载当前时间线失败'));
  });

  test('shows a specific error for an invalid share link', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: AppLocalStorage(),
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    await controller!.handleIncomingRoute('timeliness://timeline/open');

    expect(controller!.errorMessage, '分享链接无效或已损坏。');
  });

  test('shows a specific error for an unavailable shared timeline reference', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: AppLocalStorage(),
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    await controller!.handleIncomingRoute('timeliness://timeline/open?topic=missing-topic');

    expect(controller!.errorMessage, '分享的时间线暂时不可用。');
  });
}

class _ConfigurableTimelineRepository implements TimelineRepository {
  _ConfigurableTimelineRepository({
    this.trackedTopics = const <Topic>[SampleData.aiTopic, SampleData.chipTopic],
    this.recommendedTopics = SampleData.topics,
    this.trackedTopicsError,
    Map<String, Object>? timelineErrors,
  }) : _timelineErrors = timelineErrors ?? const <String, Object>{};

  final List<Topic> trackedTopics;
  final List<Topic> recommendedTopics;
  final Object? trackedTopicsError;
  final Map<String, Object> _timelineErrors;

  @override
  Future<List<Topic>> fetchTrackedTopics() async {
    if (trackedTopicsError != null) {
      throw trackedTopicsError!;
    }
    return trackedTopics;
  }

  @override
  Future<List<Topic>> fetchRecommendedTopics() async {
    return recommendedTopics;
  }

  @override
  Future<List<TimelineEntry>> fetchTimeline(String topicId) async {
    final error = _timelineErrors[topicId];
    if (error != null) {
      throw error;
    }
    return (SampleData.entriesByTopic[topicId] ?? const <TimelineEntry>[])
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}
