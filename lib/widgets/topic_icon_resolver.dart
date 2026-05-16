import 'package:flutter/material.dart';

import '../models/timeline_models.dart';
import '../theme/app_theme.dart';

class TopicIconStyle {
  const TopicIconStyle({
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.label,
  });

  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final String label;
}

class TopicIconResolver {
  const TopicIconResolver._();

  static const TopicIconStyle fallback = TopicIconStyle(
    icon: Icons.bookmark_rounded,
    foregroundColor: AppTheme.accentStrong,
    backgroundColor: AppTheme.accentSoft,
    borderColor: AppTheme.border,
    label: '通用事件',
  );

  static const TopicIconStyle pinned = TopicIconStyle(
    icon: Icons.push_pin_rounded,
    foregroundColor: AppTheme.accentStrong,
    backgroundColor: AppTheme.accentSoft,
    borderColor: AppTheme.border,
    label: '置顶',
  );

  static const TopicIconStyle failed = TopicIconStyle(
    icon: Icons.error_outline_rounded,
    foregroundColor: AppTheme.highlightStrong,
    backgroundColor: AppTheme.highlightSoft,
    borderColor: AppTheme.border,
    label: '错误',
  );

  static TopicIconStyle resolve(Topic topic) {
    final backendStyle = _styleForBackendCategories(topic);
    if (backendStyle != null) {
      return backendStyle;
    }

    final searchableText = _searchableTextFor(topic);
    for (final rule in _rules) {
      if (rule.matches(searchableText)) {
        return rule.style;
      }
    }
    return fallback;
  }

  static String _searchableTextFor(Topic topic) {
    final definition = topic.definition;
    return <String>[
      topic.name,
      topic.tagline,
      if (definition != null) ...<String>[
        definition.overview,
        definition.includeScope,
        ...definition.coreKeywords,
        ...definition.relatedKeywords,
      ],
    ].join(' ').toLowerCase();
  }

  static TopicIconStyle? _styleForBackendCategories(Topic topic) {
    final categoryKeys = <String>[
      if (topic.primaryCategory != null) topic.primaryCategory!,
      ...topic.categories,
    ];
    for (final category in categoryKeys) {
      final style = _stylesByCategory[_normalizeCategory(category)];
      if (style != null) {
        return style;
      }
    }
    return null;
  }

  static String _normalizeCategory(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_');
  }
}

class _TopicIconRule {
  const _TopicIconRule({
    required this.terms,
    required this.style,
  });

  final List<String> terms;
  final TopicIconStyle style;

  bool matches(String text) => terms.any(text.contains);
}

const TopicIconStyle _blue = TopicIconStyle(
  icon: Icons.bookmark_rounded,
  foregroundColor: AppTheme.accentStrong,
  backgroundColor: AppTheme.accentSoft,
  borderColor: AppTheme.border,
  label: '通用事件',
);

const TopicIconStyle _indigo = TopicIconStyle(
  icon: Icons.public_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '外交政策',
);

const TopicIconStyle _violet = TopicIconStyle(
  icon: Icons.hub_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '科技',
);

const TopicIconStyle _teal = TopicIconStyle(
  icon: Icons.anchor_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '交通物流',
);

const TopicIconStyle _green = TopicIconStyle(
  icon: Icons.eco_rounded,
  foregroundColor: AppTheme.highlight,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '环境',
);

const TopicIconStyle _slate = TopicIconStyle(
  icon: Icons.category_rounded,
  foregroundColor: AppTheme.textSecondary,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '综合',
);

const TopicIconStyle _militarySecurity = TopicIconStyle(
  icon: Icons.shield_rounded,
  foregroundColor: AppTheme.danger,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '军事安全',
);

const TopicIconStyle _technologyAi = TopicIconStyle(
  icon: Icons.auto_awesome_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: 'AI',
);

const TopicIconStyle _policyRegulation = TopicIconStyle(
  icon: Icons.policy_rounded,
  foregroundColor: AppTheme.highlight,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '政策监管',
);

