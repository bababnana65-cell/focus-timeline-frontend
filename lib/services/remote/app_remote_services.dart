import 'package:flutter/foundation.dart';

import '../mock_timeline_repository.dart';
import 'auth_remote_service.dart';
import 'favorite_timeline_bucket_remote_service.dart';
import 'followed_topic_remote_service.dart';
import 'http_api_client.dart';
import 'http_auth_remote_service.dart';
import 'http_favorite_timeline_bucket_remote_service.dart';
import 'http_followed_topic_remote_service.dart';
import 'http_profile_remote_service.dart';
import 'http_push_device_remote_service.dart';
import 'http_recommendation_remote_service.dart';
import 'http_share_remote_service.dart';
import 'http_timeline_creation_service.dart';
import 'http_topic_remote_service.dart';
import 'profile_remote_service.dart';
import 'push_device_remote_service.dart';
import 'recommendation_remote_service.dart';
import 'runtime_backend_config.dart';
import 'share_remote_service.dart';
import '../timeline_creation_service.dart';
import 'topic_remote_service.dart';

class AppRemoteServices {
  AppRemoteServices({
    required this.usesHttpBackend,
    required this.auth,
    required this.followedTopics,
    required this.topics,
    required this.recommendations,
    required this.shares,
    required this.pushDevices,
    required this.favoriteTimelineBuckets,
    required this.profile,
    required this.creation,
    this.onDispose,
  });

  final bool usesHttpBackend;
  final AuthRemoteService auth;
  final FollowedTopicRemoteService followedTopics;
  final TopicRemoteService topics;
  final RecommendationRemoteService recommendations;
  final ShareRemoteService shares;
  final PushDeviceRemoteService pushDevices;
  final FavoriteTimelineBucketRemoteService favoriteTimelineBuckets;
  final ProfileRemoteService profile;
  final TimelineCreationService creation;
  final void Function()? onDispose;

  void dispose() {
    onDispose?.call();
  }
}

class AppRemoteServicesFactory {
  const AppRemoteServicesFactory._();

  static AppRemoteServices create({
    required TimelineRepository repository,
    required String? Function() sessionTokenProvider,
    required String? Function() guestKeyProvider,
    RuntimeBackendConfig config = RuntimeBackendConfig.fromEnvironment,
  }) {
    if (config.isConfigured) {
      if (kDebugMode) {
        debugPrint('[timeliness] Using HTTP backend: ${config.baseUrl}');
      }
      final apiClient = HttpApiClient(
        baseUrl: config.baseUrl,
        sessionTokenProvider: sessionTokenProvider,
        guestKeyProvider: guestKeyProvider,
      );
      return AppRemoteServices(
        usesHttpBackend: true,
        auth: HttpAuthRemoteService(apiClient),
        followedTopics: HttpFollowedTopicRemoteService(apiClient),
        topics: HttpTopicRemoteService(apiClient),
        recommendations: HttpRecommendationRemoteService(apiClient),
        shares: HttpShareRemoteService(apiClient),
        pushDevices: HttpPushDeviceRemoteService(apiClient),
        favoriteTimelineBuckets:
            HttpFavoriteTimelineBucketRemoteService(apiClient),
        profile: HttpProfileRemoteService(apiClient),
        creation: HttpTimelineCreationService(apiClient),
        onDispose: apiClient.close,
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[timeliness] Using mock backend. '
        'Set TIMELINESS_USE_HTTP_BACKEND=true and TIMELINESS_API_BASE_URL to hit the server.',
      );
    }
    return AppRemoteServices(
      usesHttpBackend: false,
      auth: MockAuthRemoteService(),
      followedTopics: MockFollowedTopicRemoteService(
        repository: repository,
      ),
      topics: MockTopicRemoteService(
        repository: repository,
      ),
      recommendations: MockRecommendationRemoteService(
        repository: repository,
      ),
      shares: MockShareRemoteService(
        repository: repository,
      ),
      pushDevices: MockPushDeviceRemoteService(),
      favoriteTimelineBuckets: MockFavoriteTimelineBucketRemoteService(),
      profile: MockProfileRemoteService(),
      creation: MockTimelineCreationService(),
    );
  }
}
