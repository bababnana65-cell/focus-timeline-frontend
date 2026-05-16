import '../models/timeline_models.dart';

abstract class TimelineRepository {
  Future<List<Topic>> fetchTrackedTopics();

  Future<List<Topic>> fetchRecommendedTopics();

  Future<List<TimelineEntry>> fetchTimeline(String topicId);
}

class MockTimelineRepository implements TimelineRepository {
  @override
  Future<List<Topic>> fetchTrackedTopics() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return SampleData.topics.take(2).toList();
  }

  @override
  Future<List<Topic>> fetchRecommendedTopics() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return SampleData.topics;
  }

  @override
  Future<List<TimelineEntry>> fetchTimeline(String topicId) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final entries = SampleData.entriesByTopic[topicId] ?? const <TimelineEntry>[];
    return entries.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}

class SampleData {
  static const aiTopic = Topic(
    id: 'ai-model-release',
    name: 'AI 大模型发布',
    tagline: '追踪模型发布时间、功能更新与外部反馈',
    followerCount: 18240,
    isHot: true,
  );

  static const chipTopic = Topic(
    id: 'chip-supply-chain',
    name: '全球半导体供应链',
    tagline: '关注扩产、政策、交付周期与价格变化',
    followerCount: 12560,
    isHot: true,
  );

  static const moonTopic = Topic(
    id: 'moon-mission',
    name: '载人登月计划',
    tagline: '跟踪任务节点、测试进展和关键窗口期',
    followerCount: 9320,
    isHot: true,
  );

  static const evPriceWarTopic = Topic(
    id: 'ev-price-war',
    name: '新能源汽车价格战',
    tagline: '观察调价、销量波动与供应链连锁反应',
    followerCount: 17680,
    isHot: true,
  );

  static const lowAltitudeTopic = Topic(
    id: 'low-altitude-economy',
    name: '低空经济试点',
    tagline: '关注试点城市、航线开放与商业化进度',
    followerCount: 16940,
    isHot: true,
  );

  static const robotFactoryTopic = Topic(
    id: 'robot-factory',
    name: '机器人进厂潮',
    tagline: '跟踪产线替换、订单爆发和交付节奏',
    followerCount: 16420,
    isHot: true,
  );

  static const drugOutTopic = Topic(
    id: 'innovative-drug-outlicense',
    name: '创新药出海授权',
    tagline: '观察里程碑付款、审批进展与国际合作',
    followerCount: 15860,
    isHot: true,
  );

  static const dataExchangeTopic = Topic(
    id: 'data-exchange',
    name: '数据要素交易平台',
    tagline: '关注规则落地、交易活跃度与新场景试点',
    followerCount: 15110,
    isHot: true,
  );

  static const fusionTopic = Topic(
    id: 'fusion-funding',
    name: '可控核聚变融资潮',
    tagline: '追踪融资轮次、实验节点与产业链扩张',
    followerCount: 14720,
    isHot: true,
  );

  static const autonomousDrivingTopic = Topic(
    id: 'autonomous-driving',
    name: '无人驾驶商业化落地',
    tagline: '关注示范区开放、车队扩张与监管节奏',
    followerCount: 14300,
    isHot: true,
  );

  static const crossBorderTopic = Topic(
    id: 'cross-border-commerce',
    name: '跨境电商平台新政',
    tagline: '观察平台规则、物流成本与商家迁移趋势',
    followerCount: 13240,
    isHot: true,
  );

  static const topics = <Topic>[
    aiTopic,
    evPriceWarTopic,
    lowAltitudeTopic,
    robotFactoryTopic,
    drugOutTopic,
    dataExchangeTopic,
    fusionTopic,
    autonomousDrivingTopic,
    chipTopic,
    crossBorderTopic,
    moonTopic,
  ];

