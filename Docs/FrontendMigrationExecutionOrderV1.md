# 前端迁移执行顺序清单 v1 定稿

目标：
- 不再继续扩字段和讨论模型
- 直接进入迁移执行
- 先稳定 DTO 和适配层
- 不先散改页面和视觉

执行原则：
1. 页面层继续吃现有 view model，不直接绑后端原始 JSON
2. 先加 DTO -> ViewModel 适配层
3. 先切 controller 和 service，最后再决定是否调整页面结构
4. AppLocalStorage 只做缓存镜像，不再做唯一数据源

---

## 阶段 0：冻结输入

### 本阶段目标
冻结当前迁移输入，不再继续扩字段。

### 输入基线
- 《前端迁移契约 v1 定稿》
- 《后端可实现性回执 v1》

### 要求
- 不再新增迁移字段
- 不再继续讨论命名细节
- 若后续有新增需求，进入 v2，不回写 v1

---

## 阶段 1：新增 DTO 与 Mapper，不动页面

### 本阶段目标
先把“后端返回”和“当前前端 view state”隔开。

### 同时固定 remote service 层
为避免 controller 直接绑定接口细节，本阶段同步固定 remote service 层。

建议新增以下远程数据入口或同等结构：
- `auth_remote_service.dart`
- `followed_topic_remote_service.dart`
- `timeline_remote_service.dart`
- `recommendation_remote_service.dart`
- `share_remote_service.dart`

要求：
- controller 不直接拼 URL、不直接处理原始接口细节
- DTO 解析和远程请求都先收口到 remote service 层
- mapper 只负责 DTO -> 当前 view state，不负责请求动作

### 先新增的 DTO
建议新增以下文件或同等结构：

1. `auth_dto.dart`
- `AuthLoginResponseDto`
- `AuthSessionDto`
- `UserSummaryDto`
- `IdentityDto`

2. `followed_topic_dto.dart`
- `FollowedTopicListDto`
- `FollowedTopicItemDto`
- `FollowMutationResultDto`

3. `topic_timeline_dto.dart`
- `TopicDetailDto`
- `TopicTimelineResponseDto`
- `TimelineEntryDto`
- `SourceDto`
- `TimelineSearchResultDto`

4. `recommendation_dto.dart`
- `RecommendationResponseDto`
- `RecommendationSectionDto`
- `RecommendationItemDto`
- `HistoryTopicDto`

5. `share_dto.dart`
- `ShareCreateResultDto`
- `ShareResolveDto`
- `SharePreviewDto`

### 再新增的 Mapper
建议新增：

1. `auth_mapper.dart`
- `AuthLoginResponseDto -> AuthSession/AuthViewState`

2. `followed_topic_mapper.dart`
- `FollowedTopicItemDto -> 当前 Topic 卡片 view model`

3. `timeline_mapper.dart`
- `TopicTimelineResponseDto -> TopicSummary + TimelineBucket[] + TimelineEntry view model`

4. `recommendation_mapper.dart`
- `RecommendationResponseDto -> 当前推荐页模式数据`

5. `share_mapper.dart`
- `ShareResolveDto -> 当前分享预览 view state`

### 当前阶段不要做的事
- 不改 widget 字段
- 不改页面布局
- 不重命名现有 view model 大面积字段
- 不先删旧模型

---

## 阶段 2：切 Auth

### 本阶段目标
先把登录态从“手机号登录结果”升级为“正式 session 模型”。

### 优先改动
1. `auth_models.dart`
- 扩成可容纳：
  - `sessionToken`
  - `refreshToken?`
  - `issuedAt`
  - `expiresAt`
  - `userId`
  - `identityType`
  - `provider`
  - `primaryPhone`

2. `phone_auth_service.dart`
- 接正式 Auth DTO
- 保留手机号验证码流程
- 去掉“手机号就是用户主体”的隐含假设

3. 登录态恢复逻辑
- `restoreSession()`
- `initialize()`
- 登录后用户信息缓存按 `userId` 键控

