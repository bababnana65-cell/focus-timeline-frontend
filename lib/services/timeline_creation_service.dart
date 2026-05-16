import '../models/interest_category.dart';
import '../models/timeline_creation_models.dart';
import '../models/timeline_models.dart';

typedef TimelineExpansionProgressCallback = void Function(
  TimelineExpansionProgress progress,
);

abstract class TimelineCreationService {
  Future<List<TimelineDirectionCandidate>> suggestDirections(
    String keywords, {
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
  });

  Future<TimelineDraft> expandKeywords(
    String keywords, {
    required int variation,
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
    TopicDefinition? currentDefinition,
    TopicDefinition? removedDefinition,
    TimelineDirectionCandidate? selectedDirection,
    TimelineExpansionProgressCallback? onProgress,
  });
}

class MockTimelineCreationService implements TimelineCreationService {
  static const List<String> _nameSuffixes = <String>[
    '事件时间线',
    '进展追踪',
    '演进观察',
    '动态档案',
  ];

  static const List<String> _taglineTemplates = <String>[
    '聚焦%s的关键节点、外部反馈与最新走向',
    '围绕%s持续整理进展、信号与潜在转折',
    '从背景、发酵到关键变化，持续追踪%s',
    '把%s拆成可阅读、可更新的事件时间线',
  ];

  static const List<String> _summaryTemplates = <String>[
    'AI 已根据关键词补全出一个更明确的事件定义，你可以直接创建时间线，或者继续扩写。',
    '这个事件定义更适合做持续追踪，既能覆盖背景，也能承接后续新动态。',
    '当前草案已经收束成一个较清晰的专题，适合作为单独时间线长期更新。',
  ];

