import 'topic_context_contract_dto.dart';

class FollowedTopicItemDto {
  const FollowedTopicItemDto({
    required this.followId,
    required this.topicId,
    required this.title,
    required this.summary,
    required this.isPinned,
    required this.followedAt,
    required this.hasRecentUpdate,
    this.lastViewedAt,
    this.latestRelevantEventAt,
    this.latestRelevantEventSummary,
    this.unreadSignalCount,
    this.primaryCategory,
    this.categories = const <String>[],
    this.categoryConfidence,
    this.latestNode,
  });

  final String followId;
  final String topicId;
  final String title;
  final String summary;
  final bool isPinned;
  final DateTime followedAt;
  final DateTime? lastViewedAt;
  final DateTime? latestRelevantEventAt;
  final String? latestRelevantEventSummary;
  final bool hasRecentUpdate;
  final int? unreadSignalCount;
  final String? primaryCategory;
  final List<String> categories;
  final double? categoryConfidence;
  final LatestNodeDto? latestNode;

  DateTime? get effectiveLatestEventAt =>
      latestNode?.occurredAt ?? latestRelevantEventAt;

  String? get effectiveLatestEventSummary {
    final latestSummary = latestNode?.summary.trim();
    if (latestSummary != null && latestSummary.isNotEmpty) {
      return latestSummary;
    }
    final latestHeadline = latestNode?.headline.trim();
    if (latestHeadline != null && latestHeadline.isNotEmpty) {
      return latestHeadline;
    }
    return latestRelevantEventSummary;
  }

  FollowedTopicItemDto copyWith({
    String? followId,
    String? topicId,
    String? title,
    String? summary,
    bool? isPinned,
    DateTime? followedAt,
    DateTime? lastViewedAt,
    DateTime? latestRelevantEventAt,
    String? latestRelevantEventSummary,
    bool? hasRecentUpdate,
    int? unreadSignalCount,
    String? primaryCategory,
    List<String>? categories,
    double? categoryConfidence,
    LatestNodeDto? latestNode,
  }) {
    return FollowedTopicItemDto(
      followId: followId ?? this.followId,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      isPinned: isPinned ?? this.isPinned,
      followedAt: followedAt ?? this.followedAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      latestRelevantEventAt:
          latestRelevantEventAt ?? this.latestRelevantEventAt,
      latestRelevantEventSummary:
          latestRelevantEventSummary ?? this.latestRelevantEventSummary,
      hasRecentUpdate: hasRecentUpdate ?? this.hasRecentUpdate,
      unreadSignalCount: unreadSignalCount ?? this.unreadSignalCount,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      categories: categories ?? this.categories,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      latestNode: latestNode ?? this.latestNode,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'followId': followId,
      'topicId': topicId,
      'title': title,
      'summary': summary,
      'isPinned': isPinned,
      'followedAt': followedAt.toIso8601String(),
      if (lastViewedAt != null) 'lastViewedAt': lastViewedAt!.toIso8601String(),
      if (latestRelevantEventAt != null)
        'latestRelevantEventAt': latestRelevantEventAt!.toIso8601String(),
      if (latestRelevantEventSummary != null)
        'latestRelevantEventSummary': latestRelevantEventSummary,
      'hasRecentUpdate': hasRecentUpdate,
      if (unreadSignalCount != null) 'unreadSignalCount': unreadSignalCount,
      if (primaryCategory != null) 'primaryCategory': primaryCategory,
      if (categories.isNotEmpty) 'categories': categories,
      if (categoryConfidence != null) 'categoryConfidence': categoryConfidence,
      if (latestNode != null) 'latestNode': latestNode!.toJson(),
      'hasUnreadUpdate': hasRecentUpdate,
      if (unreadSignalCount != null) 'unreadNodeCount': unreadSignalCount,
    };
  }

  factory FollowedTopicItemDto.fromJson(Map<String, dynamic> json) {
    return FollowedTopicItemDto(
      followId: json['followId'] as String,
      topicId: json['topicId'] as String,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? false,
      followedAt: DateTime.parse(json['followedAt'] as String),
      lastViewedAt: json['lastViewedAt'] == null
          ? null
          : DateTime.parse(json['lastViewedAt'] as String),
      latestRelevantEventAt: json['latestRelevantEventAt'] == null
          ? null
          : DateTime.parse(json['latestRelevantEventAt'] as String),
      latestRelevantEventSummary: json['latestRelevantEventSummary'] as String?,
      hasRecentUpdate: json['hasUnreadUpdate'] as bool? ??
          json['hasRecentUpdate'] as bool? ??
          false,
      unreadSignalCount:
          json['unreadNodeCount'] as int? ?? json['unreadSignalCount'] as int?,
      primaryCategory: json['primaryCategory'] as String?,
      categories: readStringList(json['categories']),
      categoryConfidence: readDouble(json['categoryConfidence']),
      latestNode: json['latestNode'] == null
          ? null
          : LatestNodeDto.fromJson(json['latestNode'] as Map<String, dynamic>),
    );
  }
}