  static List<TimelineEntry> get _aiEntries => <TimelineEntry>[
        _entry(
          topicId: aiTopic.id,
          daysAgo: 96,
          title: '项目立项确认',
          summary: '研发团队确认年度旗舰模型路线。',
          detail: '内部路线图首次明确参数规模、推理效率和多模态方向。',
          fullText:
              '研发团队在项目立项会上确认年度旗舰模型路线，目标是把更强的推理能力、多模态理解和更低延迟放进同一代产品。与此同时，产品团队开始准备外部测试名单和发布节奏。',
          source: '官方路线图',
        ),
        _entry(
          topicId: aiTopic.id,
          daysAgo: 68,
          title: '首轮封闭测试',
          summary: '首批企业用户进入封闭测试。',
          detail: '测试重点集中在长上下文、代码生成和多轮工具调用能力。',
          fullText:
              '首批企业用户进入封闭测试后，反馈最集中的问题包括长上下文稳定性、工具调用容错和复杂代码任务的延迟。团队据此调整了推理链路和缓存策略。',
          source: '测试周报',
        ),
        _entry(
          topicId: aiTopic.id,
          daysAgo: 24,
          title: '推理性能提升',
          summary: '新版推理引擎延迟明显下降。',
          detail: '在同等复杂度任务下，平均首 token 时间缩短约 22%。',
          fullText:
              '新版推理引擎完成一轮优化后，在复杂任务中的平均首 token 时间明显缩短，同时通过动态路由减少了不必要的高成本调用，这让大规模商用的可行性进一步提升。',
          source: '技术博客',
          isMajor: true,
        ),
        _entry(
          topicId: aiTopic.id,
          daysAgo: 11,
          title: '开发者文档预热',
          summary: '开发者文档和示例应用开始对外预热。',
          detail: '外部沟通重点从模型参数转向实际工作流接入效果。',
          fullText:
              '在开发者文档和示例应用开始预热后，外部讨论焦点逐步从模型参数转向真实工作流的适配，包括编码、知识库问答和自动化执行场景。',
          source: '开发者社区',
        ),
        _entry(
          topicId: aiTopic.id,
          daysAgo: 3,
          title: '发布时间窗口传出',
          summary: '市场开始普遍预期发布时间窗口。',
          detail: '多家合作方开始提前准备接入公告和联动发布。',
          fullText:
              '随着合作方开始同步发布时间窗口，外界对新品发布时间的预期明显升高，多家生态伙伴同时准备兼容方案和演示案例，说明发布计划已进入最后压测阶段。',
          source: '合作伙伴消息',
        ),
        _entry(
          topicId: aiTopic.id,
          daysAgo: 0,
          hoursAgo: 16,
          title: '发布会邀请函',
          summary: '官方发布会邀请函发出。',
          detail: '邀请函重点强调实时推理、视觉理解和工作流执行能力。',
          fullText:
              '官方发布会邀请函正式发出，文案不再强调单一 benchmark，而是突出实时推理、视觉理解、工作流执行和企业集成，说明产品定位更偏向可直接落地的生产力平台。',
          source: '官方公告',
          isMajor: true,
        ),
        _entry(
          topicId: aiTopic.id,
          daysAgo: 0,
          hoursAgo: 5,
          title: '媒体试玩解禁',
          summary: '首批媒体试玩内容同步解禁。',
          detail: '试玩内容显示新版本在复杂问题拆解上更稳定。',
          fullText:
              '媒体试玩解禁后，体验文章普遍认为模型在复杂问题拆解、连续指令遵循和图文混合理解上更稳定，但也有报道提到在极长链路任务中仍需要更明显的进度提示。',
          source: '媒体评测',
        ),
        _entry(
          topicId: aiTopic.id,
          daysAgo: 0,
          hoursAgo: 1,
          title: '发布会开始',
          summary: '新品发布会进入正式直播。',
          detail: '直播同步展示了 API、应用端和企业版功能。',
          fullText:
              '发布会正式直播后，团队依次展示了 API、消费端应用和企业版产品线。演示重点在于如何把长推理、结构化输出和工具调用组合进完整任务流，而不只是展示单轮问答效果。',
          source: '直播现场',
          isMajor: true,
        ),
      ];