  @override
  Future<List<TimelineDirectionCandidate>> suggestDirections(
    String keywords, {
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final parts = keywords
        .split(RegExp(r'[\s,，、;；]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final focus = parts.isEmpty ? '新事件' : parts.join('');
    final categoryId = _normalizeCategoryHint(categoryHint) ??
        _firstKnownInterestCategoryId(interestCategoryIds) ??
        _inferCategoryId(parts.join(' '));
    return <TimelineDirectionCandidate>[
      TimelineDirectionCandidate(
        candidateId: 'candidate_recent',
        title: '$focus近期关键进展时间线',
        trackingDirection: '追踪$focus近期发生、回应、调查、处置和后续更新的时间线',
        trackingQuestion: '$focus近期发生了什么，后续如何回应和处置？',
        topicObject: focus,
        topicScope: '纳入与$focus直接相关、能形成时间轴的关键事实节点。',
        categoryId: categoryId,
        primaryCategory: 'general_event',
        recentActivityStatus: 'unknown',
        trackingViability: 'low',
        recentEvidenceCount: 0,
        reason: '本地 mock 候选，用于创建页两段式交互。',
        isRecommended: true,
      ),
      TimelineDirectionCandidate(
        candidateId: 'candidate_process',
        title: '$focus前因后果与阶段演变时间线',
        trackingDirection: '追踪$focus从起因、关键阶段、外部回应到当前状态变化的时间线',
        trackingQuestion: '$focus的前因后果和阶段变化是什么？',
        topicObject: focus,
        topicScope: '纳入背景、关键阶段、回应、影响变化和后续更新。',
        categoryId: categoryId,
        primaryCategory: 'general_event',
        recentActivityStatus: 'unknown',
        trackingViability: 'low',
        recentEvidenceCount: 0,
        reason: '适合梳理完整背景和中间过程。',
      ),
    ];
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
    onProgress?.call(
      const TimelineExpansionProgress(
        status: 'generating',
        stage: '正在整理专题方向',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 420));

    final rawParts = keywords
        .split(RegExp(r'[\s,，、;；]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final parts = rawParts.isEmpty ? <String>['新事件'] : rawParts;
    final joined = parts.join(' · ');
    final focus =
        parts.length >= 2 ? '${parts.first}与${parts[1]}' : parts.first;
    final inferredCategoryId = _inferCategoryId(parts.join(' '));
    final categoryId = _normalizeCategoryHint(categoryHint) ??
        _normalizeCategoryHint(selectedDirection?.categoryId) ??
        (inferredCategoryId == 'society'
            ? _firstKnownInterestCategoryId(interestCategoryIds) ??
                inferredCategoryId
            : inferredCategoryId);
    final categoryLabel = interestCategoryById(categoryId).label;
    final nameSuffix = _nameSuffixes[variation % _nameSuffixes.length];
    final topicName =
        '${parts.first}${parts.length > 1 ? ' / ${parts[1]}' : ''}$nameSuffix';
    final taglineTemplate =
        _taglineTemplates[variation % _taglineTemplates.length];
    final summary = _summaryTemplates[variation % _summaryTemplates.length];
    final tagline =
        '$categoryLabel视角：${taglineTemplate.replaceFirst('%s', focus)}';
    final startDate = _inferStartDate(parts, variation, categoryId);
    final trackingDirection =
        selectedDirection?.trackingDirection ?? '追踪$focus的关键节点、阶段变化和当前状态';
    final trackingQuestion =
        selectedDirection?.trackingQuestion ?? '$focus的关键节点如何随时间变化？';
    final topicObject = selectedDirection?.topicObject ?? focus;
    final topicScope =
        selectedDirection?.topicScope ?? _buildIncludeScope(focus, categoryLabel);
    final generatedDefinition = TopicDefinition(
      overview: _buildOverview(parts, focus, categoryLabel),
      includeScope: _buildIncludeScope(focus, categoryLabel),
      excludeScope: _buildExcludeScope(focus, categoryLabel),
      coreKeywords: _buildCoreKeywords(parts),
      relatedKeywords: _buildRelatedKeywords(parts, categoryId),
      excludedKeywords: _buildExcludedKeywords(parts, categoryId),
      trackingDirection: trackingDirection,
      trackingQuestion: trackingQuestion,
      topicObject: topicObject,
      topicScope: topicScope,
      timelineType: 'origin_evolution',
      timelineFocus: focus,
      nodeSelectionPolicy: const <String, List<String>>{
        'include': <String>['直接相关节点'],
        'exclude': <String>['无关评论'],
      },
      startDateConfidence: 'medium',
      timelineTypeConfidence: 'medium',
      sourceEvidenceCount: 0,
    );
    final definition = _mergeDefinitionKeywords(
      generatedDefinition,
      currentDefinition: currentDefinition,
      removedDefinition: removedDefinition,
    );
    const seedTopicId = 'draft';

    return TimelineDraft(
      keywords: joined,
      topicName: topicName,
      tagline: tagline,
      summary:
          '$summary 这次会同时给出专题定义、纳入范围和排除范围，方便你先确认边界，再创建时间线。AI 判断它更接近「$categoryLabel」类别，并建议从 ${startDate.year}年${startDate.month}月${startDate.day}日 开始追踪。',
      categoryId: categoryId,
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
      seedEntries: <TimelineEntry>[
        TimelineEntry(
          id: 'draft-brief-$variation',
          topicId: seedTopicId,
          title: '事件起点识别',
          summary: '事件从这里开始进入可持续追踪阶段。',
          detail: 'AI 根据关键词“$joined”推断出一个较合理的事件起点，后续时间线会从这里开始累积。',
          fullText:
              '系统根据你输入的关键词“$joined”生成了首版事件定义，并推断出一个事件起点时间。确认创建后，时间线会从这个起点开始，而不是从当前日期开始。',
          sourceName: 'AI 扩写',
          timestamp: startDate,
          isMajor: true,
        ),
      ],
    );
  }

  String? _normalizeCategoryHint(String? categoryHint) {
    final normalized = categoryHint?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return isKnownInterestCategoryId(normalized) ? normalized : null;
  }

  String? _firstKnownInterestCategoryId(List<String> categoryIds) {
    for (final categoryId in categoryIds) {
      final normalized = categoryId.trim();
      if (isKnownInterestCategoryId(normalized)) {
        return normalized;
      }
    }
    return null;
  }

  String _inferCategoryId(String joined) {
    final lower = joined.toLowerCase();
    if (_containsAny(lower, <String>['战争', '冲突', '导弹', '军事', '军队', '防空'])) {
      return 'military';
    }
    if (_containsAny(lower, <String>['外交', '国际', '联合国', '制裁', '关税'])) {
      return 'international';
    }
    if (_containsAny(lower, <String>['政策', '监管', '选举', '政府', '改革'])) {
      return 'politics';
    }
    if (_containsAny(lower, <String>['融资', '股价', '债务', '金融', '资本', '上市'])) {
      return 'finance';
    }
    if (_containsAny(lower, <String>['经济', '油价', '价格', '通胀', '消费'])) {
      return 'economy';
    }
    if (_containsAny(lower, <String>['公司', '企业', '商业', '重组', '裁员', '并购'])) {
      return 'enterprise';
    }
    if (_containsAny(lower, <String>['ai', '芯片', '模型', '技术', '发布', '上线'])) {
      return 'technology';
    }
    if (_containsAny(lower, <String>['医疗', '药', '医院', '疫苗', '疾病'])) {
      return 'health';
    }
    if (_containsAny(lower, <String>['气候', '环境', '能源', '污染', '碳'])) {
      return 'climate';
    }
    if (_containsAny(lower, <String>['历史', '遗产', '考古', '古代', '世纪'])) {
      return 'history';
    }
    if (_containsAny(lower, <String>['电影', '体育', '赛事', '文化', '演出'])) {
      return 'culture';
    }
    return 'society';
  }

  bool _containsAny(String value, List<String> candidates) {
    return candidates.any(value.contains);
  }

  DateTime _inferStartDate(
      List<String> parts, int variation, String categoryId) {
    final joined = parts.join(' ');
    final explicit = _parseExplicitDate(joined);
    if (explicit != null) {
      return explicit;
    }

    final now = DateTime.now();
    final lower = joined.toLowerCase();
    if (lower.contains('发布') || lower.contains('上线') || lower.contains('开售')) {
      return now.subtract(const Duration(days: 14));
    }
    if (lower.contains('重组') || lower.contains('裁员') || lower.contains('融资')) {
      return now.subtract(const Duration(days: 45));
    }
    if (lower.contains('事故') || lower.contains('冲突') || lower.contains('调查')) {
      return now.subtract(const Duration(days: 7));
    }

    final categoryOffset = switch (categoryId) {
      'history' => 365,
      'politics' => 60,
      'military' => 10,
      'economy' => 45,
      'finance' => 21,
      'enterprise' => 30,
      'technology' => 20,
      'health' => 28,
      'climate' => 90,
      'culture' => 35,
      'international' => 18,
      _ => 30,
    };
    return now.subtract(Duration(days: categoryOffset + (variation % 4) * 15));
  }

  DateTime? _parseExplicitDate(String input) {
    final normalized = input
        .replaceAll('公元', '')
        .replaceAll('年', '-')
        .replaceAll('月', '-')
        .replaceAll('日', '')
        .replaceAll('/', '-')
        .replaceAll('.', '-');

    final match = RegExp(r'(?<!\d)(\d{1,4})-(\d{1,2})-(\d{1,2})(?!\d)')
        .firstMatch(normalized);
    if (match == null) {
      return null;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (year <= 0) {
      return null;
    }
    return DateTime(year, month, day);
  }

  String _buildOverview(
      List<String> parts, String focus, String categoryLabel) {
    if (parts.length == 1) {
      return '以「$categoryLabel」视角围绕「$focus」建立一条可持续追踪的专业专题，只保留和它直接相关的关键进展、确认信息与阶段转折。';
    }
    return '以「$categoryLabel」视角围绕「$focus」建立一条边界清晰的专业专题，重点收录会直接影响该主题判断的新进展、关键动作与外部确认信号。';
  }

  String _buildIncludeScope(String focus, String categoryLabel) {
    return '纳入与「$focus」直接相关的$categoryLabel信号、官方表态、关键动作、阶段变化、外部确认、影响范围变化，以及会改变后续判断的重要节点。';
  }

  String _buildExcludeScope(String focus, String categoryLabel) {
    return '排除与「$focus」只有弱关联的泛评论、纯情绪表达、旧闻复读、没有新增事实的信息，以及偏离$categoryLabel视角的噪声内容。';
  }

  List<String> _buildCoreKeywords(List<String> parts) {
    final keywords = <String>[
      ...parts,
      if (parts.length >= 2) '${parts.first}${parts[1]}',
      ...parts.expand(_expandAliases),
    ];
    return _dedupeKeywords(keywords).take(6).toList();
  }

  List<String> _buildRelatedKeywords(List<String> parts, String categoryId) {
    final lower = parts.join(' ').toLowerCase();
    final related = <String>[
      '关键节点',
      '最新进展',
      '官方回应',
      ..._domainKeywords(lower, categoryId),
    ];
    return _dedupeKeywords(related).take(8).toList();
  }

  List<String> _buildExcludedKeywords(List<String> parts, String categoryId) {
    final lower = parts.join(' ').toLowerCase();
    final keywords = <String>[
      ..._domainExcludedKeywords(lower, categoryId),
      '二次演绎',
      '无关评论',
      '旧闻复读',
    ];
    return _dedupeKeywords(keywords).take(6).toList();
  }

  Iterable<String> _expandAliases(String value) sync* {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    yield trimmed;
    if (trimmed.contains('美伊')) {
      yield '美国';
      yield '伊朗';
    }
    if (trimmed.contains('海峡')) {
      yield '通航';
    }
    if (trimmed.contains('导弹')) {
      yield '发射';
      yield '拦截';
    }
    if (trimmed.contains('战争') || trimmed.contains('冲突')) {
      yield '军事行动';
      yield '外交表态';
    }
  }

  List<String> _domainKeywords(String lower, String categoryId) {
    final categoryKeywords = switch (categoryId) {
      'politics' => <String>['政策动作', '监管口径', '机构表态', '执行范围'],
      'military' => <String>['军事行动', '防务部署', '冲突升级', '停火信号'],
      'history' => <String>['历史节点', '阶段演变', '关键人物', '制度变化'],
      'economy' => <String>['价格波动', '供需变化', '产业影响', '宏观指标'],
      'finance' => <String>['融资安排', '资本变化', '风险暴露', '市场反应'],
      'technology' => <String>['技术路线', '产品发布', '生态接入', '版本更新'],
      'society' => <String>['公共影响', '群体反馈', '处置进展', '舆情变化'],
      'international' => <String>['外交表态', '多边机制', '制裁变化', '区域影响'],
      'enterprise' => <String>['商业模式', '管理层回应', '核心资产', '经营变化'],
      'health' => <String>['临床进展', '审批节点', '安全信号', '服务覆盖'],
      'climate' => <String>['气候风险', '减排政策', '能源供给', '环境影响'],
      'culture' => <String>['作品发布', '传播反馈', '赛事节点', '行业反应'],
      _ => <String>[],
    };
    if (lower.contains('战争') || lower.contains('冲突')) {
      return _dedupeKeywords(<String>[
        ...categoryKeywords,
        '军事行动',
        '外交表态',
        '停火信号',
        '制裁变化',
      ]);
    }
    if (lower.contains('导弹')) {
      return _dedupeKeywords(<String>[
        ...categoryKeywords,
        '发射批次',
        '打击目标',
        '拦截结果',
        '防空系统',
      ]);
    }
    if (lower.contains('海峡') ||
        lower.contains('航运') ||
        lower.contains('油轮') ||
        lower.contains('邮轮')) {
      return _dedupeKeywords(<String>[
        ...categoryKeywords,
        '通航预警',
        '绕航安排',
        '保险费率',
        '船舶动态',
      ]);
    }
    if (lower.contains('融资') || lower.contains('重组') || lower.contains('裁员')) {
      return _dedupeKeywords(<String>[
        ...categoryKeywords,
        '债务安排',
        '股权变化',
        '核心资产',
        '管理层回应',
      ]);
    }
    if (lower.contains('发布') || lower.contains('上线') || lower.contains('开售')) {
      return _dedupeKeywords(<String>[
        ...categoryKeywords,
        '发布会',
        '试用反馈',
        '版本更新',
        '生态接入',
      ]);
    }
    if (lower.contains('供应链') || lower.contains('芯片')) {
      return _dedupeKeywords(<String>[
        ...categoryKeywords,
        '扩产计划',
        '交付周期',
        '价格波动',
        '政策补贴',
      ]);
    }
    return _dedupeKeywords(<String>[
      ...categoryKeywords,
      '关键动作',
      '确认信息',
      '影响范围',
      '阶段转折',
    ]);
  }

  List<String> _domainExcludedKeywords(String lower, String categoryId) {
    final categoryExcludedKeywords = switch (categoryId) {
      'politics' => <String>['无关党争评论', '泛政策解读'],
      'military' => <String>['武器百科', '无关军迷讨论'],
      'history' => <String>['野史传闻', '无出处考据'],
      'economy' => <String>['纯股价波动', '泛市场情绪'],
      'finance' => <String>['荐股内容', '短线喊单'],
      'technology' => <String>['参数堆砌', '无关测评'],
      'society' => <String>['地域攻击', '情绪对立'],
      'international' => <String>['泛地缘评论', '无关外交旧闻'],
      'enterprise' => <String>['行业八卦', '无关营销稿'],
      'health' => <String>['未经证实偏方', '医疗恐慌表达'],
      'climate' => <String>['泛环保口号', '无关天气闲谈'],
      'culture' => <String>['饭圈争吵', '无关八卦'],
      _ => <String>[],
    };
    if (lower.contains('战争') || lower.contains('冲突')) {
      return _dedupeKeywords(<String>[
        ...categoryExcludedKeywords,
        '泛地区评论',
        '无关股市波动',
        '历史泛谈',
      ]);
    }
    if (lower.contains('导弹')) {
      return _dedupeKeywords(<String>[
        ...categoryExcludedKeywords,
        '纯外交口水战',
        '无关航运消息',
        '武器百科',
      ]);
    }
    if (lower.contains('海峡') ||
        lower.contains('航运') ||
        lower.contains('油轮') ||
        lower.contains('邮轮')) {
      return _dedupeKeywords(<String>[
        ...categoryExcludedKeywords,
        '内陆战况',
        '无关装备参数',
        '泛油价评论',
      ]);
    }
    if (lower.contains('融资') || lower.contains('重组') || lower.contains('裁员')) {
      return _dedupeKeywords(<String>[
        ...categoryExcludedKeywords,
        '纯股价波动',
        '行业八卦',
        '泛市场评论',
      ]);
    }
    if (lower.contains('发布') || lower.contains('上线') || lower.contains('开售')) {
      return _dedupeKeywords(<String>[
        ...categoryExcludedKeywords,
        '旧版本回顾',
        '无关测评',
        '泛科技舆情',
      ]);
    }
    return _dedupeKeywords(<String>[
      ...categoryExcludedKeywords,
      '纯情绪表达',
      '无直接关联内容',
      '泛讨论',
    ]);
  }

  List<String> _dedupeKeywords(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }

  TopicDefinition _mergeDefinitionKeywords(
    TopicDefinition generated, {
    TopicDefinition? currentDefinition,
    TopicDefinition? removedDefinition,
  }) {
    final coreKeywords = _mergeKeywordBuckets(
      currentDefinition?.coreKeywords,
      generated.coreKeywords,
      removedDefinition?.coreKeywords,
      limit: 6,
    );
    final relatedKeywords = _mergeKeywordBuckets(
      currentDefinition?.relatedKeywords,
      generated.relatedKeywords,
      removedDefinition?.relatedKeywords,
      limit: 8,
    );
    final excludedKeywords = _mergeKeywordBuckets(
      currentDefinition?.excludedKeywords,
      generated.excludedKeywords,
      removedDefinition?.excludedKeywords,
      remove: <String>[...coreKeywords, ...relatedKeywords],
      limit: 6,
    );
    return TopicDefinition(
      overview: generated.overview,
      includeScope: generated.includeScope,
      excludeScope: generated.excludeScope,
      coreKeywords: coreKeywords,
      relatedKeywords: relatedKeywords,
      excludedKeywords: excludedKeywords,
      trackingDirection: currentDefinition?.trackingDirection.isNotEmpty == true
          ? currentDefinition!.trackingDirection
          : generated.trackingDirection,
      trackingQuestion: currentDefinition?.trackingQuestion.isNotEmpty == true
          ? currentDefinition!.trackingQuestion
          : generated.trackingQuestion,
      topicObject: currentDefinition?.topicObject.isNotEmpty == true
          ? currentDefinition!.topicObject
          : generated.topicObject,
      topicScope: currentDefinition?.topicScope.isNotEmpty == true
          ? currentDefinition!.topicScope
          : generated.topicScope,
      timelineType: currentDefinition?.timelineType.isNotEmpty == true
          ? currentDefinition!.timelineType
          : generated.timelineType,
      timelineFocus: currentDefinition?.timelineFocus.isNotEmpty == true
          ? currentDefinition!.timelineFocus
          : generated.timelineFocus,
      nodeSelectionPolicy:
          currentDefinition?.nodeSelectionPolicy.isNotEmpty == true
              ? currentDefinition!.nodeSelectionPolicy
              : generated.nodeSelectionPolicy,
      startDateConfidence:
          currentDefinition?.startDateConfidence.isNotEmpty == true
              ? currentDefinition!.startDateConfidence
              : generated.startDateConfidence,
      timelineTypeConfidence:
          currentDefinition?.timelineTypeConfidence.isNotEmpty == true
              ? currentDefinition!.timelineTypeConfidence
              : generated.timelineTypeConfidence,
      sourceEvidenceCount: currentDefinition != null &&
              currentDefinition.sourceEvidenceCount != 0
          ? currentDefinition.sourceEvidenceCount
          : generated.sourceEvidenceCount,
      recentActivityStatus: generated.recentActivityStatus,
      recentEvidenceCount: generated.recentEvidenceCount,
      latestRelevantSourceAt: generated.latestRelevantSourceAt,
      trackingViability: generated.trackingViability,
      trackingViabilityReason: generated.trackingViabilityReason,
    );
  }

  List<String> _mergeKeywordBuckets(
    List<String>? currentValues,
    List<String> generatedValues,
    List<String>? removedValues, {
    Iterable<String> remove = const <String>[],
    required int limit,
  }) {
    final blocked = <String>{
      ...remove.map((value) => value.trim()).where((value) => value.isNotEmpty),
      ...?removedValues
          ?.map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    };
    return _dedupeKeywords(<String>[
      ...?currentValues,
      ...generatedValues,
    ]).where((value) => !blocked.contains(value)).take(limit).toList();
  }
}
