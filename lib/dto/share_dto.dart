import 'topic_timeline_dto.dart';

class ShareCreateResultDto {
  const ShareCreateResultDto({
    required this.shareToken,
    required this.shareUrl,
    required this.shareType,
    required this.allowFollow,
    this.expiresAt,
  });

  final String shareToken;
  final String shareUrl;
  final String shareType;
  final bool allowFollow;
  final DateTime? expiresAt;

  factory ShareCreateResultDto.fromJson(Map<String, dynamic> json) {
    return ShareCreateResultDto(
      shareToken: json['shareToken'] as String,
      shareUrl: json['shareUrl'] as String,
      shareType: json['shareType'] as String,
      allowFollow: json['allowFollow'] as bool,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class SharePreviewDto {
  const SharePreviewDto({
    this.latestEventAt,
    this.majorCount,
  });

  final DateTime? latestEventAt;
  final int? majorCount;

  factory SharePreviewDto.fromJson(Map<String, dynamic> json) {
    return SharePreviewDto(
      latestEventAt: json['latestEventAt'] == null
          ? null
          : DateTime.parse(json['latestEventAt'] as String),
      majorCount: json['majorCount'] as int?,
    );
  }
}

class ShareResolveDto {
  const ShareResolveDto({
    required this.shareToken,
    required this.shareType,
    required this.allowFollow,
    required this.alreadyFollowed,
    required this.topic,
    this.expiresAt,
    this.preview,
  });

  final String shareToken;
  final String shareType;
  final bool allowFollow;
  final DateTime? expiresAt;
  final bool alreadyFollowed;
  final TopicDetailDto topic;
  final SharePreviewDto? preview;

  factory ShareResolveDto.fromJson(Map<String, dynamic> json) {
    return ShareResolveDto(
      shareToken: json['shareToken'] as String,
      shareType: json['shareType'] as String,
      allowFollow: json['allowFollow'] as bool,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      alreadyFollowed: json['alreadyFollowed'] as bool,
      topic: TopicDetailDto.fromJson(json['topic'] as Map<String, dynamic>),
      preview: json['preview'] == null
          ? null
          : SharePreviewDto.fromJson(json['preview'] as Map<String, dynamic>),
    );
  }
}