  static List<TimelineEntry> get _chipEntries => <TimelineEntry>[
        _entry(
          topicId: chipTopic.id,
          daysAgo: 110,
          title: '新厂扩建方案提出',
          summary: '头部厂商提交新一轮扩建方案。',
          detail: '方案聚焦先进封装和成熟制程并行扩产。',
          fullText:
              '头部厂商提交的新厂扩建方案显示，先进封装与成熟制程产能将同步扩展，以覆盖 AI、汽车电子和工业控制的不同需求周期。',
          source: '产业快讯',
        ),
        _entry(
          topicId: chipTopic.id,
          daysAgo: 57,
          title: '设备交付推迟',
          summary: '关键设备交付节奏被迫顺延。',
          detail: '这使部分产线爬坡速度低于此前预期。',
          fullText:
              '由于关键设备交付延后，部分晶圆厂的产线爬坡进度受到影响，原本计划中的季度释放节奏需要重新评估。市场因此开始关注下游库存与交期的再平衡。',
          source: '设备渠道',
          isMajor: true,
        ),
        _entry(
          topicId: chipTopic.id,
          daysAgo: 34,
          title: '政策补贴落地',
          summary: '地方补贴方案正式落地。',
          detail: '补贴重点面向关键材料、封装和设计工具。',
          fullText:
              '地方补贴方案落地后，受益范围不仅覆盖晶圆制造，也扩展到关键材料、先进封装和设计工具链，这有助于提高供应链本地化稳定性。',
          source: '政策通报',
        ),
        _entry(
          topicId: chipTopic.id,
          daysAgo: 14,
          title: '价格止跌信号出现',
          summary: '部分细分芯片价格出现止跌迹象。',
          detail: '终端补库存和车规需求回暖开始反映到报价。',
          fullText:
              '部分细分芯片价格出现止跌迹象，说明终端补库存和车规需求回暖已开始传导至报价体系，不过整体供需仍未完全恢复到紧平衡状态。',
          source: '渠道报价',
        ),
        _entry(
          topicId: chipTopic.id,
          daysAgo: 6,
          title: '大客户签订长约',
          summary: '头部客户重新签订中长期供货协议。',
          detail: '长约锁量对季度排产预期形成支撑。',
          fullText:
              '头部客户重新签订中长期供货协议，意味着上游对后续季度排产更有把握，也反映出核心客户开始用锁量方式对冲未来可能的波动。',
          source: '供应链消息',
          isMajor: true,
        ),
        _entry(
          topicId: chipTopic.id,
          daysAgo: 0,
          hoursAgo: 20,
          title: '交货周期更新',
          summary: '最新交货周期整体缩短。',
          detail: '成熟制程产品交期改善最明显。',
          fullText:
              '最新交货周期更新显示，成熟制程产品的交期改善最为明显，而高端封装环节仍然偏紧，这意味着供应链恢复并不均匀。',
          source: '月度简报',
        ),
        _entry(
          topicId: chipTopic.id,
          daysAgo: 0,
          hoursAgo: 7,
          title: '先进封装再扩产',
          summary: '先进封装产线宣布追加投资。',
          detail: '新增投资主要投向高带宽封装能力。',
          fullText:
              '先进封装产线再度宣布追加投资，新增预算主要用于高带宽封装能力建设，进一步说明 AI 带来的需求红利正从算力芯片延伸到整条封装链路。',
          source: '企业公告',
          isMajor: true,
        ),
        _entry(
          topicId: chipTopic.id,
          daysAgo: 0,
          hoursAgo: 2,
          title: '市场风险提示',
          summary: '机构提醒旺季需求仍需继续验证。',
          detail: '对下半年需求判断仍存在分歧。',
          fullText:
              '虽然近期供应链指标有所改善，但机构仍提醒旺季需求需要继续验证，尤其是消费电子复苏速度、企业资本支出节奏以及地缘政策变化，都会影响下半年的供需判断。',
          source: '研究报告',
        ),
      ];

