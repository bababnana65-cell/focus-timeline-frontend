import '../../dto/push_device_dto.dart';
import 'http_api_client.dart';
import 'push_device_remote_service.dart';

class HttpPushDeviceRemoteService implements PushDeviceRemoteService {
  HttpPushDeviceRemoteService(this._client);

  final HttpApiClient _client;

  @override
  Future<PushDeviceStateDto> registerDevice(PushDeviceUpsertRequestDto request) async {
    final data = await _client.post(
      '/users/push-devices',
      body: request.toJson(),
    );
    return PushDeviceStateDto.fromJson(data);
  }

  @override
  Future<PushDeviceStateDto> disableDevice(PushDeviceDisableRequestDto request) async {
    final data = await _client.post(
      '/users/push-devices/disable',
      body: request.toJson(),
    );
    return PushDeviceStateDto.fromJson(data);
  }

  @override
  Future<PushTestNotificationResultDto> sendTestNotification(
    PushTestNotificationRequestDto request,
  ) async {
    final data = await _client.post(
      '/users/push-devices/test-notification',
      body: request.toJson(),
    );
    return PushTestNotificationResultDto.fromJson(data);
  }
}
