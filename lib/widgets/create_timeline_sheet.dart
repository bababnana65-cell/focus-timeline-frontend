import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/interest_category.dart';
import '../models/timeline_creation_models.dart';
import '../models/timeline_models.dart';
import '../services/timeline_controller.dart';
import '../theme/app_theme.dart';
import 'app_feedback.dart';

const List<String> _timelineCreationQuotes = <String>[
  '时间不回答问题，它只保留证据。',
  '所有突然，都是长期的结果。',
  '过去没有消失，它只是换了一种方式影响现在。',
  '事件的真相，常藏在顺序里。',
  '因果不是一条直线，而是一片缓慢显影的网。',
  '时间让噪声沉下去，也让线索浮上来。',
  '人们常记得结局，却忘了结局如何形成。',
  '每个节点都是片段，连接起来才成为判断。',
  '历史不是远方，它每天都在更新。',
  '未来最早的样子，往往藏在今天的小变化里。',
  '理解一个事件，就是理解它的时间结构。',
  '时间会淘汰情绪，留下脉络。',
  '不是所有变化都有预告，但所有变化都有路径。',
  '重要的事，很少孤立发生。',
  '当下只是一个截面，时间线才是全貌。',
  '事件不会凭空出现，它们从旧问题里长出来。',
  '节点记录事实，顺序接近真相。',
  '看见前因，才能少被后果惊动。',
  '时间让复杂变得可读。',
  '追踪不是执着过去，而是校准现在。',
  '信息告诉你发生了什么，时间告诉你为什么这样发生。',
  '没有脉络的事实，容易变成误解。',
  '很多判断的错误，不在信息少，而在顺序乱。',
  '时间线的意义，是让混乱重新拥有方向。',
  '所谓洞察，就是在变化发生前，看见它已经开始。',
  '趋势不是预言，是连续节点给出的暗示。',
  '每一次更新，都是事件在改变自己的形状。',
  '时间把个别事件，慢慢写成共同处境。',
  '真正值得关注的，不是热闹，而是转折。',
  '节点越多，越要相信结构，而不是情绪。',
  '只有把事件放回时间，才能看清它的重量。',
  '重要节点不是终点，而是意义改变的地方。',
  '一件事的开端，常常比它被看见时更早。',
  '历史并非过去完成时，它常常是现在进行时。',
  '时间不会让所有事变清楚，但会让伪装变薄。',
  '追踪时间，是为了在变化中保留判断力。',
  '当世界变快，脉络就是稀缺品。',
  '时间线不是为了记住一切，而是为了不忘关键。',
  '在时间面前，碎片会归位，因果会显影。',
  '越复杂的事件，越需要慢慢看。',
  '真相有时不是一句话，而是一段过程。',
  '世界以新闻的形式出现，以时间线的形式被理解。',
  '热点会过去，脉络会留下。',
  '节点是事实的坐标，时间线是判断的地图。',
  '只有连续地看，才能看见真正的变化。',
  '事件的深处，不是结论，而是演化。',
  '许多答案，不在最新消息里，而在最早的伏笔里。',
  '时间让微小信号拥有解释力。',
  '在变化尚未命名之前，它已经开始发生。',
  '看清一个事件，需要给它足够的时间。',
  '时间不是答案，线索才是。',
  '所有变化，都有来处。',
  '看见顺序，才看见因果。',
  '事件不会突然发生，它只是终于显现。',
  '时间线不是记录过去，而是理解现在。',
  '真相常常不在某个节点，而在节点之间。',
  '重要的不是发生了什么，而是它如何一步步发生。',
  '每一个今天，都是昨天埋下的伏笔。',
  '追踪时间，是为了不被时间推着走。',
  '当信息太碎，时间线让它重新成形。',
  '人只能活在当下，却总要借过去理解当下。',
  '时间把偶然变成历史，把历史变成解释。',
  '未来不是突然到来，它沿着每一个节点靠近。',
  '所谓趋势，就是时间替混乱写出的秩序。',
  '记忆是个人的时间线，历史是众人的时间线。',
  '一个事件的意义，往往要等后来的节点来解释。',
  '时间从不说明什么，但它留下证据。',
  '线索越完整，判断越克制。',
  '看见时间的结构，就不容易被瞬间的情绪带走。',
  '每个节点都很小，但连起来就是时代的形状。',
];

const String _lowEvidenceDirectionMessage = '暂无足够真实来源，建议补充关键词后再生成时间线。';

bool _needsMoreEvidence(TimelineDirectionCandidate candidate) {
  if (candidate.recentEvidenceCount > 0) {
    return false;
  }
  final viability = candidate.trackingViability.trim().toLowerCase();
  return viability.isEmpty || viability == 'low' || viability == 'unknown';
}

Future<Topic?> showCreateTimelineSheet(
  BuildContext context,
  TimelineController controller, {
  bool expanded = false,
}) {
  return showModalBottomSheet<Topic>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    barrierColor: AppTheme.textSecondary.withValues(alpha: 0.20),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusSheet),
      ),
    ),
    builder: (context) {
      final sheet = _CreateTimelineSheet(controller: controller);
      if (!expanded) {
        return sheet;
      }
      return FractionallySizedBox(
        heightFactor: 0.96,
        child: sheet,
      );
    },
  );
}

class _CreateTimelineSheet extends StatefulWidget {
  const _CreateTimelineSheet({
    required this.controller,
  });

  final TimelineController controller;

  @override
  State<_CreateTimelineSheet> createState() => _CreateTimelineSheetState();
}