  static List<TimelineEntry> get _moonEntries => <TimelineEntry>[
        _entry(
          topicId: moonTopic.id,
          daysAgo: 140,
          title: '阶段任务确定',
          summary: '载人登月阶段任务正式拆解。',
          detail: '任务链路覆盖火箭、飞船、着陆器和地面支持系统。',
          fullText:
              '载人登月阶段任务完成拆解后，研制工作从单点突破转向多系统协同，重点变成飞行器集成测试和多部门联调。',
          source: '任务公告',
        ),
        _entry(
          topicId: moonTopic.id,
          daysAgo: 82,
          title: '关键试验台架建成',
          summary: '关键试验台架完成搭建。',
          detail: '后续将进入高频率联调阶段。',
          fullText:
              '关键试验台架建成后，多项原先需要分散完成的验证任务可以并入同一联调流程，整体研发效率明显提升。',
          source: '工程进展',
        ),
        _entry(
          topicId: moonTopic.id,
          daysAgo: 47,
          title: '地面综合演练',
          summary: '第一次全链路地面综合演练完成。',
          detail: '演练重点验证了时序协同和应急处置流程。',
          fullText:
              '第一次全链路地面综合演练完成后，工程团队开始针对通信时序、异常处置和多系统切换中的边界情况做专项复盘。',
          source: '演练通报',
          isMajor: true,
        ),
        _entry(
          topicId: moonTopic.id,
          daysAgo: 19,
          title: '发动机测试通过',
          summary: '关键发动机完成关键工况测试。',
          detail: '测试结果满足计划窗口要求。',
          fullText:
              '关键发动机测试通过，意味着后续更复杂的联试可以按计划推进，发射窗口安排的确定性随之增强。',
          source: '测试报告',
          isMajor: true,
        ),
        _entry(
          topicId: moonTopic.id,
          daysAgo: 4,
          title: '发射窗口研判',
          summary: '专家组对窗口期进行集中研判。',
          detail: '评估结果显示主计划与备份窗口均可行。',
          fullText:
              '专家组在集中研判后认为，当前主计划和备份窗口都具备可行性，但仍需关注后续天气与协同资源排布。',
          source: '专家纪要',
        ),
        _entry(
          topicId: moonTopic.id,
          daysAgo: 0,
          hoursAgo: 11,
          title: '联试进入收尾',
          summary: '多系统联试进入收尾阶段。',
          detail: '各子系统开始提交最终状态报告。',
          fullText:
              '多系统联试进入收尾阶段，各子系统陆续提交最终状态报告，项目管理重点由技术问题清单转向发射前资源统筹和风险复核。',
          source: '项目例会',
        ),
        _entry(
          topicId: moonTopic.id,
          daysAgo: 0,
          hoursAgo: 3,
          title: '重大节点确认',
          summary: '下一关键节点时间窗口正式确认。',
          detail: '官方确认后，项目节奏从准备态转向执行态。',
          fullText:
              '重大节点时间窗口正式确认后，整个项目从准备态转向执行态，意味着后续每一个状态更新都将直接影响公众和产业链对任务进展的判断。',
          source: '官方发布',
          isMajor: true,
        ),
      ];

  static const List<_SimpleTopicSeed> _simpleTopicSeeds = <_SimpleTopicSeed>[
    _SimpleTopicSeed(
      topic: evPriceWarTopic,
      source: '行业追踪',
      kickoff: '主流品牌启动新一轮价格调整。',
      milestone: '渠道贴息和置换补贴开始同步加码。',
      recent: '24 小时内又有新车型加入调价。',
      latest: '头部品牌公开回应，竞争进入新阶段。',
    ),
    _SimpleTopicSeed(
      topic: lowAltitudeTopic,
      source: '试点通报',
      kickoff: '多地公布新一批低空经济试点。',
      milestone: '航线审批流程缩短，商业化演示提速。',
      recent: '24 小时内新增城市航线开放测试。',
      latest: '运营规则再次细化，进入落地阶段。',
    ),
    _SimpleTopicSeed(
      topic: robotFactoryTopic,
      source: '制造业观察',
      kickoff: '工业机器人试点从单线扩展到多线。',
      milestone: '核心厂商订单排期明显拉长。',
      recent: '24 小时内又有工厂宣布导入方案。',
      latest: '关键客户确认新一批交付窗口。',
    ),
    _SimpleTopicSeed(
      topic: drugOutTopic,
      source: '医药跟踪',
      kickoff: '创新药项目进入授权谈判阶段。',
      milestone: '海外审评资料准备进度明显加快。',
      recent: '24 小时内潜在合作方线索继续增加。',
      latest: '关键条款接近敲定，热度陡升。',
    ),
    _SimpleTopicSeed(
      topic: dataExchangeTopic,
      source: '数商快报',
      kickoff: '数据交易规则完成一轮修订。',
      milestone: '医疗和制造场景率先上线交易。',
      recent: '24 小时内多家机构入场挂牌。',
      latest: '跨区域合作机制开始试运行。',
    ),
    _SimpleTopicSeed(
      topic: fusionTopic,
      source: '前沿科技报',
      kickoff: '聚变赛道再现大额融资窗口。',
      milestone: '团队公布下一关键实验节点。',
      recent: '24 小时内机构关注度继续提升。',
      latest: '实验结果预告释出，热度进一步集中。',
    ),
    _SimpleTopicSeed(
      topic: autonomousDrivingTopic,
      source: '出行简报',
      kickoff: '无人驾驶示范区再次扩围。',
      milestone: '多家平台扩大运营车队规模。',
      recent: '24 小时内又有城市宣布接入示范运营。',
      latest: '关键付费节点突破，商业化再进一步。',
    ),
    _SimpleTopicSeed(
      topic: crossBorderTopic,
      source: '平台公告',
      kickoff: '跨境平台预告新一轮规则调整。',
      milestone: '平台同步更新物流和仓储策略。',
      recent: '24 小时内又有新补贴政策释放。',
      latest: '卖家大会正式定调新阶段运营策略。',
    ),
  ];

