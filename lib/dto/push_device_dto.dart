class PushDeviceUpsertRequestDto {
  const PushDeviceUpsertRequestDto({
    required this.deviceId,
    required this.platform,
    required this.pushToken,
    required this.appVersion,
    required this.enabled,
  });

  final String deviceId;
  final String platform;
  final String pushToken;
  final String appVersion;
  final bool enabled;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'platform': platform,
      'pushToken': pushToken,
      'appVersion': appVersion,
      'enabled': enabled,
    };
  }
}

class PushDeviceDisableRequestDto {
  const PushDeviceDisableRequestDto({
    required this.deviceId,
  });

  final String deviceId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'deviceId': deviceId,
    };
  }
}

class PushDeviceStateDto {
  const PushDeviceStateDto({
    required this.deviceId,
    required this.platform,
    required this.enabled,
    required this.updatedAt,
  });

  final String deviceId;
  final String platform;
  final bool enabled;
  final DateTime updatedAt;

  factory PushDeviceStateDto.fromJson(Map<String, dynamic> json) {
    return PushDeviceStateDto(
      deviceId: json['deviceId'] as String,
      platform: json['platform'] as String? ?? 'windows',
      enabled: json['enabled'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class PushTestNotificationRequestDto {
  const PushTestNotificationRequestDto({
    required this.topicId,
    required this.title,
    required this.body,
  });

  final String topicId;
  final String title;
  final String body;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'topicId': topicId,
      'title': title,
      'body': body,
    };
  }
}

class PushTestNotificationDeviceDto {
  const PushTestNotificationDeviceDto({
    required this.deviceId,
    required this.platform,
    required this.enabled,
    required this.updatedAt,
  });

  final String deviceId;
  final String platform;
  final bool enabled;
  final DateTime updatedAt;

  factory PushTestNotificationDeviceDto.fromJson(Map<String, dynamic> json) {
    return PushTestNotificationDeviceDto(
      deviceId: json['deviceId'] as String,
      platform: json['platform'] as String? ?? 'windows',
      enabled: json['enabled'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class PushTestNotificationResultDto {
  const PushTestNotificationResultDto({
    required this.type,
    required this.topicId,
    required this.title,
    required this.body,
    required this.sentCount,
    required this.devices,
    required this.simulated,
  });

  final String type;
  final String topicId;
  final String title;
  final String body;
  final int sentCount;
  final List<PushTestNotificationDeviceDto> devices;
  final bool simulated;

  factory PushTestNotificationResultDto.fromJson(Map<String, dynamic> json) {
    final rawDevices = json['devices'];
    final devices = rawDevices is List
        ? rawDevices
            .whereType<Map>()
            .map(
              (item) => PushTestNotificationDeviceDto.fromJson(
                item.cast<String, dynamic>(),
              ),
            )
            .toList(growable: false)
        : const <PushTestNotificationDeviceDto>[];
    return PushTestNotificationResultDto(
      type: json['type'] as String? ?? 'topic_update',
      topicId: json['topicId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      sentCount: json['sentCount'] as int? ?? 0,
      devices: devices,
      simulated: json['simulated'] as bool? ?? false,
    );
  }
}
