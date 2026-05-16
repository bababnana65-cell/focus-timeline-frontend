import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/remote/app_remote_services.dart';
import 'package:event_timeline/services/remote/http_auth_remote_service.dart';
import 'package:event_timeline/services/remote/http_api_client.dart';
import 'package:event_timeline/services/remote/runtime_backend_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to mock remote services when http backend is not configured', () {
    final services = AppRemoteServicesFactory.create(
      repository: MockTimelineRepository(),
      sessionTokenProvider: () => null,
      guestKeyProvider: () => 'guest_test',
      config: const RuntimeBackendConfig(
        useHttpBackend: false,
        baseUrl: '',
      ),
    );

    expect(services.auth, isNot(isA<HttpAuthRemoteService>()));
    services.dispose();
  });

  test('switches to http remote services when runtime backend is configured', () {
    final services = AppRemoteServicesFactory.create(
      repository: MockTimelineRepository(),
      sessionTokenProvider: () => 'sess_001',
      guestKeyProvider: () => 'guest_test',
      config: const RuntimeBackendConfig(
        useHttpBackend: true,
        baseUrl: 'http://127.0.0.1:8000',
      ),
    );

    expect(services.auth, isA<HttpAuthRemoteService>());
    services.dispose();
  });

  test('http api exception uses FastAPI detail string when present', () {
    final exception = HttpApiException.fromPayload(
      statusCode: 404,
      payload: const <String, dynamic>{
        'detail': 'Not Found',
      },
    );

    expect(exception.message, 'Not Found');
    expect(exception.statusCode, 404);
  });
}
