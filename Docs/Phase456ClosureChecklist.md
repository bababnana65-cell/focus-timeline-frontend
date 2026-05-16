# 阶段 4/5/6 收口清单

本文用于收口当前前端迁移中与“时间轴 / Share / Recommendation”相关的剩余兼容分支，避免继续扩展旧本地逻辑。

## 1. 时间轴

### 已完成收口
- 服务端专题的时间轴主数据源已经切到 `TopicRemoteService -> TopicTimelineMapper -> TimelineBucket/TimelineEntry view model`
- 服务端专题远端失败时，不再回退到本地 repository 时间轴作为事实源
- `TimelineEntry.id` 已稳定映射 `topicEventLinkId`
- 搜索结果、重大节点筛选、分桶都建立在 DTO -> mapper -> view model 链路上

### 当前仍保留的旧本地逻辑
- `custom/shared` 专题仍然使用本地 `_entriesByTopic`
- `custom/shared` 的时间轴搜索仍允许本地过滤 fallback
- `_seedTimelineSearchEntries()` 仍保留，用于搜索输入时的临时命中展示
- `_buildTimelineBuckets()` 仍保留，用于：
  - `custom/shared` 专题
  - 搜索临时命中结果
  - 本地草稿 / 导入专题

### 为什么暂时保留
- `custom/shared` 还没有正式服务端时间轴接口
- 阶段 7（新建时间线）仍然冻结后置

### 删除条件
- 后端提供 `custom/shared` 专题的正式时间轴读取与搜索接口
- 新建时间线切到正式服务端创建链路
- 页面不再需要本地草稿节点作为唯一事实源

## 2. Share

### 已完成收口
- 服务端专题的分享创建已经走 `_shareRemoteService.createShare()`
- 服务端专题的分享解析已经走 `_shareRemoteService.resolveShare()`
- 服务端专题的“关注并查看”已经改成走 `followTopic()`，不再只在本地临时加入关注列表

### 当前仍保留的本地兼容分支
- `TopicShareService.buildShareMessage()` 仍保留，但只用于非服务端专题
- `TopicShareService.buildShareLink()/parseIncomingRoute()` 仍保留，用于本地 payload 导入流
- `_consumeImportedSharedTopic()` 仍保留，只服务于 imported payload 的 `custom/shared` 时间线

### 为什么暂时保留
- 当前 `custom/shared` 时间线仍存在本地分享与导入需求
- 后端第一阶段 `shareType` 固定为 `topic`，尚未覆盖本地 payload 迁移场景

### 删除条件
- 后端支持 `custom/shared` 时间线的标准分享与解析
- 本地 payload 分享不再需要兼容

## 3. Recommendation

### 已完成收口
- 推荐页底层已经切到 `/recommendations`
- `hot/random/history` 不再由前端本地生成事实列表
- controller 已将 `personalized / hot / explore / history` 投影为当前页面模式

### 当前仍保留的兼容逻辑
- `historyTopics` 仍然是“远端 history + 本地仅有 history”的合并结果
- 推荐页搜索仍然基于当前本地 `searchableRecommendationTopics` 做本地过滤
- 页面仍以 `热门 / 随机 / 历史` 模式展示，而不是直接渲染分区结构

### 为什么暂时保留
- 本地 `custom/shared` 被浏览后，后端暂时还不知道这些历史
- 当前阶段不改推荐页结构与视觉

### 删除条件
- 后端提供覆盖 `custom/shared` 的统一历史记录语义，或相关场景完成服务端化
- 推荐页升级到正式分区布局
- 建立服务端搜索接口后，推荐页搜索不再依赖本地 topic 集合

## 4. 不再继续扩展的分支

以下分支已明确不再继续扩展：
- 服务端专题时间轴的 repository fallback
- 服务端专题分享创建失败时回退本地 payload
- 前端本地生成 hot/random 推荐列表

## 5. 联调核对结果

当前已通过 controller/service 层联调回归覆盖以下链路：
- 登录后恢复 session 与进入“我的关注”
- 打开时间轴并读取服务端时间轴 DTO
- 搜索时间轴并保留 `topicEventLinkId` 映射
- 分享创建 / 分享解析 / 关注并查看
- 推荐页 `personalized / hot / explore / history` 投影

注意：
- 以上联调基于当前前端 remote-service 契约 mock 与 controller 集成测试完成
- 当前应用运行时仍注入 `MockAuthRemoteService / MockFollowedTopicRemoteService / MockTopicRemoteService / MockRecommendationRemoteService / MockShareRemoteService`
- 当前工作区未绑定真实后端运行环境，因此“真实后端在线联调”仍需后端环境准备完成后再做一次端到端验证

## 6. 本阶段结束标准

阶段 4/5/6 现在可以视为“已基本完成”，后续只做：
- 删除条件满足后的兼容分支清理
- 真实后端联调下的问题修补

不再继续为 v1 迁移扩字段或扩展旧本地逻辑。