const TopicIconStyle _publicSafety = TopicIconStyle(
  icon: Icons.health_and_safety_rounded,
  foregroundColor: AppTheme.danger,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '公共安全',
);

const TopicIconStyle _financeCapital = TopicIconStyle(
  icon: Icons.show_chart_rounded,
  foregroundColor: AppTheme.highlight,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '金融市场',
);

const TopicIconStyle _economyMarket = TopicIconStyle(
  icon: Icons.query_stats_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '宏观经济',
);

const TopicIconStyle _enterpriseBusiness = TopicIconStyle(
  icon: Icons.business_center_rounded,
  foregroundColor: AppTheme.lavender,
  backgroundColor: AppTheme.surfaceMuted,
  borderColor: AppTheme.border,
  label: '公司商业',
);

const Map<String, TopicIconStyle> _stylesByCategory = <String, TopicIconStyle>{
  'military_security': _militarySecurity,
  'diplomacy_policy': _indigo,
  'policy_regulation': _policyRegulation,
  'economy_market': _economyMarket,
  'finance_capital': _financeCapital,
  'technology_ai': _technologyAi,
  'semiconductor_chip': TopicIconStyle(
    icon: Icons.memory_rounded,
    foregroundColor: AppTheme.lavender,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '半导体',
  ),
  'cybersecurity': TopicIconStyle(
    icon: Icons.security_rounded,
    foregroundColor: AppTheme.textSecondary,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '网络安全',
  ),
  'aerospace': TopicIconStyle(
    icon: Icons.rocket_launch_rounded,
    foregroundColor: AppTheme.lavender,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '航天航空',
  ),
  'automotive_ev': TopicIconStyle(
    icon: Icons.directions_car_rounded,
    foregroundColor: AppTheme.lavender,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '新能源车',
  ),
  'energy_supply': TopicIconStyle(
    icon: Icons.bolt_rounded,
    foregroundColor: AppTheme.highlight,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '能源',
  ),
  'enterprise_business': _enterpriseBusiness,
  'industry_chain': TopicIconStyle(
    icon: Icons.precision_manufacturing_rounded,
    foregroundColor: AppTheme.lavender,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '产业链',
  ),
  'public_safety': _publicSafety,
  'social_public': TopicIconStyle(
    icon: Icons.groups_rounded,
    foregroundColor: AppTheme.lavender,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '社会民生',
  ),
  'legal_regulation': TopicIconStyle(
    icon: Icons.gavel_rounded,
    foregroundColor: AppTheme.textSecondary,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '法律司法',
  ),
  'health_medical': TopicIconStyle(
    icon: Icons.medical_services_rounded,
    foregroundColor: AppTheme.highlight,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '医疗健康',
  ),
  'education_research': TopicIconStyle(
    icon: Icons.school_rounded,
    foregroundColor: AppTheme.lavender,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '教育研究',
  ),
  'environment_climate': _green,
  'transport_logistics': _teal,
  'infrastructure_real_estate': TopicIconStyle(
    icon: Icons.domain_rounded,
    foregroundColor: AppTheme.textSecondary,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '基建地产',
  ),
  'culture_sports': TopicIconStyle(
    icon: Icons.movie_filter_rounded,
    foregroundColor: AppTheme.lavender,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '文化体育',
  ),
  'disaster_accident': TopicIconStyle(
    icon: Icons.warning_amber_rounded,
    foregroundColor: AppTheme.danger,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '灾害事故',
  ),
  'biotech_pharma': TopicIconStyle(
    icon: Icons.science_rounded,
    foregroundColor: AppTheme.lavender,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '生物医药',
  ),
  'culture_media': TopicIconStyle(
    icon: Icons.movie_filter_rounded,
    foregroundColor: AppTheme.lavender,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '文化媒体',
  ),
  'sports_events': TopicIconStyle(
    icon: Icons.sports_soccer_rounded,
    foregroundColor: AppTheme.highlight,
    backgroundColor: AppTheme.surfaceMuted,
    borderColor: AppTheme.border,
    label: '体育赛事',
  ),
  'general_event': _blue,
};