class _CreateTimelineSheetState extends State<_CreateTimelineSheet> {
  late final TextEditingController _keywordsController;
  TimelineDraft? _draft;
  List<TimelineDirectionCandidate> _directionCandidates =
      <TimelineDirectionCandidate>[];
  TimelineDirectionCandidate? _selectedDirection;
  String? _categoryId;
  bool _categoryLockedByUser = false;
  String? _errorText;
  bool _isCreating = false;
  bool _pendingCreateAfterLogin = false;
  TimelineExpansionProgress? _expansionProgress;
  TimelineExpansionProgress? _localExpansionProgress;
  late int _observedDeferredCreateResultToken;
  String _lastExpandedKeywordInput = '';
  List<String> _coreKeywords = <String>[];
  List<String> _relatedKeywords = <String>[];
  List<String> _excludedKeywords = <String>[];
  final Set<String> _removedCoreKeywords = <String>{};
  final Set<String> _removedRelatedKeywords = <String>{};
  final Set<String> _removedExcludedKeywords = <String>{};
  final Random _quoteRandom = Random();
  final List<int> _recentQuoteIndexes = <int>[];
  int _quoteIndex = -1;

  @override
  void initState() {
    super.initState();
    _advanceQuote();
    _keywordsController = TextEditingController();
    _keywordsController.addListener(_handleKeywordsChanged);
    _observedDeferredCreateResultToken =
        widget.controller.deferredTimelineCreationResultToken;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    if (_pendingCreateAfterLogin && !widget.controller.isRegistered) {
      widget.controller.discardDeferredTimelineCreation();
    }
    widget.controller.removeListener(_handleControllerChanged);
    _keywordsController.removeListener(_handleKeywordsChanged);
    _keywordsController.dispose();
    super.dispose();
  }

  String get _currentQuote =>
      _timelineCreationQuotes[_quoteIndex < 0 ? 0 : _quoteIndex];

  bool get _hasAiExpandedContent =>
      _draft != null ||
      _directionCandidates.isNotEmpty ||
      _selectedDirection != null ||
      _lastExpandedKeywordInput.isNotEmpty;

  String _aiExpandButtonLabel(TimelineController controller) {
    if (controller.isGeneratingTimelineDraft) {
      return '扩写中';
    }
    return _hasAiExpandedContent ? 'AI 再次扩写' : 'AI 扩写';
  }

  void _advanceQuote() {
    final blocked = _recentQuoteIndexes.toSet();
    var candidates = <int>[
      for (var index = 0; index < _timelineCreationQuotes.length; index++)
        if (!blocked.contains(index)) index,
    ];
    if (candidates.isEmpty) {
      candidates = <int>[
        for (var index = 0; index < _timelineCreationQuotes.length; index++)
          if (index != _quoteIndex) index,
      ];
    }
    final nextIndex = candidates[_quoteRandom.nextInt(candidates.length)];
    _quoteIndex = nextIndex;
    _recentQuoteIndexes.add(nextIndex);
    if (_recentQuoteIndexes.length > 10) {
      _recentQuoteIndexes.removeAt(0);
    }
  }

  TimelineExpansionProgress _directionSearchProgressFor(String keywords) {
    final focus = _displayFocus(keywords);
    final categoryLabel = _categoryLockedByUser && _categoryId != null
        ? interestCategoryById(_categoryId!).label
        : '';
    return TimelineExpansionProgress(
      status: 'searching',
      stage: '正在检索时间轴线索',
      items: <TimelineExpansionProgressItem>[
        TimelineExpansionProgressItem(
          title: '“$focus”起点：首次爆发、官方表态、关键时间',
        ),
        TimelineExpansionProgressItem(
          title: '“$focus”过程：现场处置、调查进展、责任认定',
        ),
        TimelineExpansionProgressItem(
          title: '“$focus”影响：后续影响、结果变化、相关回应',
        ),
        if (categoryLabel.isNotEmpty)
          TimelineExpansionProgressItem(
            title: '“$focus”限定在“$categoryLabel”：只保留匹配节点',
          ),
        const TimelineExpansionProgressItem(
          title: '候选方向：按起点、过程和影响拆成 2-3 条时间线',
        ),
      ],
    );
  }

  TimelineExpansionProgress _directionCandidateProgressFor(
    List<TimelineDirectionCandidate> candidates,
  ) {
    final items = candidates
        .map((candidate) {
          final title = candidate.trackingDirection.trim().isNotEmpty
              ? candidate.trackingDirection.trim()
              : candidate.topicScope.trim().isNotEmpty
                  ? candidate.topicScope.trim()
                  : candidate.title.trim();
          if (title.isEmpty) {
            return null;
          }
          return TimelineExpansionProgressItem(
            title: title,
            date: candidate.latestRelevantSourceAt,
          );
        })
        .whereType<TimelineExpansionProgressItem>()
        .toList(growable: false);
    return TimelineExpansionProgress(
      status: 'ready',
      stage: '已找到可生成方向',
      items: items.isEmpty
          ? const <TimelineExpansionProgressItem>[
              TimelineExpansionProgressItem(
                title: '点选下方方向后，将直接创建正式时间线',
              ),
            ]
          : items,
    );
  }

