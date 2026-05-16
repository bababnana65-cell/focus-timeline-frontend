import Foundation

final class MockTimelineService: TimelineService {
    func fetchTrackedTopics() async throws -> [Topic] {
        try await Task.sleep(for: .milliseconds(180))
        return Array(SampleData.topics.prefix(2))
    }

    func fetchRecommendedTopics() async throws -> [Topic] {
        try await Task.sleep(for: .milliseconds(180))
        return SampleData.topics
    }

    func fetchTimeline(for topic: Topic) async throws -> [TimelineEntry] {
        try await Task.sleep(for: .milliseconds(260))
        return SampleData.entries[topic.id, default: []]
            .sorted { $0.timestamp < $1.timestamp }
    }
}

private enum SampleData {
    static let aiTopic = Topic(
        id: UUID(uuidString: "D0D89FC6-2A29-4692-9B8F-CB9F1144D0A1")!,
        name: "AI 大模型发布",
        tagline: "追踪模型发布时间、功能更新与外部反馈",
        followerCount: 18_240,
        isHot: true
    )

    static let chipTopic = Topic(
        id: UUID(uuidString: "36730117-3A34-4D5E-8B2A-7D1F63C0AD84")!,
        name: "全球半导体供应链",
        tagline: "关注扩产、政策、交付周期与价格变化",
        followerCount: 12_560,
        isHot: true
    )

    static let moonTopic = Topic(
        id: UUID(uuidString: "A88E5D50-DB49-4A5C-BADB-8AF7A8A7E56F")!,
        name: "载人登月计划",
        tagline: "跟踪任务节点、测试进展和关键窗口期",
        followerCount: 9_320,
        isHot: true
    )

    static let topics: [Topic] = [aiTopic, chipTopic, moonTopic]