### controller 双轨兼容要求
- 当前登录 UI 不动
- 当前 masked phone 展示逻辑不动
- 先由 mapper 把新 DTO 投影回当前登录页面需要的数据

### 完成标志
- 登录页 UI 基本不变
- session 结构已正式化
- 后续所有接口可带正式 token

---

## 阶段 3：切“我的关注”

### 本阶段目标
把“我的关注”从本地事实源切成“服务端主导，本地缓存兜底”。

### 优先改动
1. `tracked topics` 对应 service / controller
- 新增 `refreshTrackedTopics()`
- 新增 follow/pin mutation 适配

2. `timeline_controller.dart`
- `_trackedTopics` 不再是唯一事实源
- 优先读 DTO + mapper 输出
- 本地仅保存缓存镜像

3. `app_local_storage.dart`
- 明确区分：
  - 正式服务端数据缓存
  - 本地缓存元数据（cachedAt/sourceGeneratedAt）

### controller 双轨兼容要求
- 页面卡片 UI 不动
- 左滑交互不动
- 搜索可先本地过滤缓存结果
- follow/unfollow/pin 先乐观更新，再用服务端回写修正

### 完成标志
- “我的关注”已能从服务端恢复
- 换设备后关注列表可恢复
- 本地缓存只是启动优化

---

## 阶段 4：切“时间轴”

### 本阶段目标
先替换时间轴数据输入，不重写页面渲染结构。

### 优先改动
1. `timeline_controller.dart`
- `loadTimelineForTopic(topicId)`
- `refreshSelectedTopic()`
- `searchTimeline(query)`
- `toggleMajorNodesOnly()`

2. 时间轴数据输入
- 从 `TopicTimelineResponseDto` 进入
- 由 `timeline_mapper.dart` 转成现有：
  - `Topic summary`
  - `TimelineBucket[]`
  - `TimelineEntry` 兼容 view state

3. 保留当前 bucket UI
- 继续使用 `TimelineBucket`
- 继续保留客户端 bucket 渲染结构
- 不强迫 widget 直接接 `topicEventLinkId / relationType` 原始字段

### 第一阶段兼容要求
- `TimelineEntry.id` 优先映射 `topicEventLinkId`
- `timestamp` 先映射 `sortTime`
- `isMajor` 先映射 `contextualMajor`
- 来源展示先用 `primarySource`
- `sources[]` 先挂在 entry view model 上备用

### ID 迁移约束
本阶段必须统一检查所有依赖 `TimelineEntry.id` 的本地状态，避免切到 `topicEventLinkId` 后局部状态错位或丢失。

至少检查：
- 节点展开状态
- 搜索定位
- 历史记录
- 本地缓存 key
- 任何以 `TimelineEntry.id` 作为稳定条目标识的 UI 状态

要求：
- 第一阶段统一以 `topicEventLinkId` 作为稳定条目标识
- 若局部仍保留旧 `id` 兼容，必须标记为过渡逻辑

### 当前阶段不要做的事
- 不重写 `timeline_screen.dart`
- 不重写 `timeline_bucket_card.dart`
- 不把四层模型直接塞进 widget

### 完成标志
- 时间轴页面视觉基本不变
- 数据来源已经切到后端 DTO
- 搜索和重大节点筛选继续可用

---

## 阶段 5：切 Share

### 本阶段目标
把分享底层从本地 payload/deep link 迁到服务端 `shareToken`。

### 优先改动
1. `topic_share_service.dart`
- 不再本地拼完整 payload
- 改成请求 `POST /shares`
- 用 `GET /shares/{token}` 解析分享

2. `timeline_controller.dart`
- `resolveSharedTopic(token)`
- `openPendingSharedTopic()`
- `followSharedTopicAndOpen()`

### controller 双轨兼容要求
- “仅查看 / 关注并查看”弹层不动
- 分享预览 UI 不动
- 只替换底层来源