  TimelineExpansionProgress _draftExpansionProgressFor(
    String keywords, {
    required bool categoryRecast,
    TimelineDirectionCandidate? selectedDirection,
  }) {
    final focus = _displayFocus(keywords);
    final categoryLabel =
        _categoryId == null ? '' : interestCategoryById(_categoryId!).label;
    if (categoryRecast) {
      return TimelineExpansionProgress(
        status: 'generating',
        stage: '正在按类别重算',
        items: <TimelineExpansionProgressItem>[
          if (categoryLabel.isNotEmpty)
            TimelineExpansionProgressItem(
              title: '按“$categoryLabel”重新整理专题方向',
            ),
          const TimelineExpansionProgressItem(
            title: '只保留核心关键词，重算简介、起点和关键词边界',
          ),
          if (_draft?.trackingDirection.trim().isNotEmpty == true)
            TimelineExpansionProgressItem(
              title: _draft!.trackingDirection.trim(),
            ),
        ],
      );
    }

    if (selectedDirection != null) {
      return TimelineExpansionProgress(
        status: 'generating',
        stage: '正在生成专题草案',
        items: <TimelineExpansionProgressItem>[
          TimelineExpansionProgressItem(
            title: selectedDirection.trackingDirection.trim().isEmpty
                ? '按已选择方向生成专题草案'
                : selectedDirection.trackingDirection.trim(),
          ),
          if (selectedDirection.topicScope.trim().isNotEmpty)
            TimelineExpansionProgressItem(
              title: selectedDirection.topicScope.trim(),
            ),
          const TimelineExpansionProgressItem(
            title: '生成标题、简介、建议起点和关键词边界',
          ),
        ],
      );
    }

    final currentDirection = _draft?.trackingDirection.trim() ?? '';
    return TimelineExpansionProgress(
      status: 'generating',
      stage: _hasAiExpandedContent ? '正在再次扩写' : '正在生成专题草案',
      items: <TimelineExpansionProgressItem>[
        TimelineExpansionProgressItem(
          title: _hasAiExpandedContent
              ? '结合当前核心、已纳入和已排除关键词重新整理'
              : '围绕“$focus”整理专题方向和简介',
        ),
        if (categoryLabel.isNotEmpty)
          TimelineExpansionProgressItem(
            title: '保持“$categoryLabel”类别约束，重新校准内容',
          ),
        if (currentDirection.isNotEmpty)
          TimelineExpansionProgressItem(title: currentDirection),
        const TimelineExpansionProgressItem(
          title: '生成标题、简介、建议起点和关键词边界',
        ),
      ],
    );
  }

  TimelineExpansionProgress _mergeProgressWithLocalContext(
    TimelineExpansionProgress incoming,
    TimelineExpansionProgress? local,
  ) {
    if (local == null || local.items.isEmpty) {
      return incoming;
    }
    final seen = <String>{};
    final items = <TimelineExpansionProgressItem>[];
    for (final item in <TimelineExpansionProgressItem>[
      ...local.items,
      ...incoming.items,
    ]) {
      final title = item.title.trim();
      if (title.isEmpty || !seen.add(title)) {
        continue;
      }
      items.add(item);
    }
    return TimelineExpansionProgress(
      status: incoming.status,
      stage: incoming.stage.trim().isEmpty ? local.stage : incoming.stage,
      items: items,
    );
  }

