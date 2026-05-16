import 'package:flutter/material.dart';

import '../models/timeline_models.dart';
import '../theme/app_theme.dart';

class TimelineSignalStyle {
  const TimelineSignalStyle({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
}

class TimelineSignalResolver {
  const TimelineSignalResolver._();

  static const TimelineSignalStyle fallback = TimelineSignalStyle(
    label: '后续跟进',
    icon: Icons.more_horiz_rounded,
    foregroundColor: AppTheme.textSecondary,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
  );

  static TimelineSignalStyle resolve(TimelineBucket bucket) {
    final backendStyle = _styleForBackendSignals(bucket);
    if (backendStyle != null) {
      return backendStyle;
    }

    final searchableText = _searchableTextFor(bucket);
    for (final rule in _rules) {
      if (rule.matches(searchableText)) {
        return rule.style;
      }
    }
    return fallback;
  }

  static String _searchableTextFor(TimelineBucket bucket) {
    return <String>[
      bucket.headline,
      bucket.label,
      for (final entry in bucket.entries) ...<String>[
        entry.title,
        entry.summary,
        entry.detail,
      ],
    ].join(' ').toLowerCase();
  }

  static TimelineSignalStyle? _styleForBackendSignals(TimelineBucket bucket) {
    for (final entry in bucket.entries) {
      final primarySignal = entry.primarySignal;
      if (primarySignal != null && primarySignal.trim().isNotEmpty) {
        final style = _stylesBySignal[_normalizeSignal(primarySignal)];
        if (style != null) {
          return style;
        }
      }
    }
    for (final entry in bucket.entries) {
      for (final signal in entry.signals) {
        final style = _stylesBySignal[_normalizeSignal(signal)];
        if (style != null) {
          return style;
        }
      }
    }
    return null;
  }

  static String _normalizeSignal(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_');
  }
}

class _TimelineSignalRule {
  const _TimelineSignalRule({
    required this.terms,
    required this.style,
  });

  final List<String> terms;
  final TimelineSignalStyle style;

  bool matches(String text) => terms.any(text.contains);
}

const TimelineSignalStyle _official = TimelineSignalStyle(
  label: '官方确认',
  icon: Icons.campaign_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _clarification = TimelineSignalStyle(
  label: '澄清否认',
  icon: Icons.fact_check_rounded,
  foregroundColor: AppTheme.textSecondary,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _start = TimelineSignalStyle(
  label: '启动立项',
  icon: Icons.play_arrow_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _complete = TimelineSignalStyle(
  label: '完成交付',
  icon: Icons.task_alt_rounded,
  foregroundColor: AppTheme.highlight,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _pause = TimelineSignalStyle(
  label: '延期暂停',
  icon: Icons.pause_circle_rounded,
  foregroundColor: AppTheme.highlight,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _escalation = TimelineSignalStyle(
  label: '升级加剧',
  icon: Icons.trending_up_rounded,
  foregroundColor: AppTheme.danger,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _deescalation = TimelineSignalStyle(
  label: '缓和降温',
  icon: Icons.south_west_rounded,
  foregroundColor: AppTheme.highlight,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _risk = TimelineSignalStyle(
  label: '风险预警',
  icon: Icons.report_problem_rounded,
  foregroundColor: AppTheme.danger,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _interruption = TimelineSignalStyle(
  label: '事故中断',
  icon: Icons.warning_amber_rounded,
  foregroundColor: AppTheme.danger,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _military = TimelineSignalStyle(
  label: '军事安全',
  icon: Icons.shield_rounded,
  foregroundColor: AppTheme.danger,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _diplomacy = TimelineSignalStyle(
  label: '外交沟通',
  icon: Icons.forum_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _policy = TimelineSignalStyle(
  label: '政策监管',
  icon: Icons.policy_rounded,
  foregroundColor: AppTheme.highlight,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _legal = TimelineSignalStyle(
  label: '法律司法',
  icon: Icons.gavel_rounded,
  foregroundColor: AppTheme.textSecondary,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _sanction = TimelineSignalStyle(
  label: '制裁限制',
  icon: Icons.block_rounded,
  foregroundColor: AppTheme.danger,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _market = TimelineSignalStyle(
  label: '市场反应',
  icon: Icons.show_chart_rounded,
  foregroundColor: AppTheme.highlight,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _supply = TimelineSignalStyle(
  label: '供应运营',
  icon: Icons.local_shipping_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _business = TimelineSignalStyle(
  label: '公司经营',
  icon: Icons.business_center_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _technology = TimelineSignalStyle(
  label: '技术产品',
  icon: Icons.memory_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _data = TimelineSignalStyle(
  label: '数据指标',
  icon: Icons.query_stats_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _sentiment = TimelineSignalStyle(
  label: '舆情反馈',
  icon: Icons.record_voice_over_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
);

const TimelineSignalStyle _milestone = TimelineSignalStyle(
  label: '时间节点',
  icon: Icons.event_available_rounded,
  foregroundColor: AppTheme.accentStrong,
  backgroundColor: AppTheme.accentSoft,
  borderColor: AppTheme.border,
);

const Map<String, TimelineSignalStyle> _stylesBySignal =
    <String, TimelineSignalStyle>{
  'official_action': _official,
  'official_response': _official,
  'clarification': _clarification,
  'risk_warning': _risk,
  'escalation': _escalation,
  'deescalation': _deescalation,
  'milestone': _milestone,
  'launch_start': _start,
  'completion': _complete,
  'delay': _pause,
  'interruption': _interruption,
  'market_reaction': _market,
  'price_impact': _market,
  'supply_risk': _supply,
  'operation_impact': _supply,
  'policy_change': _policy,
  'legal_action': _legal,
  'sanction_action': _sanction,
  'diplomacy_response': _diplomacy,
  'military_action': _military,
  'technology_update': _technology,
  'data_release': _data,
  'public_opinion': _sentiment,
  'follow_up': TimelineSignalResolver.fallback,
  'general_progress': TimelineSignalResolver.fallback,
};

const List<_TimelineSignalRule> _rules = <_TimelineSignalRule>[
  _TimelineSignalRule(
    terms: <String>[
      '制裁',
      '禁运',
      '出口管制',
      '封禁',
      '限制交易',
      '列入清单',
      '冻结资产',
      '关税',
      '反制',
    ],
    style: _sanction,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '监管',
      '政策',
      '规则',
      '法规',
      '审查',
      '调查',
      '处罚',
      '审批',
      '许可',
      '合规',
      '补贴',
    ],
    style: _policy,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '起诉',
      '诉讼',
      '法院',
      '判决',
      '裁定',
      '禁令',
      '调查令',
      '和解协议',
      '法律责任',
      '司法审查',
    ],
    style: _legal,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '会谈',
      '谈判',
      '访问',
      '通话',
      '磋商',
      '斡旋',
      '谴责',
      '表态',
      '联合声明',
      '峰会',
      '协议',
      '沟通渠道',
    ],
    style: _diplomacy,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '宣布',
      '公告',
      '声明',
      '确认',
      '通报',
      '披露',
      '正式',
      '发文',
      '公布',
      '官宣',
      '发布会',
    ],
    style: _official,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '上涨',
      '下跌',
      '回落',
      '暴涨',
      '暴跌',
      '波动',
      '价格',
      '股价',
      '汇率',
      '油价',
      '金价',
      '销量',
      '重新定价',
      '市场反应',
    ],
    style: _market,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '风险',
      '预警',
      '警告',
      '担忧',
      '威胁',
      '隐患',
      '危机',
      '不确定性',
      '可能导致',
      '面临压力',
    ],
    style: _risk,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '升级',
      '加剧',
      '扩大',
      '加码',
      '恶化',
      '升温',
      '激化',
      '增强',
      '扩大范围',
      '进入新阶段',
    ],
    style: _escalation,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '缓和',
      '降温',
      '撤回',
      '让步',
      '和解',
      '停火',
      '恢复',
      '重启',
      '释放善意',
      '达成共识',
    ],
    style: _deescalation,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '事故',
      '故障',
      '中断',
      '宕机',
      '停运',
      '封锁',
      '延误',
      '泄露',
      '爆炸',
      '坠毁',
      '短缺',
    ],
    style: _interruption,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '袭击',
      '打击',
      '空袭',
      '导弹',
      '导弹发射',
      '发射导弹',
      '军演',
      '防空',
      '舰队',
      '军事行动',
      '军事戒备',
      '实弹',
      '开火',
      '战斗',
    ],
    style: _military,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '发布',
      '测试',
      '升级',
      '版本',
      '模型',
      '芯片',
      '系统',
      '功能',
      'api',
      '开源',
      '专利',
      '样机',
      '量产',
    ],
    style: _technology,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '财报',
      '营收',
      '利润',
      '亏损',
      '裁员',
      '招聘',
      '并购',
      '融资',
      '投资',
      '合作',
      '重组',
      '管理层',
    ],
    style: _business,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '供应链',
      '产能',
      '库存',
      '交付',
      '运输',
      '港口',
      '物流',
      '订单',
      '生产',
      '停产',
      '复产',
      '封装',
    ],
    style: _supply,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '数据显示',
      '报告',
      '统计',
      '指数',
      '同比',
      '环比',
      '增长',
      '下降',
      '超过',
      '低于',
      '预测',
      '调查',
    ],
    style: _data,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '争议',
      '质疑',
      '批评',
      '抗议',
      '抵制',
      '热议',
      '用户反馈',
      '社交媒体',
      '公众反应',
      '舆论发酵',
    ],
    style: _sentiment,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '启动',
      '开启',
      '立项',
      '批准',
      '签署',
      '部署',
      '上线',
      '进入',
      '成立',
      '发起',
    ],
    style: _start,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '完成',
      '交付',
      '落地',
      '达成',
      '兑现',
      '验收',
      '结束',
      '收官',
      '投产',
    ],
    style: _complete,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '延期',
      '推迟',
      '暂停',
      '搁置',
      '取消',
      '中止',
      '叫停',
      '撤回',
      '终止',
      '延后',
    ],
    style: _pause,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '否认',
      '澄清',
      '辟谣',
      '回应称',
      '不属实',
      '误传',
      '修正',
      '更正',
      '说明',
    ],
    style: _clarification,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '开始',
      '截止',
      '窗口期',
      '里程碑',
      '阶段',
      '节点',
      '关键日期',
    ],
    style: _milestone,
  ),
  _TimelineSignalRule(
    terms: <String>[
      '后续',
      '继续',
      '进一步',
      '补充',
      '跟进',
      '推进',
      '等待',
      '仍需',
      '尚未',
      '下一步',
      '计划',
      '准备',
    ],
    style: TimelineSignalResolver.fallback,
  ),
];