class FollowedTopicListDto {
  const FollowedTopicListDto({
    required this.items,
    this.generatedAt,
  });

  final List<FollowedTopicItemDto> items;
  final DateTime? generatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(),
      if (generatedAt != null) 'generatedAt': generatedAt!.toIso8601String(),
    };
  }

  factory FollowedTopicListDto.fromJson(Map<String, dynamic> json) {
    return FollowedTopicListDto(
      items: (json['items'] as List<dynamic>)
          .map((item) =>
              FollowedTopicItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      generatedAt: json['generatedAt'] == null
          ? null
          : DateTime.parse(json['generatedAt'] as String),
    );
  }
}

class FollowMutationResultDto {
  const FollowMutationResultDto({
    required this.followed,
    this.topicId,
    this.item,
    this.isPinned,
    this.capabilities,
  });

  final bool followed;
  final String? topicId;
  final FollowedTopicItemDto? item;
  final bool? isPinned;
  final UserCapabilitiesDto? capabilities;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'followed': followed,
      if (topicId != null) 'topicId': topicId,
      if (item != null) 'item': item!.toJson(),
      if (isPinned != null) 'isPinned': isPinned,
      if (capabilities != null) 'capabilities': capabilities!.toJson(),
    };
  }

  factory FollowMutationResultDto.fromJson(Map<String, dynamic> json) {
    return FollowMutationResultDto(
      followed: json['followed'] as bool,
      topicId: json['topicId'] as String?,
      item: json['item'] == null
          ? null
          : FollowedTopicItemDto.fromJson(json['item'] as Map<String, dynamic>),
      isPinned: json['isPinned'] as bool?,
      capabilities: json['capabilities'] == null
          ? null
          : UserCapabilitiesDto.fromJson(
              json['capabilities'] as Map<String, dynamic>),
    );
  }
}

class UserCapabilitiesDto {
  const UserCapabilitiesDto({
    required this.authenticated,
    required this.accountTier,
    required this.followLimit,
    this.followCount,
    this.remainingFollowQuota,
  });

  final bool authenticated;
  final String accountTier;
  final int followLimit;
  final int? followCount;
  final int? remainingFollowQuota;

  bool get isGuest => !authenticated || accountTier == 'guest';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'authenticated': authenticated,
      'accountTier': accountTier,
      'followLimit': followLimit,
      if (followCount != null) 'followCount': followCount,
      if (remainingFollowQuota != null)
        'remainingFollowQuota': remainingFollowQuota,
    };
  }

  factory UserCapabilitiesDto.fromJson(Map<String, dynamic> json) {
    return UserCapabilitiesDto(
      authenticated: json['authenticated'] as bool? ?? false,
      accountTier: json['accountTier'] as String? ?? 'guest',
      followLimit: json['followLimit'] as int? ?? 5,
      followCount: json['followCount'] as int?,
      remainingFollowQuota: json['remainingFollowQuota'] as int?,
    );
  }
}

class GuestSkippedTopicDto {
  const GuestSkippedTopicDto({
    required this.topicId,
    this.reason,
  });

  final String topicId;
  final String? reason;

  bool get isFollowLimitReached => reason == 'FOLLOW_LIMIT_REACHED';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'topicId': topicId,
      if (reason != null) 'reason': reason,
    };
  }

  factory GuestSkippedTopicDto.fromJson(Map<String, dynamic> json) {
    return GuestSkippedTopicDto(
      topicId: json['topicId'] as String? ?? '',
      reason: json['reason'] as String?,
    );
  }
}

List<String> _readStringList(dynamic value) {
  return (value as List<dynamic>? ?? const <dynamic>[])
      .whereType<String>()
      .toList();
}

List<GuestSkippedTopicDto> _readSkippedTopics(
  Map<String, dynamic> json,
  List<String> skippedTopicIds,
) {
  final rawSkippedTopics = json['skippedTopics'] as List<dynamic>?;
  if (rawSkippedTopics == null) {
    return skippedTopicIds
        .map((topicId) => GuestSkippedTopicDto(topicId: topicId))
        .toList();
  }
  return rawSkippedTopics
      .whereType<Map>()
      .map(
          (item) => GuestSkippedTopicDto.fromJson(item.cast<String, dynamic>()))
      .where((item) => item.topicId.isNotEmpty)
      .toList();
}

class GuestFollowMergeResultDto {
  const GuestFollowMergeResultDto({
    required this.mergedTopicIds,
    required this.alreadyFollowedTopicIds,
    required this.skippedTopicIds,
    this.skippedTopics = const <GuestSkippedTopicDto>[],
    required this.followCount,
    required this.followLimit,
    required this.remainingFollowQuota,
  });