### 完成标志
- 分享链接不再依赖本地 topic + entries 编码
- 分享预览来自服务端返回

---

## 阶段 6：切 Recommendation

### 本阶段目标
先让 controller 能消费新推荐分区结构，再决定是否改页面。

### 优先改动
1. `recommendations` 对应 service / controller
- `loadRecommendations()`
- 从 `sections + history` 构建当前页面所需数据

2. `timeline_controller.dart`
- 当前热门/随机/历史的本地生成逻辑逐步下沉
- 先保留页面模式切换，但底层来源改成服务端

### controller 双轨兼容要求
- 当前推荐页 UI 可暂时不改成多分区布局
- 当前页面仍可显示：
  - 热门
  - 探索/随机
  - 历史
- 由 controller 把新分区 DTO 投影成旧模式

### 当前阶段不要做的事
- 不先大改推荐页布局
- 不先改卡片组件
- 不先重写搜索

### 完成标志
- 推荐底层来源已服务端化
- 前端不再自己算 hot/random
- 页面结构是否升级到多分区，可作为下一步单独决策

---

## 阶段 7：最后切“新建时间线”

### 本阶段目标
让“新建时间线”从本地造 Topic/Entry 迁到正式 TopicDefinition 提交流程。

### 优先改动
1. `timeline_creation_service.dart`
- 保留当前 draft 流程
- 先把 draft 结构对齐 `TopicDefinition`
- 逐步切到服务端扩写 / 创建接口

2. `timeline_controller.dart`
- 不再本地直接创建完整 Topic + seed entries
- 改成：
  - 提交定义
  - 等待服务端创建 topic
  - 创建成功后进入时间轴

### 兼容要求
- 创建弹层 UI 先不动
- 本地 draft 可保留
- 本地种子节点生成逻辑最后再下线

### 完成标志
- 自建专题不再依赖本地完整 mock 生成
- 正式进入服务端 TopicDefinition 模型

---

## controller 双轨兼容建议

在迁移过程中，以下方法建议先做双轨兼容：

- `initialize()`
- `loadInitialData()`
- `refreshTrackedTopics()`
- `loadTimelineForTopic()`
- `refreshSelectedTopic()`
- `loadRecommendations()`
- `resolveSharedTopic()`

双轨兼容原则：
- 优先走新 DTO 路径
- 若接口未完成或失败，可短期 fallback 到旧本地数据
- fallback 只作为过渡，不再继续扩展旧逻辑

### 退出条件
双轨兼容必须有退出条件：
- 一旦对应接口稳定，旧本地逻辑停止扩展
- 不允许新旧两套逻辑长期同时演化
- 每完成一个阶段，都要明确记录哪些 fallback 已可以移除

---

## 页面暂时完全不动的范围

以下页面在前几阶段建议尽量不动视觉和结构：

- `registration_gate_screen.dart`
- `tracked_topics_screen.dart`
- `timeline_screen.dart`
- `recommendations_screen.dart`
- `source_article_screen.dart`
- 分享相关弹层

优先改 service、controller、mapper，最后再评估页面是否需要配合调整。

---

## 推荐的文件改动顺序

### 第一批
- DTO 文件
- Mapper 文件
- Remote service 文件
- Auth service / model

### 第二批
- Follow service / controller
- Local storage 缓存结构

### 第三批
- Timeline service / controller / mapper

### 第四批
- Share service / controller

### 第五批
- Recommendation service / controller

### 第六批
- Timeline creation service / controller

---

## 每阶段完成后都要做的检查

1. 页面视觉是否基本不变
2. controller 是否已经优先走 DTO
3. 本地缓存是否已经降级为镜像
4. 接口失败时是否仍可有限 fallback
5. 是否新增了不必要的页面字段耦合
6. 是否把后端原始字段直接泄露到 widget 层

---

## 当前阶段最重要的一句话

先换“数据入口”，再换“页面结构”。

不要反过来。
