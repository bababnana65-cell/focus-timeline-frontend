import '../../dto/push_device_dto.dart';

abstract class PushDeviceRemoteService {
  Future<PushDeviceStateDto> registerDevice(PushDeviceUpsertRequestDto request);

  Future<PushDeviceStateDto> disableDevice(PushDeviceDisableRequestDto request);

  Future<PushTestNotificationResultDto> sendTestNotification(
    PushTestNotificationRequestDto request,
  );
}

class MockPushDeviceRemoteService implements PushDeviceRemoteService {
  final Map<String, PushDeviceStateDto> _devicesById = <String, PushDeviceStateDto>{};

  @override
  Future<PushDeviceStateDto> registerDevice(PushDeviceUpsertRequestDto request) async {
    final result = PushDeviceStateDto(
      deviceId: request.deviceId,
      platform: request.platform,
      enabled: request.enabled,
      updatedAt: DateTime.now(),
    );
    _devicesById[request.deviceId] = result;
    return result;
  }

  @override
  Future<PushDeviceStateDto> disableDevice(PushDeviceDisableRequestDto request) async {
    final current = _devicesById[request.deviceId];
    final result = PushDeviceStateDto(
      deviceId: request.deviceId,
      platform: current?.platform ?? 'windows',
      enabled: false,
      updatedAt: DateTime.now(),
    );
    _devicesById[request.deviceId] = result;
    return result;
  }

  @override
  Future<PushTestNotificationResultDto> sendTestNotification(
    PushTestNotificationRequestDto request,
  ) async {
    final enabledDevices = _devicesById.values.where((device) => device.enabled).toList();
    return PushTestNotificationResultDto(
      type: 'topic_update',
      topicId: request.topicId,
      title: request.title,
      body: request.body,
      sentCount: enabledDevices.length,
      devices: enabledDevices
          .map(
            (device) => PushTestNotificationDeviceDto(
              deviceId: device.deviceId,
              platform: device.platform,
              enabled: device.enabled,
              updatedAt: device.updatedAt,
            ),
          )
          .toList(growable: false),
      simulated: true,
    );
  }
}