  static Map<String, List<TimelineEntry>> get entriesByTopic => <String, List<TimelineEntry>>{
        aiTopic.id: _withTestingCompanions(_aiEntries),
        chipTopic.id: _withTestingCompanions(_chipEntries),
        moonTopic.id: _withTestingCompanions(_moonEntries),
        for (final seed in _simpleTopicSeeds) seed.topic.id: _withTestingCompanions(_simpleEntries(seed)),
      };

  static List<TimelineEntry> _withTestingCompanions(List<TimelineEntry> entries) {
    final expanded = <TimelineEntry>[];
    for (final entry in entries) {
      expanded
        ..add(entry)
        ..addAll(_companionEntriesFor(entry));
    }
    expanded.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return expanded;
  }

  static List<TimelineEntry> _companionEntriesFor(TimelineEntry entry) {
    final baseTime = entry.timestamp;
    final firstCompanionTime = DateTime(
      baseTime.year,
      baseTime.month,
      baseTime.day,
      baseTime.hour,
      baseTime.minute,
      10,
    );
    final secondCompanionTime = DateTime(
      baseTime.year,
      baseTime.month,
      baseTime.day,
      baseTime.hour,
      baseTime.minute,
      20,
    );

    return <TimelineEntry>[
      TimelineEntry(
        id: '${entry.id}-follow-up',
        topicId: entry.topicId,
        title: '${entry.title} · 补充跟进',
        summary: '围绕该节点又出现一条补充动态。',
        detail: '${entry.summary} 之后，相关方继续释放增量信息，开始补充这一节点的背景和影响范围。',
        fullText:
            '在“${entry.title}”之后，又出现了一条补充跟进动态。新增信息主要围绕既有节点的背景、执行细节和影响范围展开，用来帮助测试同一时间节点下多条动态并列展示的效果。',
        sourceName: entry.sourceName,
        sourceKind: entry.sourceKind,
        sourceReliability: entry.sourceReliability,
        timestamp: firstCompanionTime,
        isMajor: false,
      ),
      TimelineEntry(
        id: '${entry.id}-signal',
        topicId: entry.topicId,
        title: '${entry.title} · 外部反馈',
        summary: '相关方给出新的外部反馈信号。',
        detail: '与该节点关联的外部反馈继续积累，专题判断因此多了一层验证信息。',
        fullText:
            '围绕“${entry.title}”的外部反馈继续增加，相关机构、合作方或观察者给出了新的验证信号。这条动态主要用于测试同一节点下展示 2-3 条关联动态时的阅读密度和层级表现。',
        sourceName: '${entry.sourceName} / 跟进',
        sourceKind: entry.sourceKind,
        sourceReliability: entry.sourceReliability,
        timestamp: secondCompanionTime,
        isMajor: false,
      ),
    ];
  }

