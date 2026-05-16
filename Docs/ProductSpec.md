# 产品规格说明

## 1. 产品定位

“事件时间轴”是一个聚合型信息产品，面向需要持续追踪公共事件、行业动态或专题进展的用户。核心体验不是“看一篇新闻”，而是“看一个事件如何持续发展”。

## 2. MVP 目标

- 让用户可以关注多个事件专题
- 用时间轴而不是信息流来理解进展
- 快速识别重大节点与阶段性转折
- 减少早期长尾信息对主时间轴的视觉干扰

## 3. 功能映射

### 时间轴

- 默认时间单位：天
- 最近 24 小时可切到小时粒度
- 历史超过阈值后按月归档
- 长跨度事件按年 / 十年 / 世纪自动切换颗粒度
- 支持升序 / 降序
- 默认正序，最新内容位于底部

### 节点内容

- 日期后显示当期梗概
- 同时显示该时间段事件数量
- 重大事件使用高亮图标
- 首次点击展开细节
- 再次点击进入全文

### 用户体系

- 注册后可维护多个关注事件
- 可从热门推荐直接关注
- 保留手动刷新入口

## 4. 页面结构

### A. 时间轴页

- 顶部：当前关注专题、切换专题、排序、刷新
- 中部：竖向时间轴
- 节点：时间标签、摘要、数量、重大标识
- 展开态：节点下列出当期详细事件
- 二次点击：全文页

### B. 热门推荐页

- 推荐热点专题卡片
- 展示热度、标签和一句话摘要
- 支持一键关注

### C. 我的关注页

- 已关注专题列表
- 设置当前默认专题
- 取消关注
- 未来可扩展通知偏好、数据同步

## 5. 数据模型建议

### User

- id
- nickname
- avatar_url
- created_at

### Topic

- id
- name
- tagline
- heat_score
- is_hot

### Subscription

- id
- user_id
- topic_id
- is_default
- created_at

### Event

- id
- topic_id
- title
- summary
- detail
- full_text
- source_name
- published_at
- is_major

## 6. API 建议

- `POST /auth/register`
- `GET /topics/hot`
- `GET /topics/subscribed`
- `POST /topics/{id}/subscribe`
- `DELETE /topics/{id}/subscribe`
- `GET /topics/{id}/timeline?sort=asc`
- `POST /topics/{id}/refresh`

## 7. 推荐的后续增强

- 事件来源去重与合并
- AI 自动生成阶段性总结
- 节点可信度分层
- 消息通知与重大节点提醒
- 多维筛选：来源、地区、阶段、情绪

## 8. 相关规格

- 多尺度时间轴规则见 `Docs/TimelineGranularitySpec.md`
- 客户端与服务端职责见 `Docs/ClientServerArchitecture.md`