const List<_TopicIconRule> _rules = <_TopicIconRule>[
  _TopicIconRule(
    terms: <String>[
      '大模型',
      '人工智能',
      'ai ',
      ' ai',
      'openai',
      'gpt',
      'llm',
      '模型发布'
    ],
    style: TopicIconStyle(
      icon: Icons.auto_awesome_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: 'AI',
    ),
  ),
  _TopicIconRule(
    terms: <String>['半导体', '芯片', '晶圆', '封装', 'gpu', '算力'],
    style: TopicIconStyle(
      icon: Icons.memory_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '半导体',
    ),
  ),
  _TopicIconRule(
    terms: <String>['网络安全', '黑客', '漏洞', '数据泄露', '勒索', '攻击'],
    style: TopicIconStyle(
      icon: Icons.security_rounded,
      foregroundColor: AppTheme.textSecondary,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '网络安全',
    ),
  ),
  _TopicIconRule(
    terms: <String>['战争', '冲突', '军事', '军演', '导弹', '防务', '威慑', '停火'],
    style: TopicIconStyle(
      icon: Icons.shield_rounded,
      foregroundColor: AppTheme.danger,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '军事冲突',
    ),
  ),
  _TopicIconRule(
    terms: <String>['选举', '投票', '竞选', '总统', '议会', '政党'],
    style: TopicIconStyle(
      icon: Icons.how_to_vote_rounded,
      foregroundColor: AppTheme.highlight,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '选举政治',
    ),
  ),
  _TopicIconRule(
    terms: <String>['监管', '政策', '法规', '规则', '审批', '补贴', '制裁'],
    style: TopicIconStyle(
      icon: Icons.policy_rounded,
      foregroundColor: AppTheme.highlight,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '政策监管',
    ),
  ),
  _TopicIconRule(
    terms: <String>['司法', '法院', '诉讼', '法律', '判决', '合规'],
    style: TopicIconStyle(
      icon: Icons.gavel_rounded,
      foregroundColor: AppTheme.textSecondary,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '法律司法',
    ),
  ),
  _TopicIconRule(
    terms: <String>['宏观', '经济', '通胀', '利率', '央行', '就业', 'gdp'],
    style: TopicIconStyle(
      icon: Icons.query_stats_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '宏观经济',
    ),
  ),
  _TopicIconRule(
    terms: <String>['金融', '股市', '债券', '汇率', '基金', '银行', '融资'],
    style: TopicIconStyle(
      icon: Icons.show_chart_rounded,
      foregroundColor: AppTheme.highlight,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '金融市场',
    ),
  ),
  _TopicIconRule(
    terms: <String>['公司', '企业', '商业', '并购', '财报', '品牌', '价格战'],
    style: TopicIconStyle(
      icon: Icons.business_center_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '公司商业',
    ),
  ),
  _TopicIconRule(
    terms: <String>['科技', '互联网', '平台', '软件', '硬件', '应用'],
    style: _violet,
  ),
  _TopicIconRule(
    terms: <String>['航天', '航空', '卫星', '火箭', '登月', '低空'],
    style: TopicIconStyle(
      icon: Icons.rocket_launch_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '航天航空',
    ),
  ),
  _TopicIconRule(
    terms: <String>['新能源汽车', '新能源车', '汽车', '电动车', 'ev ', '车企', '销量'],
    style: TopicIconStyle(
      icon: Icons.directions_car_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '汽车',
    ),
  ),
  _TopicIconRule(
    terms: <String>['能源', '电力', '石油', '天然气', '光伏', '风电', '煤炭'],
    style: TopicIconStyle(
      icon: Icons.bolt_rounded,
      foregroundColor: AppTheme.highlight,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '能源',
    ),
  ),
  _TopicIconRule(
    terms: <String>['航运', '物流', '供应链', '港口', '海峡', '运输', '交付'],
    style: _teal,
  ),
  _TopicIconRule(
    terms: <String>['地产', '房地产', '基建', '城市', '住房', '轨道交通'],
    style: TopicIconStyle(
      icon: Icons.domain_rounded,
      foregroundColor: AppTheme.textSecondary,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '基建地产',
    ),
  ),
  _TopicIconRule(
    terms: <String>['气候', '环保', '环境', '碳', '污染', '生态'],
    style: _green,
  ),
  _TopicIconRule(
    terms: <String>['医疗', '健康', '医院', '药品', '医保', '疫苗'],
    style: TopicIconStyle(
      icon: Icons.medical_services_rounded,
      foregroundColor: AppTheme.highlight,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '医疗健康',
    ),
  ),
  _TopicIconRule(
    terms: <String>['生物', '生物科技', '基因', '临床', '药企'],
    style: TopicIconStyle(
      icon: Icons.science_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '生物科技',
    ),
  ),
  _TopicIconRule(
    terms: <String>['公共安全', '治安', '安全事故', '消防', '风险'],
    style: TopicIconStyle(
      icon: Icons.health_and_safety_rounded,
      foregroundColor: AppTheme.danger,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '公共安全',
    ),
  ),
  _TopicIconRule(
    terms: <String>['灾害', '地震', '洪水', '台风', '事故', '坠毁', '爆炸'],
    style: TopicIconStyle(
      icon: Icons.warning_amber_rounded,
      foregroundColor: AppTheme.danger,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '灾害事故',
    ),
  ),
  _TopicIconRule(
    terms: <String>['教育', '学校', '高校', '考试', '招生'],
    style: TopicIconStyle(
      icon: Icons.school_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '教育',
    ),
  ),
  _TopicIconRule(
    terms: <String>['民生', '社会', '消费', '人口', '就业', '养老'],
    style: TopicIconStyle(
      icon: Icons.groups_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '社会民生',
    ),
  ),
  _TopicIconRule(
    terms: <String>['文化', '媒体', '影视', '娱乐', '内容', '舆论'],
    style: TopicIconStyle(
      icon: Icons.movie_filter_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '文化媒体',
    ),
  ),
  _TopicIconRule(
    terms: <String>['体育', '赛事', '足球', '篮球', '奥运'],
    style: TopicIconStyle(
      icon: Icons.sports_soccer_rounded,
      foregroundColor: AppTheme.highlight,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '体育赛事',
    ),
  ),
  _TopicIconRule(
    terms: <String>['农业', '粮食', '食品', '农产品', '养殖'],
    style: TopicIconStyle(
      icon: Icons.restaurant_rounded,
      foregroundColor: AppTheme.highlight,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '农业食品',
    ),
  ),
  _TopicIconRule(
    terms: <String>['加密', '区块链', 'web3', '比特币', '虚拟货币', '数字资产'],
    style: TopicIconStyle(
      icon: Icons.account_balance_wallet_rounded,
      foregroundColor: AppTheme.textSecondary,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '加密资产',
    ),
  ),
  _TopicIconRule(
    terms: <String>['国际', '外交', '全球', '外部', '联盟', '峰会'],
    style: _indigo,
  ),
  _TopicIconRule(
    terms: <String>['地缘', '边境', '地区', '海域', '海湾'],
    style: TopicIconStyle(
      icon: Icons.map_rounded,
      foregroundColor: AppTheme.lavender,
      backgroundColor: AppTheme.surfaceMuted,
      borderColor: AppTheme.border,
      label: '地缘政治',
    ),
  ),
  _TopicIconRule(
    terms: <String>['专题', '事件', '进展', '时间线'],
    style: _blue,
  ),
  _TopicIconRule(
    terms: <String>['观察', '追踪', '趋势'],
    style: _slate,
  ),
];