  static List<TimelineEntry> _simpleEntries(_SimpleTopicSeed seed) {
    return <TimelineEntry>[
      _entry(
        topicId: seed.topic.id,
        daysAgo: 72,
        title: '关注启动',
        summary: seed.kickoff,
        detail: '围绕「${seed.topic.tagline}」的讨论开始成型。',
        fullText:
            '${seed.topic.name}的早期关注点开始聚集。${seed.kickoff}随着更多从业者和媒体加入讨论，这一专题开始从行业观察走向公共热点。',
        source: seed.source,
      ),
      _entry(
        topicId: seed.topic.id,
        daysAgo: 15,
        title: '关键节点出现',
        summary: seed.milestone,
        detail: '市场开始重新评估事件后续的兑现节奏。',
        fullText:
            '${seed.topic.name}出现关键节点后，专题热度明显抬升。${seed.milestone}这让围绕${seed.topic.tagline}的判断从预期讨论转向阶段验证。',
        source: seed.source,
        isMajor: true,
      ),
      _entry(
        topicId: seed.topic.id,
        daysAgo: 0,
        hoursAgo: 16,
        title: '24 小时新动态',
        summary: seed.recent,
        detail: '专题在最近一天继续积累增量信息。',
        fullText:
            '${seed.topic.name}在最近 24 小时继续出现新增动态。${seed.recent}这说明专题仍处在高频更新阶段，适合持续追踪。',
        source: seed.source,
      ),
      _entry(
        topicId: seed.topic.id,
        daysAgo: 0,
        hoursAgo: 3,
        title: '热度继续升温',
        summary: seed.latest,
        detail: '最新节点让关注度进一步集中。',
        fullText:
            '${seed.topic.name}的最新节点再次把外部注意力拉高。${seed.latest}如果后续还有确认性消息，这条时间线很可能继续快速推进。',
        source: seed.source,
        isMajor: true,
      ),
    ];
  }

  static TimelineEntry _entry({
    required String topicId,
    required int daysAgo,
    int hoursAgo = 0,
    required String title,
    required String summary,
    required String detail,
    required String fullText,
    required String source,
    bool isMajor = false,
  }) {
    final now = DateTime.now();
    final date = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      30,
    ).subtract(Duration(days: daysAgo, hours: hoursAgo));

    return TimelineEntry(
      id: '$topicId-$title-$daysAgo-$hoursAgo',
      topicId: topicId,
      title: title,
      summary: summary,
      detail: detail,
      fullText: fullText,
      sourceName: source,
      sourceKind: _inferSourceKind(source),
      sourceReliability: _inferSourceReliability(source),
      timestamp: date,
      isMajor: isMajor,
    );
  }

  static SourceKind _inferSourceKind(String source) {
    if (source.contains('官方') ||
        source.contains('公告') ||
        source.contains('发布') ||
        source.contains('通报')) {
      return SourceKind.official;
    }
    if (source.contains('报告') || source.contains('纪要')) {
      return SourceKind.research;
    }
    if (source.contains('社区') || source.contains('直播')) {
      return SourceKind.community;
    }
    if (source.contains('消息') || source.contains('渠道')) {
      return SourceKind.aggregator;
    }
    if (source.contains('媒体') || source.contains('博客') || source.contains('评测')) {
      return SourceKind.media;
    }
    return SourceKind.aggregator;
  }

  static SourceReliability _inferSourceReliability(String source) {
    if (source.contains('官方') ||
        source.contains('公告') ||
        source.contains('发布') ||
        source.contains('通报')) {
      return SourceReliability.high;
    }
    if (source.contains('报告') || source.contains('纪要') || source.contains('评测')) {
      return SourceReliability.medium;
    }
    if (source.contains('消息') || source.contains('渠道')) {
      return SourceReliability.low;
    }
    return SourceReliability.medium;
  }
}

class _SimpleTopicSeed {
  const _SimpleTopicSeed({
    required this.topic,
    required this.source,
    required this.kickoff,
    required this.milestone,
    required this.recent,
    required this.latest,
  });

  final Topic topic;
  final String source;
  final String kickoff;
  final String milestone;
  final String recent;
  final String latest;
}
