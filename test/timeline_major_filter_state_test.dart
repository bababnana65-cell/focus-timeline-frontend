import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  test('selecting a different topic resets the major-node filter', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = AppLocalStorage();
    await storage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    await controller.selectTopic(SampleData.aiTopic);
    controller.toggleMajorNodesOnly();

    expect(controller.showOnlyMajorNodes, isTrue);

    await controller.selectTopic(SampleData.evPriceWarTopic);

    expect(controller.showOnlyMajorNodes, isFalse);
  });

  test('major-node and favorite-node filters are mutually exclusive', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = AppLocalStorage();
    await storage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    await controller.selectTopic(SampleData.aiTopic);

    controller.toggleMajorNodesOnly();
    expect(controller.showOnlyMajorNodes, isTrue);
    expect(controller.showOnlyFavoriteNodes, isFalse);

    controller.toggleFavoriteNodesOnly();
    expect(controller.showOnlyMajorNodes, isFalse);
    expect(controller.showOnlyFavoriteNodes, isTrue);

    controller.toggleMajorNodesOnly();
    expect(controller.showOnlyMajorNodes, isTrue);
    expect(controller.showOnlyFavoriteNodes, isFalse);
  });
}