  String _displayFocus(String keywords) {
    final normalized = keywords.trim();
    if (normalized.isEmpty) {
      return '当前关键词';
    }
    return normalized.length > 18
        ? '${normalized.substring(0, 18)}...'
        : normalized;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final activeProgress = _expansionProgress ?? _localExpansionProgress;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textPrimary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'NEW TIMELINE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textTertiary,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '创建时间轴',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentQuote,
                  key: const ValueKey<String>('create-timeline-quote'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                        height: 1.38,
                      ),
                ),
                const SizedBox(height: 14),
                Container(
                  constraints: const BoxConstraints(minHeight: 72),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(top: 22),
                        width: 1,
                        height: 22,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'KEYWORD',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppTheme.textTertiary,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _keywordsController,
                              minLines: 1,
                              maxLines: 2,
                              cursorColor: AppTheme.accent,
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                hintText: controller.createTimelineKeywordHint,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorText != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _errorText!,
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.isGeneratingTimelineDraft || _isCreating
                      ? null
                      : _generateDraft,
                  icon: _isCreating
                      ? const Icon(Icons.hourglass_top_rounded)
                      : controller.isGeneratingTimelineDraft
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentStrong,
                              ),
                            )
                          : const Icon(Icons.auto_fix_high_rounded),
                  label: Text(
                    _isCreating ? '创建中' : _aiExpandButtonLabel(controller),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: EdgeInsets.zero,
                    backgroundColor: AppTheme.accentSoft,
                    foregroundColor: AppTheme.accentStrong,
                  ),
                ),
                if (activeProgress != null &&
                    (controller.isGeneratingTimelineDraft ||
                        _directionCandidates.isNotEmpty ||
                        _isCreating)) ...<Widget>[
                  const SizedBox(height: 12),
                  _AiProgressClueTicker(
                    progress: activeProgress,
                  ),
                ],
                if (_directionCandidates.isNotEmpty && _draft == null) ...[
                  const SizedBox(height: 18),
                  _DirectionCandidatesPanel(
                    candidates: _directionCandidates,
                    onSelected: _selectDirectionCandidate,
                  ),
                ],
                if (_draft != null) ...<Widget>[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: AppTheme.shadow,
                          blurRadius: 30,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _draft!.topicName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    height: 1.18,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _draft!.tagline,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.45,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _CategoryPill(
                              category: interestCategoryById(
                                _categoryId ?? _draft!.categoryId,
                              ),
                              locked: _categoryLockedByUser,
                              onTap: _pickCategory,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_draft!.trackingDirection.trim().isNotEmpty) ...[
                          _TrackingDirectionNote(
                            text: _draft!.trackingDirection.trim(),
                            lowConfidence: _isLowConfidenceDraft(_draft!),
                            recentActivityStatus: _draft!.recentActivityStatus,
                            trackingViability: _draft!.trackingViability,
                            trackingViabilityReason:
                                _draft!.trackingViabilityReason,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _StartDateSuggestion(date: _draft!.startDate),
                        const SizedBox(height: 12),
                        Text(
                          _draft!.summary,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        _EditableKeywordGroup(
                          title: '核心关键词',
                          tone: AppTheme.accent,
                          values: _coreKeywords,
                          onAdd: () => _promptAddKeyword(
                            '核心关键词',
                            _coreKeywords,
                            _removedCoreKeywords,
                          ),
                          onRemove: (value) {
                            _removeKeyword(
                              value,
                              _coreKeywords,
                              _removedCoreKeywords,
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _EditableKeywordGroup(
                          title: '已纳入扩展关键词',
                          tone: AppTheme.accentMuted,
                          values: _relatedKeywords,
                          onAdd: () => _promptAddKeyword(
                            '已纳入扩展关键词',
                            _relatedKeywords,
                            _removedRelatedKeywords,
                          ),
                          onRemove: (value) {
                            _removeKeyword(
                              value,
                              _relatedKeywords,
                              _removedRelatedKeywords,
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _EditableKeywordGroup(
                          title: '已排除关键词',
                          tone: AppTheme.danger,
                          values: _excludedKeywords,
                          onAdd: () => _promptAddKeyword(
                            '已排除关键词',
                            _excludedKeywords,
                            _removedExcludedKeywords,
                          ),
                          onRemove: (value) {
                            _removeKeyword(
                              value,
                              _excludedKeywords,
                              _removedExcludedKeywords,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateDraft({bool categoryRecast = false}) async {
    if (categoryRecast) {
      await _expandDraft(categoryRecast: true);
      return;
    }

    final keywords = _keywordsController.text.trim();
    if (keywords.isEmpty) {
      setState(() {
        _errorText = '请先输入关键词。';
      });
      return;
    }

    setState(() {
      _advanceQuote();
      _errorText = null;
      _expansionProgress = null;
      _localExpansionProgress = _directionSearchProgressFor(keywords);
      _draft = null;
      _selectedDirection = null;
      _directionCandidates = <TimelineDirectionCandidate>[];
    });

    try {
      final candidates = await widget.controller.suggestTimelineDirections(
        keywords,
        categoryHint: _categoryLockedByUser ? _categoryId : null,
      );
      if (!mounted || _keywordsController.text.trim() != keywords) {
        return;
      }
      if (candidates.isNotEmpty) {
        final ordered = List<TimelineDirectionCandidate>.from(candidates)
          ..sort((a, b) {
            if (a.isRecommended == b.isRecommended) {
              return 0;
            }
            return a.isRecommended ? -1 : 1;
          });
        final visibleCandidates = ordered.take(3).toList(growable: false);
        setState(() {
          _localExpansionProgress =
              _directionCandidateProgressFor(visibleCandidates);
          _directionCandidates = visibleCandidates;
        });
        return;
      }
    } catch (_) {
      if (!mounted || _keywordsController.text.trim() != keywords) {
        return;
      }
    }

    if (mounted) {
      setState(() {});
    }
    await _expandDraft(refreshQuote: false);
  }

  Future<void> _expandDraft({
    bool categoryRecast = false,
    TimelineDirectionCandidate? selectedDirection,
    bool refreshQuote = true,
  }) async {
    final keywords = _keywordsController.text.trim();
    if (keywords.isEmpty) {
      setState(() {
        _errorText = '请先输入关键词。';
      });
      return;
    }

    setState(() {
      if (refreshQuote) {
        _advanceQuote();
      }
      _errorText = null;
      _expansionProgress = null;
      _localExpansionProgress = _draftExpansionProgressFor(
        keywords,
        categoryRecast: categoryRecast,
        selectedDirection: selectedDirection,
      );
      if (selectedDirection != null || categoryRecast) {
        _draft = null;
      }
    });

    try {
      final currentDefinition =
          _currentDefinitionForExpansion(coreOnly: categoryRecast);
      final removedDefinition =
          _removedDefinitionForExpansion(coreOnly: categoryRecast);
      final previousCoreKeywords = List<String>.from(_coreKeywords);
      final previousRelatedKeywords =
          categoryRecast ? <String>[] : List<String>.from(_relatedKeywords);
      final previousExcludedKeywords =
          categoryRecast ? <String>[] : List<String>.from(_excludedKeywords);
      final removedRelatedKeywords =
          categoryRecast ? <String>{} : _removedRelatedKeywords;
      final removedExcludedKeywords =
          categoryRecast ? <String>{} : _removedExcludedKeywords;
      final draft = await widget.controller.expandTimelineKeywords(
        keywords,
        categoryHint: _categoryLockedByUser ? _categoryId : null,
        selectedDirection: selectedDirection,
        currentDefinition: currentDefinition,
        removedDefinition: removedDefinition,
        onProgress: (progress) {
          if (!mounted || _keywordsController.text.trim() != keywords) {
            return;
          }
          setState(() {
            _expansionProgress = _mergeProgressWithLocalContext(
              progress,
              _localExpansionProgress,
            );
          });
        },
      );
      if (!mounted) {
        return;
      }
      if (_keywordsController.text.trim() != keywords) {
        return;
      }
      setState(() {
        final mergedCoreKeywords = _mergeKeywordLists(
          previousCoreKeywords,
          draft.definition.coreKeywords,
          _removedCoreKeywords,
          limit: 6,
        );
        final mergedRelatedKeywords = _mergeKeywordLists(
          previousRelatedKeywords,
          draft.definition.relatedKeywords,
          removedRelatedKeywords,
          remove: mergedCoreKeywords,
          limit: 8,
        );
        final mergedExcludedKeywords = _mergeKeywordLists(
          previousExcludedKeywords,
          draft.definition.excludedKeywords,
          removedExcludedKeywords,
          remove: <String>[...mergedCoreKeywords, ...mergedRelatedKeywords],
          limit: 6,
        );
        final mergedDefinition = TopicDefinition(
          overview: draft.definition.overview,
          includeScope: draft.definition.includeScope,
          excludeScope: draft.definition.excludeScope,
          coreKeywords: mergedCoreKeywords,
          relatedKeywords: mergedRelatedKeywords,
          excludedKeywords: mergedExcludedKeywords,
          trackingDirection: draft.trackingDirection,
          trackingQuestion: draft.trackingQuestion,
          topicObject: draft.topicObject,
          topicScope: draft.topicScope,
          timelineType: draft.timelineType,
          timelineFocus: draft.timelineFocus,
          nodeSelectionPolicy: draft.nodeSelectionPolicy,
          startDateConfidence: draft.startDateConfidence,
          timelineTypeConfidence: draft.timelineTypeConfidence,
          sourceEvidenceCount: draft.sourceEvidenceCount,
          recentActivityStatus: draft.recentActivityStatus,
          recentEvidenceCount: draft.recentEvidenceCount,
          latestRelevantSourceAt: draft.latestRelevantSourceAt,
          trackingViability: draft.trackingViability,
          trackingViabilityReason: draft.trackingViabilityReason,
        );
        _draft = TimelineDraft(
          keywords: draft.keywords,
          topicName: draft.topicName,
          tagline: draft.tagline,
          summary: draft.summary,
          categoryId: draft.categoryId,
          definition: mergedDefinition,
          trackingDirection: draft.trackingDirection,
          trackingQuestion: draft.trackingQuestion,
          topicObject: draft.topicObject,
          topicScope: draft.topicScope,
          timelineType: draft.timelineType,
          timelineFocus: draft.timelineFocus,
          nodeSelectionPolicy: draft.nodeSelectionPolicy,
          startDateConfidence: draft.startDateConfidence,
          timelineTypeConfidence: draft.timelineTypeConfidence,
          sourceEvidenceCount: draft.sourceEvidenceCount,
          recentActivityStatus: draft.recentActivityStatus,
          recentEvidenceCount: draft.recentEvidenceCount,
          latestRelevantSourceAt: draft.latestRelevantSourceAt,
          trackingViability: draft.trackingViability,
          trackingViabilityReason: draft.trackingViabilityReason,
          seedEntries: draft.seedEntries,
        );
        _selectedDirection = selectedDirection;
        _directionCandidates = <TimelineDirectionCandidate>[];
        _lastExpandedKeywordInput = keywords;
        _expansionProgress = null;
        _localExpansionProgress = null;
        if (!_categoryLockedByUser) {
          _categoryId = draft.categoryId;
        }
        _coreKeywords = List<String>.from(mergedDefinition.coreKeywords);
        _relatedKeywords = List<String>.from(mergedDefinition.relatedKeywords);
        _excludedKeywords =
            List<String>.from(mergedDefinition.excludedKeywords);
        if (categoryRecast) {
          _removedRelatedKeywords.clear();
          _removedExcludedKeywords.clear();
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = '$error';
        _expansionProgress = null;
        _localExpansionProgress = null;
      });
    }
  }

  Future<void> _selectDirectionCandidate(
    TimelineDirectionCandidate candidate,
  ) async {
    final keywords = _keywordsController.text.trim();
    if (keywords.isEmpty || _isCreating) {
      return;
    }
    setState(() {
      _selectedDirection = candidate;
      _errorText = null;
      _isCreating = true;
      _localExpansionProgress = TimelineExpansionProgress(
        status: 'creating',
        stage: '正在创建时间线',
        items: <TimelineExpansionProgressItem>[
          TimelineExpansionProgressItem(
            title: candidate.trackingDirection.trim().isEmpty
                ? candidate.title.trim()
                : candidate.trackingDirection.trim(),
            date: candidate.latestRelevantSourceAt,
          ),
        ],
      );
    });
    try {
      final topic = await widget.controller.createTimelineFromDirection(
        keywords: keywords,
        candidate: candidate,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(topic);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final normalizedError = '$error'.replaceFirst('Exception: ', '');
      final mappedError = _mapCreateErrorMessage(normalizedError);
      final shouldResumeAfterLogin = widget.controller.isGuest &&
          widget.controller.pendingLoginPromptReason != null;
      setState(() {
        _pendingCreateAfterLogin = shouldResumeAfterLogin;
        _errorText =
            shouldResumeAfterLogin ? '登录成功后，将自动继续创建这个专题。' : mappedError;
        _expansionProgress = null;
        _localExpansionProgress = null;
      });
      if (shouldResumeAfterLogin) {
        widget.controller.queueDeferredTimelineCreationFromDirection(
          keywords: keywords,
          candidate: candidate,
        );
      } else {
        widget.controller.showError(mappedError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _handleKeywordsChanged() {
    final normalized = _keywordsController.text.trim();
    if (normalized == _lastExpandedKeywordInput) {
      return;
    }

    final hasDraftState = _draft != null ||
        _directionCandidates.isNotEmpty ||
        _selectedDirection != null ||
        _coreKeywords.isNotEmpty ||
        _relatedKeywords.isNotEmpty ||
        _excludedKeywords.isNotEmpty ||
        _removedCoreKeywords.isNotEmpty ||
        _removedRelatedKeywords.isNotEmpty ||
        _removedExcludedKeywords.isNotEmpty ||
        _categoryLockedByUser ||
        _categoryId != null;
    if (!hasDraftState) {
      return;
    }

    setState(() {
      _draft = null;
      _directionCandidates = <TimelineDirectionCandidate>[];
      _selectedDirection = null;
      _categoryId = null;
      _categoryLockedByUser = false;
      _errorText = null;
      _expansionProgress = null;
      _localExpansionProgress = null;
      _lastExpandedKeywordInput = '';
      _coreKeywords = <String>[];
      _relatedKeywords = <String>[];
      _excludedKeywords = <String>[];
      _removedCoreKeywords.clear();
      _removedRelatedKeywords.clear();
      _removedExcludedKeywords.clear();
    });
  }

  bool _isLowConfidenceDraft(TimelineDraft draft) {
    return draft.startDateConfidence == 'low' ||
        draft.timelineTypeConfidence == 'low' ||
        draft.sourceEvidenceCount == 0;
  }

  String _mapCreateErrorMessage(String raw) {
    if (raw.contains('TOPIC_DIRECTION_NOT_INITIALIZABLE')) {
      return _lowEvidenceDirectionMessage;
    }
    if (raw.contains('TOPIC_INITIALIZATION_ALREADY_RUNNING')) {
      return '这个专题已经在生成中，请稍后打开时间线查看。';
    }
    if (raw.contains('TOPIC_CREATE_RATE_LIMITED')) {
      return '创建专题失败：服务端仍返回创建频率限制，请确认后端已取消创建专题数量限制。';
    }
    return raw;
  }

  Future<void> _pickCategory() async {
    final selectedId = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择所属类别'),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interestCategories
                  .map(
                    (category) => _CategoryChoiceChip(
                      category: category,
                      selected:
                          category.id == (_categoryId ?? _draft?.categoryId),
                      onSelected: () {
                        Navigator.of(context).pop(category.id);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );

    if (selectedId == null || !mounted) {
      return;
    }

    final previousCategoryId = _categoryId ?? _draft?.categoryId;
    final shouldRecast = selectedId != previousCategoryId &&
        _draft != null &&
        _keywordsController.text.trim().isNotEmpty &&
        !widget.controller.isGeneratingTimelineDraft &&
        !_isCreating;

    setState(() {
      _categoryId = selectedId;
      _categoryLockedByUser = true;
      if (!shouldRecast) {
        _advanceQuote();
      }
    });

    if (shouldRecast) {
      await _generateDraft(categoryRecast: true);
    }
  }

  Future<void> _promptAddKeyword(
    String title,
    List<String> bucket,
    Set<String> removedBucket,
  ) async {
    final value = await showAppTextInputDialog(
      context,
      title: '新增$title',
      hintText: '输入一个关键词',
      confirmLabel: '增加',
    );

    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty || bucket.contains(normalized) || !mounted) {
      return;
    }

    setState(() {
      removedBucket.remove(normalized);
      bucket.add(normalized);
    });
  }

  void _removeKeyword(
    String value,
    List<String> bucket,
    Set<String> removedBucket,
  ) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }
    setState(() {
      bucket.remove(normalized);
      removedBucket.add(normalized);
    });
  }

  TopicDefinition? _currentDefinitionForExpansion({bool coreOnly = false}) {
    final draftDefinition = _draft?.definition;
    if (draftDefinition == null &&
        _coreKeywords.isEmpty &&
        (coreOnly || (_relatedKeywords.isEmpty && _excludedKeywords.isEmpty))) {
      return null;
    }
    return TopicDefinition(
      overview: draftDefinition?.overview ?? '',
      includeScope: draftDefinition?.includeScope ?? '',
      excludeScope: draftDefinition?.excludeScope ?? '',
      coreKeywords: List<String>.from(_coreKeywords),
      relatedKeywords:
          coreOnly ? const <String>[] : List<String>.from(_relatedKeywords),
      excludedKeywords:
          coreOnly ? const <String>[] : List<String>.from(_excludedKeywords),
      trackingDirection:
          coreOnly ? '' : draftDefinition?.trackingDirection ?? '',
      trackingQuestion: coreOnly ? '' : draftDefinition?.trackingQuestion ?? '',
      topicObject: coreOnly ? '' : draftDefinition?.topicObject ?? '',
      topicScope: coreOnly ? '' : draftDefinition?.topicScope ?? '',
      timelineType: coreOnly ? '' : draftDefinition?.timelineType ?? '',
      timelineFocus: coreOnly ? '' : draftDefinition?.timelineFocus ?? '',
      nodeSelectionPolicy: coreOnly
          ? const <String, List<String>>{}
          : draftDefinition?.nodeSelectionPolicy ??
              const <String, List<String>>{},
      startDateConfidence:
          coreOnly ? '' : draftDefinition?.startDateConfidence ?? '',
      timelineTypeConfidence:
          coreOnly ? '' : draftDefinition?.timelineTypeConfidence ?? '',
      sourceEvidenceCount:
          coreOnly ? 0 : draftDefinition?.sourceEvidenceCount ?? 0,
      recentActivityStatus: coreOnly
          ? 'unknown'
          : draftDefinition?.recentActivityStatus ?? 'unknown',
      recentEvidenceCount:
          coreOnly ? 0 : draftDefinition?.recentEvidenceCount ?? 0,
      latestRelevantSourceAt:
          coreOnly ? null : draftDefinition?.latestRelevantSourceAt,
      trackingViability:
          coreOnly ? 'low' : draftDefinition?.trackingViability ?? 'low',
      trackingViabilityReason:
          coreOnly ? '' : draftDefinition?.trackingViabilityReason ?? '',
    );
  }

  TopicDefinition? _removedDefinitionForExpansion({bool coreOnly = false}) {
    if (_removedCoreKeywords.isEmpty &&
        (coreOnly ||
            (_removedRelatedKeywords.isEmpty &&
                _removedExcludedKeywords.isEmpty))) {
      return null;
    }
    return TopicDefinition(
      overview: '',
      includeScope: '',
      excludeScope: '',
      coreKeywords: _removedCoreKeywords.toList(growable: false),
      relatedKeywords: coreOnly
          ? const <String>[]
          : _removedRelatedKeywords.toList(growable: false),
      excludedKeywords: coreOnly
          ? const <String>[]
          : _removedExcludedKeywords.toList(growable: false),
    );
  }

  List<String> _mergeKeywordLists(
    List<String> currentValues,
    List<String> generatedValues,
    Set<String> removedValues, {
    Iterable<String> remove = const <String>[],
    required int limit,
  }) {
    final blocked = <String>{
      ...removedValues,
      ...remove.map((value) => value.trim()).where((value) => value.isNotEmpty),
    };
    final seen = <String>{};
    final merged = <String>[];
    for (final value in <String>[...currentValues, ...generatedValues]) {
      final normalized = value.trim();
      if (normalized.isEmpty ||
          blocked.contains(normalized) ||
          !seen.add(normalized)) {
        continue;
      }
      merged.add(normalized);
      if (merged.length >= limit) {
        break;
      }
    }
    return merged;
  }

  void _handleControllerChanged() {
    final resultToken = widget.controller.deferredTimelineCreationResultToken;
    if (!_pendingCreateAfterLogin ||
        resultToken == _observedDeferredCreateResultToken) {
      return;
    }
    _observedDeferredCreateResultToken = resultToken;
    final createdTopic = widget.controller.deferredTimelineCreationResultTopic;
    final deferredError =
        widget.controller.deferredTimelineCreationErrorMessage;
    if (createdTopic != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(createdTopic);
      });
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingCreateAfterLogin = false;
      _errorText = deferredError ?? _errorText;
    });
  }
}

class _DirectionCandidatesPanel extends StatelessWidget {
  const _DirectionCandidatesPanel({
    required this.candidates,
    required this.onSelected,
  });

  final List<TimelineDirectionCandidate> candidates;
  final ValueChanged<TimelineDirectionCandidate> onSelected;

  @override
  Widget build(BuildContext context) {
    final hasCreatableDirection =
        candidates.any((candidate) => !_needsMoreEvidence(candidate));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppTheme.shadow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'AI 建议追踪方向',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            hasCreatableDirection
                ? '点选方向后会直接生成时间线。'
                : '这些方向暂缺真实来源，建议换一个更具体的关键词。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          ...candidates.map(
            (candidate) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DirectionCandidateCard(
                candidate: candidate,
                onTap: () => onSelected(candidate),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionCandidateCard extends StatelessWidget {
  const _DirectionCandidateCard({
    required this.candidate,
    required this.onTap,
  });

  final TimelineDirectionCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = interestCategoryById(candidate.categoryId);
    final needsMoreEvidence = _needsMoreEvidence(candidate);
    final statusText = switch (candidate.recentActivityStatus) {
      'active' => '近期仍有更新',
      'quiet' => '近期更新较少',
      _ => '证据不足',
    };
    final latestText = candidate.latestRelevantSourceAt == null
        ? ''
        : ' · 最近依据 ${candidate.latestRelevantSourceAt!.month}月${candidate.latestRelevantSourceAt!.day}日';

    return Material(
      color: AppTheme.surfaceMuted.withValues(
        alpha: needsMoreEvidence ? 0.48 : 0.72,
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusControl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      candidate.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                    ),
                  ),
                  if (candidate.isRecommended) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentSoft,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: const Text(
                        '推荐',
                        style: TextStyle(
                          color: AppTheme.accentStrong,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 7),
              Text(
                candidate.trackingDirection,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  _MiniMetaPill(text: category.label),
                  _MiniMetaPill(text: statusText),
                  if (needsMoreEvidence) const _MiniMetaPill(text: '暂无足够来源'),
                  if (latestText.isNotEmpty) _MiniMetaPill(text: latestText),
                ],
              ),
              if (candidate.reason.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  candidate.reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetaPill extends StatelessWidget {
  const _MiniMetaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.72)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _AiProgressClueTicker extends StatefulWidget {
  const _AiProgressClueTicker({required this.progress});

  final TimelineExpansionProgress progress;

  @override
  State<_AiProgressClueTicker> createState() => _AiProgressClueTickerState();
}

class _AiProgressClueTickerState extends State<_AiProgressClueTicker> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _AiProgressClueTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameItems(oldWidget.progress.items, widget.progress.items)) {
      _index = 0;
      _syncTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.progress.items;
    final isWorking = widget.progress.status == 'searching' ||
        widget.progress.status == 'generating' ||
        widget.progress.status == 'creating';
    final safeIndex =
        items.isEmpty ? 0 : _index.clamp(0, items.length - 1).toInt();
    final item = items.isEmpty ? null : items[safeIndex];
    final dateText = item?.date == null
        ? ''
        : '${item!.date!.year}.${item.date!.month}.${item.date!.day} ';
    final titleText =
        item == null ? widget.progress.stage : '$dateText${item.title}';

    return Container(
      key: const ValueKey<String>('ai-expansion-progress-clues'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.72)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 18,
            height: 18,
            child: isWorking
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accentStrong,
                  )
                : const Icon(
                    Icons.manage_search_rounded,
                    color: AppTheme.accentStrong,
                    size: 18,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      '候选线索',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentStrong,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.progress.stage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Align(
                    key: ValueKey<String>(titleText),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _syncTimer() {
    _timer?.cancel();
    if (widget.progress.items.length <= 1) {
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted || widget.progress.items.isEmpty) {
        return;
      }
      setState(() {
        _index = (_index + 1) % widget.progress.items.length;
      });
    });
  }

  bool _sameItems(
    List<TimelineExpansionProgressItem> previous,
    List<TimelineExpansionProgressItem> next,
  ) {
    if (previous.length != next.length) {
      return false;
    }
    for (var index = 0; index < previous.length; index += 1) {
      if (previous[index].title != next[index].title ||
          previous[index].date != next[index].date) {
        return false;
      }
    }
    return true;
  }
}

class _TrackingDirectionNote extends StatelessWidget {
  const _TrackingDirectionNote({
    required this.text,
    required this.lowConfidence,
    required this.recentActivityStatus,
    required this.trackingViability,
    required this.trackingViabilityReason,
  });

  final String text;
  final bool lowConfidence;
  final String recentActivityStatus;
  final String trackingViability;
  final String trackingViabilityReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'AI 理解',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentStrong,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
          ),
          if (lowConfidence) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              '依据较少，建议补充关键词后再确认。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
            ),
          ],
          if (_recentStatusLabel.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _recentStatusLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
            ),
            if (_recentStatusDetail.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                _recentStatusDetail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String get _recentStatusLabel {
    if (recentActivityStatus == 'active' || trackingViability == 'high') {
      return '近期仍有更新';
    }
    if (recentActivityStatus == 'quiet') {
      return '近期更新较少';
    }
    if (recentActivityStatus == 'unknown') {
      return '证据不足';
    }
    return '';
  }

  String get _recentStatusDetail {
    if (trackingViabilityReason.trim().isNotEmpty) {
      return trackingViabilityReason.trim();
    }
    if (recentActivityStatus == 'quiet') {
      return '适合作为历史时间线阅读，后续提醒可能不频繁。';
    }
    if (recentActivityStatus == 'unknown') {
      return '建议补充关键词，帮助确认是否值得持续关注。';
    }
    return '';
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.category,
    required this.locked,
    required this.onTap,
  });

  final InterestCategory category;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '所属类别：${category.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentSoft.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: AppTheme.accent.withValues(alpha: locked ? 0.30 : 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                _interestCategoryIcon(category.id),
                size: 15,
                color: AppTheme.accentStrong.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 5),
              Text(
                category.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentStrong,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
              ),
              if (locked) ...<Widget>[
                const SizedBox(width: 4),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: AppTheme.accentStrong.withValues(alpha: 0.64),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChoiceChip extends StatelessWidget {
  const _CategoryChoiceChip({
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final InterestCategory category;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      key: ValueKey<String>('create-category-${category.id}'),
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: Icon(
        _interestCategoryIcon(category.id),
        size: 16,
        color: selected ? AppTheme.surface : AppTheme.accentStrong,
      ),
      label: Text(category.label),
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: selected ? AppTheme.surface : AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
      selectedColor: AppTheme.accentStrong,
      backgroundColor: AppTheme.surfaceMuted,
      side: BorderSide(
        color: selected
            ? AppTheme.accentStrong
            : AppTheme.accent.withValues(alpha: 0.16),
      ),
    );
  }
}

class _StartDateSuggestion extends StatelessWidget {
  const _StartDateSuggestion({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 18,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'AI 建议起点',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatTimelineDate(date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '随扩写更新',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

IconData _interestCategoryIcon(String id) {
  return switch (id) {
    'politics' => Icons.account_balance_rounded,
    'military' => Icons.shield_outlined,
    'history' => Icons.history_edu_rounded,
    'economy' => Icons.trending_up_rounded,
    'finance' => Icons.payments_outlined,
    'technology' => Icons.memory_rounded,
    'society' => Icons.groups_rounded,
    'international' => Icons.public_rounded,
    'enterprise' => Icons.business_center_outlined,
    'health' => Icons.medical_services_outlined,
    'climate' => Icons.eco_outlined,
    'culture' => Icons.palette_outlined,
    _ => Icons.category_outlined,
  };
}

class _EditableKeywordGroup extends StatelessWidget {
  const _EditableKeywordGroup({
    required this.title,
    required this.tone,
    required this.values,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final Color tone;
  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tone,
                    ),
              ),
            ),
            IconButton(
              onPressed: onAdd,
              tooltip: '增加关键词',
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: tone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            '当前没有关键词，点击右侧增加。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (value) => Container(
                    padding: const EdgeInsets.only(
                        left: 12, right: 6, top: 6, bottom: 6),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: tone.withValues(alpha: 0.14)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          value,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tone,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(
                              width: 24, height: 24),
                          padding: EdgeInsets.zero,
                          onPressed: () => onRemove(value),
                          tooltip: '删除关键词',
                          icon: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: tone,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
