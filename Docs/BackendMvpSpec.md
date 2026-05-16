# 事件时间轴后端 MVP 规格

## 1. 目标

这版后端不是“给 Flutter 提供几个 demo 接口”，而是先搭一套可以正式演进的起步架构：

- 服务端成为唯一主数据源
- 本地缓存只负责加速与离线兜底
- `Topic / EventNode / TopicEventLink` 成为中心模型
- 用户关注、置顶、浏览历史、自建专题、分享都进入服务端
- 为后续新闻接入、去重、审核、版本管理预留结构

## 2. 技术选型

### 推荐方案

- API 服务：`FastAPI`
- 主数据库：`PostgreSQL`
- 缓存 / 短信验证码 / 限流：`Redis`
- 后续异步任务：独立 `worker`（可用 RQ / Celery / Dramatiq）

### 为什么这里优先 `FastAPI`

- 这是典型的数据建模与内容聚合型产品，`Python` 在数据清洗、去重、规则判断、后续 AI/抓取接入上更顺手
- `FastAPI` 自带强类型请求/响应模型和 OpenAPI，移动端联调成本低
- 对中小团队起步更快，先做“模块化单体”比一开始拆很多服务更稳
- 后续需要接入来源抓取、规则引擎、审核流、embedding/相似度判断时，不需要换栈

## 3. 最小可行正式架构

### 3.1 架构形态

起步阶段使用“模块化单体”：

- `Flutter App`
- `FastAPI Backend`
- `PostgreSQL`
- `Redis`（可选但推荐）

先不拆微服务，但在代码上按领域拆模块，后续可平滑拆出：

- 用户与认证
- 专题与定义
- 事件节点与来源
- 关注/同步/历史
- 分享
- 推荐
- 数据接入与质量控制

### 3.2 服务端职责

- 保存标准专题与自建专题
- 保存标准节点与自建节点
- 维护 `TopicEventLink` 多对多关系
- 保存用户关注、置顶、历史、排序偏好、选中专题
- 生成分享链接，并支持“实时分享”与“快照分享”
- 为多时间颗粒度时间轴提供原始节点和聚合桶
- 为后续去重、审核、版本管理预留表结构

### 3.3 数据同步原则

- 登录成功后，客户端通过 `bootstrap` 接口拉取用户状态
- 关注、置顶、浏览、分享、自建专题都先写服务端
- 客户端只保留缓存，不再把本地数据当权威答案
- 同一用户换手机重新登录后，服务端恢复其关注、偏好、自建专题与历史

## 4. 核心数据模型

### 4.1 领域主轴

#### `topics`

- 表示一个边界明确的专题
- 标准专题和用户自建专题都放在同一张表
- 通过 `kind`、`owner_user_id`、`visibility` 区分来源和权限

#### `event_nodes`

- 表示一条去重后的事实节点
- 只存一份事实，不因属于多个专题而复制
- 保存时间精度、重要度、可信度、审核状态

#### `topic_event_links`

- 表示“这个事件节点为什么属于这个专题”
- 保存关联角色、相关度、关联理由、显示桶提示
- 同一个 `event_node_id` 可以被多个 `topic_id` 引用

### 4.2 表设计

| 表名 | 作用 | 关键字段 |
|---|---|---|
| `users` | 用户主表 | `phone_number`, `nickname`, `avatar_url`, `timezone`, `locale` |
| `user_preferences` | 用户偏好 | `default_sort_order`, `selected_topic_id`, `home_recommendation_mode` |
| `user_sessions` | 登录会话 | `token_hash`, `device_id`, `client_platform`, `expires_at` |
| `sms_challenges` | 短信验证码记录 | `phone_number`, `code_hash`, `expires_at`, `consumed_at` |
| `topics` | 专题主表 | `kind`, `owner_user_id`, `title`, `description`, `core_keywords`, `start_time_*` |
| `topic_revisions` | 专题版本快照 | `topic_id`, `revision_number`, `change_summary` |
| `event_nodes` | 事件节点主表 | `canonical_key`, `event_time_at`, `time_precision`, `importance`, `confidence_score` |
| `event_node_revisions` | 节点版本快照 | `event_node_id`, `revision_number`, `change_summary` |
| `event_sources` | 节点来源证据 | `event_node_id`, `source_type`, `source_url`, `publisher_name`, `reliability_score` |
| `topic_event_links` | 专题与节点关联 | `topic_id`, `event_node_id`, `relation_role`, `relevance_score`, `link_reason` |
| `user_topic_follows` | 用户关注与置顶 | `user_id`, `topic_id`, `is_pinned`, `pin_rank`, `custom_sort_rank` |
| `topic_view_history` | 浏览历史 | `user_id`, `topic_id`, `event_node_id`, `opened_from`, `viewed_at` |
| `share_links` | 分享链接 | `code`, `topic_id`, `mode`, `allow_follow`, `snapshot_payload`, `expires_at` |

### 4.3 建模要点

- `topics` 只定义专题边界，不直接复制事实内容
- `event_nodes` 只定义事实节点及其证据
- `topic_event_links` 负责把事实放进不同专题语境
- 原文链接放在 `event_sources`，只作为证据和延伸阅读
- `topic_revisions` / `event_node_revisions` 先建好，为后续审核和版本管理留出口
- `share_links.mode = live | snapshot`
  - `live`：打开时读当前最新专题
  - `snapshot`：打开时读分享时刻冻结的快照

## 5. 主要 API

### 5.1 认证

- `POST /v1/auth/sms/send`
- `POST /v1/auth/sms/verify`
- `POST /v1/auth/logout`

### 5.2 启动同步

- `GET /v1/bootstrap`
  - 返回用户信息
  - 返回偏好设置
  - 返回关注列表
  - 返回浏览历史
  - 返回热门推荐

### 5.3 用户数据

- `GET /v1/me`
- `PATCH /v1/me/preferences`
- `GET /v1/me/follows`
- `POST /v1/me/follows`
- `PATCH /v1/me/follows/{topic_id}`
- `DELETE /v1/me/follows/{topic_id}`
- `GET /v1/me/history`
- `POST /v1/me/history`

### 5.4 专题与时间线

- `GET /v1/topics`
- `POST /v1/topics`
- `GET /v1/topics/{topic_id}`
- `GET /v1/topics/{topic_id}/timeline`
- `POST /v1/topics/{topic_id}/events`

### 5.5 分享

- `POST /v1/topics/{topic_id}/shares`
- `GET /v1/public/shares/{code}`

### 5.6 推荐

- `GET /v1/recommendations/hot`
- `GET /v1/recommendations/random`
- `GET /v1/recommendations/history`

## 6. 与 Flutter 现状的衔接方式

当前前端已有的本地概念可以平滑映射：

- 本地 `session` -> `users + user_sessions`
- 本地关注列表 -> `user_topic_follows`
- 本地置顶 -> `user_topic_follows.is_pinned/pin_rank`
- 本地浏览历史 -> `topic_view_history`
- 本地排序偏好 -> `user_preferences.default_sort_order`
- 本地自建时间线 -> `topics(kind=user_created)`
- 本地分享快照 -> `share_links(snapshot_payload)`

## 7. 后续扩展建议

- 引入 `Redis` 保存短信验证码、发送频控、推荐缓存
- 新增 `raw_ingest_records` 接外部新闻源原始数据
- 新增 `dedupe_jobs / review_tasks` 支持去重与审核
- 给 `event_nodes` 增加相似度指纹、实体提取结果与聚合规则
- 增加后台管理端，对标准专题和标准节点做审核、发布和回滚