  final List<String> mergedTopicIds;
  final List<String> alreadyFollowedTopicIds;
  final List<String> skippedTopicIds;
  final List<GuestSkippedTopicDto> skippedTopics;
  final int followCount;
  final int followLimit;
  final int remainingFollowQuota;

  List<String> get followLimitSkippedTopicIds {
    return skippedTopics
        .where((topic) => topic.isFollowLimitReached)
        .map((topic) => topic.topicId)
        .toList();
  }

  UserCapabilitiesDto toCapabilities() {
    return UserCapabilitiesDto(
      authenticated: true,
      accountTier: followLimit >= 50 ? 'pro' : 'free',
      followLimit: followLimit,
      followCount: followCount,
      remainingFollowQuota: remainingFollowQuota,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mergedTopicIds': mergedTopicIds,
      'alreadyFollowedTopicIds': alreadyFollowedTopicIds,
      'skippedTopicIds': skippedTopicIds,
      'skippedTopics': skippedTopics.map((item) => item.toJson()).toList(),
      'followCount': followCount,
      'followLimit': followLimit,
      'remainingFollowQuota': remainingFollowQuota,
    };
  }

  factory GuestFollowMergeResultDto.fromJson(Map<String, dynamic> json) {
    final skippedTopicIds = _readStringList(json['skippedTopicIds']);
    final skippedTopics = _readSkippedTopics(json, skippedTopicIds);
    return GuestFollowMergeResultDto(
      mergedTopicIds: _readStringList(json['mergedTopicIds']),
      alreadyFollowedTopicIds: _readStringList(json['alreadyFollowedTopicIds']),
      skippedTopicIds: skippedTopicIds.isNotEmpty
          ? skippedTopicIds
          : skippedTopics.map((item) => item.topicId).toList(),
      skippedTopics: skippedTopics,
      followCount: json['followCount'] as int? ?? 0,
      followLimit: json['followLimit'] as int? ?? 10,
      remainingFollowQuota: json['remainingFollowQuota'] as int? ?? 0,
    );
  }
}

class GuestTopicClaimResultDto {
  const GuestTopicClaimResultDto({
    required this.claimedTopicIds,
    required this.alreadyOwnedTopicIds,
    required this.skippedTopicIds,
    this.skippedTopics = const <GuestSkippedTopicDto>[],
    required this.followCount,
    required this.followLimit,
    required this.remainingFollowQuota,
  });

  final List<String> claimedTopicIds;
  final List<String> alreadyOwnedTopicIds;
  final List<String> skippedTopicIds;
  final List<GuestSkippedTopicDto> skippedTopics;
  final int followCount;
  final int followLimit;
  final int remainingFollowQuota;

  List<String> get followLimitSkippedTopicIds {
    return skippedTopics
        .where((topic) => topic.isFollowLimitReached)
        .map((topic) => topic.topicId)
        .toList();
  }

  UserCapabilitiesDto toCapabilities() {
    return UserCapabilitiesDto(
      authenticated: true,
      accountTier: followLimit >= 50 ? 'pro' : 'free',
      followLimit: followLimit,
      followCount: followCount,
      remainingFollowQuota: remainingFollowQuota,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'claimedTopicIds': claimedTopicIds,
      'alreadyOwnedTopicIds': alreadyOwnedTopicIds,
      'skippedTopicIds': skippedTopicIds,
      'skippedTopics': skippedTopics.map((item) => item.toJson()).toList(),
      'followCount': followCount,
      'followLimit': followLimit,
      'remainingFollowQuota': remainingFollowQuota,
    };
  }

  factory GuestTopicClaimResultDto.fromJson(Map<String, dynamic> json) {
    final skippedTopicIds = _readStringList(json['skippedTopicIds']);
    final skippedTopics = _readSkippedTopics(json, skippedTopicIds);
    return GuestTopicClaimResultDto(
      claimedTopicIds: _readStringList(json['claimedTopicIds']),
      alreadyOwnedTopicIds: _readStringList(json['alreadyOwnedTopicIds']),
      skippedTopicIds: skippedTopicIds.isNotEmpty
          ? skippedTopicIds
          : skippedTopics.map((item) => item.topicId).toList(),
      skippedTopics: skippedTopics,
      followCount: json['followCount'] as int? ?? 0,
      followLimit: json['followLimit'] as int? ?? 10,
      remainingFollowQuota: json['remainingFollowQuota'] as int? ?? 0,
    );
  }
}

class FollowedTopicCacheSnapshot {
  const FollowedTopicCacheSnapshot({
    required this.payload,
    required this.cachedAt,
  });

  final FollowedTopicListDto payload;
  final DateTime cachedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'payload': payload.toJson(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  factory FollowedTopicCacheSnapshot.fromJson(Map<String, dynamic> json) {
    return FollowedTopicCacheSnapshot(
      payload: FollowedTopicListDto.fromJson(
          json['payload'] as Map<String, dynamic>),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }
}
