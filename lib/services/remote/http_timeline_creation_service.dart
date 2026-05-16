import '../../models/timeline_creation_models.dart';
import '../../models/timeline_models.dart';
import '../timeline_creation_service.dart';
import 'http_api_client.dart';

class HttpTimelineCreationService implements TimelineCreationService {
  HttpTimelineCreationService(this._client);

  final HttpApiClient _client;

  @override
  Future<List<TimelineDirectionCandidate>> suggestDirections(
    String keywords, {
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
  }) async {
    final normalizedInterestCategoryIds = _readKnownInterestCategoryIds(
      interestCategoryIds,
    );
    final data = await _client.post(
      '/topics/expand-definition/candidates',
      authenticated: true,
      includeGuestKey: true,
      body: <String, dynamic>{
        'keywords': keywords,
        if (categoryHint != null && categoryHint.trim().isNotEmpty)
          'categoryId': categoryHint.trim(),
        if (normalizedInterestCategoryIds.isNotEmpty)
          'interestCategoryIds': normalizedInterestCategoryIds,
      },
    );
    final items = data['items'];
    if (items is! List) {
      return const <TimelineDirectionCandidate>[];
    }
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .map(_candidateFromJson)
        .where((candidate) => candidate.title.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<TimelineDraft> expandKeywords(
    String keywords, {
    required int variation,
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
    TopicDefinition? currentDefinition,
    TopicDefinition? removedDefinition,
    TimelineDirectionCandidate? selectedDirection,
    TimelineExpansionProgressCallback? onProgress,
  }) async {
    if (onProgress != null) {
      try {
        return await _expandKeywordsWithJob(
          keywords,
          variation: variation,
          categoryHint: categoryHint,
          interestCategoryIds: interestCategoryIds,
          currentDefinition: currentDefinition,
          removedDefinition: removedDefinition,
          selectedDirection: selectedDirection,
          onProgress: onProgress,
        );
      } on HttpApiException catch (error) {
        if (error.statusCode != 404 && error.statusCode != 405) {
          rethrow;
        }
      }
    }

    return _expandKeywordsSynchronously(
      keywords,
      variation: variation,
      categoryHint: categoryHint,
      interestCategoryIds: interestCategoryIds,
      currentDefinition: currentDefinition,
      removedDefinition: removedDefinition,
      selectedDirection: selectedDirection,
    );
  }

  Future<TimelineDraft> _expandKeywordsSynchronously(
    String keywords, {
    required int variation,
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
    TopicDefinition? currentDefinition,
    TopicDefinition? removedDefinition,
    TimelineDirectionCandidate? selectedDirection,
  }) async {
    final normalizedInterestCategoryIds = _readKnownInterestCategoryIds(
      interestCategoryIds,
    );
    final currentDefinitionPayload = _definitionPayload(currentDefinition);
    final removedDefinitionPayload = _definitionPayload(removedDefinition);
    final selectedDirectionPayload = _candidatePayload(selectedDirection);
    final data = await _client.post(
      '/topics/expand-definition',
      authenticated: true,
      includeGuestKey: true,
      body: <String, dynamic>{
        'keywords': keywords,
        if (categoryHint != null && categoryHint.trim().isNotEmpty)
          'categoryId': categoryHint.trim(),
        if (normalizedInterestCategoryIds.isNotEmpty)
          'interestCategoryIds': normalizedInterestCategoryIds,
        if (currentDefinitionPayload != null)
          'currentDefinition': currentDefinitionPayload,
        if (removedDefinitionPayload != null)
          'removedDefinition': removedDefinitionPayload,
        if (selectedDirectionPayload != null)
          'selectedDirection': selectedDirectionPayload,
      },
    );
    return _draftFromJson(data, variation: variation);
  }

  Future<TimelineDraft> _expandKeywordsWithJob(
    String keywords, {
    required int variation,
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
    TopicDefinition? currentDefinition,
    TopicDefinition? removedDefinition,
    TimelineDirectionCandidate? selectedDirection,
    required TimelineExpansionProgressCallback onProgress,
  }) async {
    final normalizedInterestCategoryIds = _readKnownInterestCategoryIds(
      interestCategoryIds,
    );
    final currentDefinitionPayload = _definitionPayload(currentDefinition);
    final removedDefinitionPayload = _definitionPayload(removedDefinition);
    final selectedDirectionPayload = _candidatePayload(selectedDirection);
    final job = await _client.post(
      '/topics/expand-definition/jobs',
      authenticated: true,
      includeGuestKey: true,
      body: <String, dynamic>{
        'keywords': keywords,
        if (categoryHint != null && categoryHint.trim().isNotEmpty)
          'categoryId': categoryHint.trim(),
        if (normalizedInterestCategoryIds.isNotEmpty)
          'interestCategoryIds': normalizedInterestCategoryIds,
        if (currentDefinitionPayload != null)
          'currentDefinition': currentDefinitionPayload,
        if (removedDefinitionPayload != null)
          'removedDefinition': removedDefinitionPayload,
        if (selectedDirectionPayload != null)
          'selectedDirection': selectedDirectionPayload,
      },
    );
    final jobId = _readString(job['jobId']);
    if (jobId.isEmpty) {
      throw const HttpApiException(message: 'AI 扩写任务创建失败。');
    }
    onProgress(_progressFromJson(job));

    for (var attempt = 0; attempt < 180; attempt += 1) {
      final detail = await _client.get(
        '/topics/expand-definition/jobs/$jobId',
        authenticated: true,
        includeGuestKey: true,
      );
      final progress = _progressFromJson(detail);
      onProgress(progress);
      final status = _readString(detail['status']);
      if (status == 'done') {
        final result = detail['result'];
        if (result is Map<String, dynamic>) {
          return _draftFromJson(result, variation: variation);
        }
        if (result is Map) {
          return _draftFromJson(
            result.cast<String, dynamic>(),
            variation: variation,
          );
        }
        throw const HttpApiException(message: 'AI 扩写任务缺少结果。');
      }
      if (status == 'failed') {
        final error = _readString(detail['error']);
        throw HttpApiException(
          message: error.isEmpty ? 'AI 扩写任务失败。' : error,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw const HttpApiException(message: 'AI 扩写任务超时。');
  }

  Map<String, dynamic>? _candidatePayload(
    TimelineDirectionCandidate? candidate,
  ) {
    if (candidate == null) {
      return null;
    }
    return candidate.toJson();
  }

  Map<String, dynamic>? _definitionPayload(TopicDefinition? definition) {
    if (definition == null) {
      return null;
    }
    final coreKeywords = _readStringList(definition.coreKeywords);
    final extendedKeywords = _readStringList(definition.relatedKeywords);
    final excludedKeywords = _readStringList(definition.excludedKeywords);
    if (coreKeywords.isEmpty &&
        extendedKeywords.isEmpty &&
        excludedKeywords.isEmpty) {
      return null;
    }
    return <String, dynamic>{
      'coreKeywords': coreKeywords,
      'extendedKeywords': extendedKeywords,
      'excludedKeywords': excludedKeywords,
      if (definition.trackingDirection.trim().isNotEmpty)
        'trackingDirection': definition.trackingDirection.trim(),
      if (definition.trackingQuestion.trim().isNotEmpty)
        'trackingQuestion': definition.trackingQuestion.trim(),
      if (definition.topicObject.trim().isNotEmpty)
        'topicObject': definition.topicObject.trim(),
      if (definition.topicScope.trim().isNotEmpty)
        'topicScope': definition.topicScope.trim(),
      if (definition.timelineType.trim().isNotEmpty)
        'timelineType': definition.timelineType.trim(),
      if (definition.timelineFocus.trim().isNotEmpty)
        'timelineFocus': definition.timelineFocus.trim(),
      if (definition.nodeSelectionPolicy.isNotEmpty)
        'nodeSelectionPolicy': definition.nodeSelectionPolicy,
      if (definition.startDateConfidence.trim().isNotEmpty)
        'startDateConfidence': definition.startDateConfidence.trim(),
      if (definition.timelineTypeConfidence.trim().isNotEmpty)
        'timelineTypeConfidence': definition.timelineTypeConfidence.trim(),
      if (definition.sourceEvidenceCount > 0)
        'sourceEvidenceCount': definition.sourceEvidenceCount,
      if (definition.recentActivityStatus.trim().isNotEmpty &&
          definition.recentActivityStatus.trim() != 'unknown')
        'recentActivityStatus': definition.recentActivityStatus.trim(),
      if (definition.recentEvidenceCount > 0)
        'recentEvidenceCount': definition.recentEvidenceCount,
      if (definition.latestRelevantSourceAt != null)
        'latestRelevantSourceAt':
            definition.latestRelevantSourceAt!.toUtc().toIso8601String(),
      if (definition.trackingViability.trim().isNotEmpty &&
          definition.trackingViability.trim() != 'low')
        'trackingViability': definition.trackingViability.trim(),
      if (definition.trackingViabilityReason.trim().isNotEmpty)
        'trackingViabilityReason': definition.trackingViabilityReason.trim(),
    };
  }

  TimelineDirectionCandidate _candidateFromJson(Map<String, dynamic> json) {
    return TimelineDirectionCandidate(
      candidateId: _readString(json['candidateId']),
      title: _readString(json['title']),
      trackingDirection: _readString(json['trackingDirection']),
      trackingQuestion: _readString(json['trackingQuestion']),
      topicObject: _readString(json['topicObject']),
      topicScope: _readString(json['topicScope']),
      timelineType: _readString(json['timelineType']),
      timelineTypeConfidence: _readString(json['timelineTypeConfidence']),
      categoryId: _readString(json['categoryId']),
      primaryCategory: _readString(json['primaryCategory']),
      recentActivityStatus: _readString(json['recentActivityStatus']).isNotEmpty
          ? _readString(json['recentActivityStatus'])
          : 'unknown',
      trackingViability: _readString(json['trackingViability']).isNotEmpty
          ? _readString(json['trackingViability'])
          : 'low',
      sourceEvidenceCount: _readInt(json['sourceEvidenceCount']),
      recentEvidenceCount: _readInt(json['recentEvidenceCount']),
      latestRelevantSourceAt: _readDateTime(json['latestRelevantSourceAt']),
      reason: _readString(json['reason']),
      isRecommended: json['isRecommended'] == true,
    );
  }

  TimelineDraft _draftFromJson(
    Map<String, dynamic> json, {
    required int variation,
  }) {
    final definitionJson =
        (json['topicDefinition'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final definition = TopicDefinition(
      overview: _readString(definitionJson['overview']),
      includeScope: _readString(definitionJson['includeScope']),
      excludeScope: _readString(definitionJson['excludeScope']),
      coreKeywords: _readStringList(definitionJson['coreKeywords']),
      relatedKeywords: _readStringList(
        definitionJson['relatedKeywords'] ?? definitionJson['extendedKeywords'],
      ),
      excludedKeywords: _readStringList(definitionJson['excludedKeywords']),
      trackingDirection: _readString(json['trackingDirection']),
      trackingQuestion: _readString(json['trackingQuestion']),
      topicObject: _readString(json['topicObject']),
      topicScope: _readString(json['topicScope']),
      timelineType: _readString(json['timelineType']),
      timelineFocus: _readString(json['timelineFocus']),
      nodeSelectionPolicy: _readStringListMap(json['nodeSelectionPolicy']),
      startDateConfidence: _readString(json['startDateConfidence']),
      timelineTypeConfidence: _readString(json['timelineTypeConfidence']),
      sourceEvidenceCount: _readInt(json['sourceEvidenceCount']),
      recentActivityStatus: _readString(json['recentActivityStatus']).isNotEmpty
          ? _readString(json['recentActivityStatus'])
          : 'unknown',
      recentEvidenceCount: _readInt(json['recentEvidenceCount']),
      latestRelevantSourceAt: _readDateTime(json['latestRelevantSourceAt']),
      trackingViability: _readString(json['trackingViability']).isNotEmpty
          ? _readString(json['trackingViability'])
          : 'low',
      trackingViabilityReason: _readString(json['trackingViabilityReason']),
    );
    final startDate = _readDate(json['startDate']) ?? DateTime.now();
    final topicName = _readString(json['topicName']).isNotEmpty
        ? _readString(json['topicName'])
        : _readString(json['title']);
    final summary = _readString(json['summary']);

    return TimelineDraft(
      keywords: _readString(json['keywords']),
      topicName: topicName,
      tagline: _readString(json['tagline']),
      summary: summary,
      categoryId: _readString(json['categoryId']).isNotEmpty
          ? _readString(json['categoryId'])
          : _readString(json['interestCategoryId']),
      definition: definition,
      trackingDirection: definition.trackingDirection,
      trackingQuestion: definition.trackingQuestion,
      topicObject: definition.topicObject,
      topicScope: definition.topicScope,
      timelineType: definition.timelineType,
      timelineFocus: definition.timelineFocus,
      nodeSelectionPolicy: definition.nodeSelectionPolicy,
      startDateConfidence: definition.startDateConfidence,
      timelineTypeConfidence: definition.timelineTypeConfidence,
      sourceEvidenceCount: definition.sourceEvidenceCount,
      recentActivityStatus: definition.recentActivityStatus,
      recentEvidenceCount: definition.recentEvidenceCount,
      latestRelevantSourceAt: definition.latestRelevantSourceAt,
      trackingViability: definition.trackingViability,
      trackingViabilityReason: definition.trackingViabilityReason,
      seedEntries: <TimelineEntry>[
        TimelineEntry(
          id: 'draft-brief-$variation',
          topicId: 'draft',
          title: '事件起点识别',
          summary: summary.isNotEmpty ? summary : '后端已生成专题定义草案。',
          detail: definition.overview,
          fullText:
              '${definition.includeScope}\n${definition.excludeScope}'.trim(),
          sourceName: 'AI 扩写',
          timestamp: startDate,
          isMajor: true,
        ),
      ],
    );
  }

  String _readString(Object? value) {
    if (value is String) {
      return value.trim();
    }
    return '';
  }

  List<String> _readStringList(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  List<String> _readKnownInterestCategoryIds(List<String> values) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final value in values) {
      final id = value.trim();
      if (id.isEmpty || !seen.add(id)) {
        continue;
      }
      normalized.add(id);
    }
    return normalized;
  }

  Map<String, List<String>> _readStringListMap(Object? value) {
    if (value is! Map) {
      return const <String, List<String>>{};
    }
    final result = <String, List<String>>{};
    value.forEach((key, rawItems) {
      if (key is! String || rawItems is! List) {
        return;
      }
      result[key] = rawItems.whereType<String>().toList(growable: false);
    });
    return result;
  }

  int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  DateTime? _readDate(Object? value) {
    final raw = _readString(value);
    if (raw.isEmpty) {
      return null;
    }
    final parts = raw.split('-');
    if (parts.length != 3) {
      return DateTime.tryParse(raw);
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return DateTime.tryParse(raw);
    }
    return DateTime(year, month, day);
  }

  DateTime? _readDateTime(Object? value) {
    final raw = _readString(value);
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  TimelineExpansionProgress _progressFromJson(Map<String, dynamic> json) {
    return TimelineExpansionProgress(
      status: _readString(json['status']),
      stage: _readString(json['stage']),
      items: _readProgressItems(json['progressItems']),
    );
  }

  List<TimelineExpansionProgressItem> _readProgressItems(Object? value) {
    if (value is! List) {
      return const <TimelineExpansionProgressItem>[];
    }
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .map(
          (item) => TimelineExpansionProgressItem(
            title: _readString(item['title']),
            date: _readDate(item['date']),
            sourceTier: _readString(item['sourceTier']).isNotEmpty
                ? _readString(item['sourceTier'])
                : 'general_web',
            url: _readString(item['url']),
          ),
        )
        .where((item) => item.title.isNotEmpty)
        .toList(growable: false);
  }
}