    static let entries: [UUID: [TimelineEntry]] = [
        aiTopic.id: [
            makeEntry(topicID: aiTopic.id, daysAgo: 96, hoursAgo: 0, title: "项目立项确认", summary: "研发团队确认年度旗舰模型路线。", detail: "内部路线图首次明确参数规模、推理效率和多模态方向。", fullText: "研发团队在项目立项会上确认年度旗舰模型路线，目标是把更强的推理能力、多模态理解和更低延迟放进同一代产品。与此同时，产品团队开始准备外部测试名单和发布节奏。", source: "官方路线图", isMajor: false),
            makeEntry(topicID: aiTopic.id, daysAgo: 68, hoursAgo: 0, title: "首轮封闭测试", summary: "首批企业用户进入封闭测试。", detail: "测试重点集中在长上下文、代码生成和多轮工具调用能力。", fullText: "首批企业用户进入封闭测试后，反馈最集中的问题包括长上下文稳定性、工具调用容错和复杂代码任务的延迟。团队据此调整了推理链路和缓存策略。", source: "测试周报", isMajor: false),
            makeEntry(topicID: aiTopic.id, daysAgo: 24, hoursAgo: 0, title: "推理性能提升", summary: "新版推理引擎延迟明显下降。", detail: "在同等复杂度任务下，平均首 token 时间缩短约 22%。", fullText: "新版推理引擎完成一轮优化后，在复杂任务中的平均首 token 时间明显缩短，同时通过动态路由减少了不必要的高成本调用，这让大规模商用的可行性进一步提升。", source: "技术博客", isMajor: true),
            makeEntry(topicID: aiTopic.id, daysAgo: 11, hoursAgo: 0, title: "开发者文档预热", summary: "开发者文档和示例应用开始对外预热。", detail: "外部沟通重点从模型参数转向实际工作流接入效果。", fullText: "在开发者文档和示例应用开始预热后，外部讨论焦点逐步从模型参数转向真实工作流的适配，包括编码、知识库问答和自动化执行场景。", source: "开发者社区", isMajor: false),
            makeEntry(topicID: aiTopic.id, daysAgo: 3, hoursAgo: 0, title: "发布时间窗口传出", summary: "市场开始普遍预期发布时间窗口。", detail: "多家合作方开始提前准备接入公告和联动发布。", fullText: "随着合作方开始同步发布时间窗口，外界对新品发布时间的预期明显升高，多家生态伙伴同时准备兼容方案和演示案例，说明发布计划已进入最后压测阶段。", source: "合作伙伴消息", isMajor: false),
            makeEntry(topicID: aiTopic.id, daysAgo: 0, hoursAgo: 16, title: "发布会邀请函", summary: "官方发布会邀请函发出。", detail: "邀请函重点强调实时推理、视觉理解和工作流执行能力。", fullText: "官方发布会邀请函正式发出，文案不再强调单一 benchmark，而是突出实时推理、视觉理解、工作流执行和企业集成，说明产品定位更偏向可直接落地的生产力平台。", source: "官方公告", isMajor: true),
            makeEntry(topicID: aiTopic.id, daysAgo: 0, hoursAgo: 5, title: "媒体试玩解禁", summary: "首批媒体试玩内容同步解禁。", detail: "试玩内容显示新版本在复杂问题拆解上更稳定。", fullText: "媒体试玩解禁后，体验文章普遍认为模型在复杂问题拆解、连续指令遵循和图文混合理解上更稳定，但也有报道提到在极长链路任务中仍需要更明显的进度提示。", source: "媒体评测", isMajor: false),
            makeEntry(topicID: aiTopic.id, daysAgo: 0, hoursAgo: 1, title: "发布会开始", summary: "新品发布会进入正式直播。", detail: "直播同步展示了 API、应用端和企业版功能。", fullText: "发布会正式直播后，团队依次展示了 API、消费端应用和企业版产品线。演示重点在于如何把长推理、结构化输出和工具调用组合进完整任务流，而不只是展示单轮问答效果。", source: "直播现场", isMajor: true)
        ],
        chipTopic.id: [
            makeEntry(topicID: chipTopic.id, daysAgo: 110, hoursAgo: 0, title: "新厂扩建方案提出", summary: "头部厂商提交新一轮扩建方案。", detail: "方案聚焦先进封装和成熟制程并行扩产。", fullText: "头部厂商提交的新厂扩建方案显示，先进封装与成熟制程产能将同步扩展，以覆盖 AI、汽车电子和工业控制的不同需求周期。", source: "产业快讯", isMajor: false),
            makeEntry(topicID: chipTopic.id, daysAgo: 57, hoursAgo: 0, title: "设备交付推迟", summary: "关键设备交付节奏被迫顺延。", detail: "这使部分产线爬坡速度低于此前预期。", fullText: "由于关键设备交付延后，部分晶圆厂的产线爬坡进度受到影响，原本计划中的季度释放节奏需要重新评估。市场因此开始关注下游库存与交期的再平衡。", source: "设备渠道", isMajor: true),
            makeEntry(topicID: chipTopic.id, daysAgo: 34, hoursAgo: 0, title: "政策补贴落地", summary: "地方补贴方案正式落地。", detail: "补贴重点面向关键材料、封装和设计工具。", fullText: "地方补贴方案落地后，受益范围不仅覆盖晶圆制造，也扩展到关键材料、先进封装和设计工具链，这有助于提高供应链本地化稳定性。", source: "政策通报", isMajor: false),
            makeEntry(topicID: chipTopic.id, daysAgo: 14, hoursAgo: 0, title: "价格止跌信号出现", summary: "部分细分芯片价格出现止跌迹象。", detail: "终端补库存和车规需求回暖开始反映到报价。", fullText: "部分细分芯片价格出现止跌迹象，说明终端补库存和车规需求回暖已开始传导至报价体系，不过整体供需仍未完全恢复到紧平衡状态。", source: "渠道报价", isMajor: false),
            makeEntry(topicID: chipTopic.id, daysAgo: 6, hoursAgo: 0, title: "大客户签订长约", summary: "头部客户重新签订中长期供货协议。", detail: "长约锁量对季度排产预期形成支撑。", fullText: "头部客户重新签订中长期供货协议，意味着上游对后续季度排产更有把握，也反映出核心客户开始用锁量方式对冲未来可能的波动。", source: "供应链消息", isMajor: true),
            makeEntry(topicID: chipTopic.id, daysAgo: 0, hoursAgo: 20, title: "交货周期更新", summary: "最新交货周期整体缩短。", detail: "成熟制程产品交期改善最明显。", fullText: "最新交货周期更新显示，成熟制程产品的交期改善最为明显，而高端封装环节仍然偏紧，这意味着供应链恢复并不均匀。", source: "月度简报", isMajor: false),
            makeEntry(topicID: chipTopic.id, daysAgo: 0, hoursAgo: 7, title: "先进封装再扩产", summary: "先进封装产线宣布追加投资。", detail: "新增投资主要投向高带宽封装能力。", fullText: "先进封装产线再度宣布追加投资，新增预算主要用于高带宽封装能力建设，进一步说明 AI 带来的需求红利正从算力芯片延伸到整条封装链路。", source: "企业公告", isMajor: true),
            makeEntry(topicID: chipTopic.id, daysAgo: 0, hoursAgo: 2, title: "市场风险提示", summary: "机构提醒旺季需求仍需继续验证。", detail: "对下半年需求判断仍存在分歧。", fullText: "虽然近期供应链指标有所改善，但机构仍提醒旺季需求需要继续验证，尤其是消费电子复苏速度、企业资本支出节奏以及地缘政策变化，都会影响下半年的供需判断。", source: "研究报告", isMajor: false)
        ],
        moonTopic.id: [
            makeEntry(topicID: moonTopic.id, daysAgo: 140, hoursAgo: 0, title: "阶段任务确定", summary: "载人登月阶段任务正式拆解。", detail: "任务链路覆盖火箭、飞船、着陆器和地面支持系统。", fullText: "载人登月阶段任务完成拆解后，研制工作从单点突破转向多系统协同，重点变成飞行器集成测试和多部门联调。", source: "任务公告", isMajor: false),
            makeEntry(topicID: moonTopic.id, daysAgo: 82, hoursAgo: 0, title: "关键试验台架建成", summary: "关键试验台架完成搭建。", detail: "后续将进入高频率联调阶段。", fullText: "关键试验台架建成后，多项原先需要分散完成的验证任务可以并入同一联调流程，整体研发效率明显提升。", source: "工程进展", isMajor: false),
            makeEntry(topicID: moonTopic.id, daysAgo: 47, hoursAgo: 0, title: "地面综合演练", summary: "第一次全链路地面综合演练完成。", detail: "演练重点验证了时序协同和应急处置流程。", fullText: "第一次全链路地面综合演练完成后，工程团队开始针对通信时序、异常处置和多系统切换中的边界情况做专项复盘。", source: "演练通报", isMajor: true),
            makeEntry(topicID: moonTopic.id, daysAgo: 19, hoursAgo: 0, title: "发动机测试通过", summary: "关键发动机完成关键工况测试。", detail: "测试结果满足计划窗口要求。", fullText: "关键发动机测试通过，意味着后续更复杂的联试可以按计划推进，发射窗口安排的确定性随之增强。", source: "测试报告", isMajor: true),
            makeEntry(topicID: moonTopic.id, daysAgo: 4, hoursAgo: 0, title: "发射窗口研判", summary: "专家组对窗口期进行集中研判。", detail: "评估结果显示主计划与备份窗口均可行。", fullText: "专家组在集中研判后认为，当前主计划和备份窗口都具备可行性，但仍需关注后续天气与协同资源排布。", source: "专家纪要", isMajor: false),
            makeEntry(topicID: moonTopic.id, daysAgo: 0, hoursAgo: 11, title: "联试进入收尾", summary: "多系统联试进入收尾阶段。", detail: "各子系统开始提交最终状态报告。", fullText: "多系统联试进入收尾阶段，各子系统陆续提交最终状态报告，项目管理重点由技术问题清单转向发射前资源统筹和风险复核。", source: "项目例会", isMajor: false),
            makeEntry(topicID: moonTopic.id, daysAgo: 0, hoursAgo: 3, title: "重大节点确认", summary: "下一关键节点时间窗口正式确认。", detail: "官方确认后，项目节奏从准备态转向执行态。", fullText: "重大节点时间窗口正式确认后，整个项目从准备态转向执行态，意味着后续每一个状态更新都将直接影响公众和产业链对任务进展的判断。", source: "官方发布", isMajor: true)
        ]
    ]

    static func makeEntry(
        topicID: UUID,
        daysAgo: Int,
        hoursAgo: Int,
        title: String,
        summary: String,
        detail: String,
        fullText: String,
        source: String,
        isMajor: Bool
    ) -> TimelineEntry {
        let dayAdjusted = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let timestamp = Calendar.current.date(byAdding: .hour, value: -hoursAgo, to: dayAdjusted) ?? dayAdjusted

        return TimelineEntry(
            id: UUID(),
            topicID: topicID,
            title: title,
            summary: summary,
            detail: detail,
            fullText: fullText,
            sourceName: source,
            timestamp: timestamp,
            isMajor: isMajor
        )
    }
}

