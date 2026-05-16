# 事件时间轴 App · Map Markers v12 视觉规范
> 日期：2026-04-28  
> 范围：视觉设计交付，不修改 Flutter 代码  
> 关键要求：地图标记风；新闻文字阅读优先；图标低占比；不使用渐变色；不使用不规则多边形色块；不使用黑色或深色填充块；页面逻辑、入口、文案和业务规则保持当前截图语义

## 设计方向

方向名：**Map Markers Timeline / 地图标记时间轴**

- 把专题看成“正在追踪的地点/站点”，把时间节点看成“路线上的标记点”。
- 使用小路线点、轻路径线、坐标式标签和站点感建立差异化。
- 不做大地图、不引入真实地理功能，不改变业务规则。
- 图标只作为轻提示，标题、摘要、日期和最新动态仍是第一信息层。
- 推荐、关注和时间轴保持同一套“路径标记”语言。

## 色彩 Token

```css
--canvas: #f7fafe;
--canvas-mint: #f6fbfa;
--surface: #ffffff;
--ink: #172237;
--muted: #68758a;
--line: #dce8f1;
--blue: #438cff;
--blue-deep: #2f72d6;
--mint: #32c89b;
--mint-soft: #e9f9f1;
--coral: #ff746b;
--coral-soft: #fff1ef;
--lavender: #8d86f5;
--lavender-soft: #f2f0ff;
--red: #e94c57;
--green: #1f9e74;
--paper-blue: #f2f7ff;
--paper-rose: #fff7f6;
--route-line: #cfe1ee;
```

## 组件原则

- 推荐卡片：左侧小路线点和 POINT 标签，正文列保持主宽度。
- 我的关注卡片：左侧小站点点位，当前、新动态、准备中使用浅色卡片状态。
- 时间轴节点：保留日期列，节点以 ROUTE MARK / MAJOR MARK 标签强化进展路线感。
- 推荐分类：四等分轻分段控件，文案固定为 `可能关心 / 当前热门 / 随机看看 / 历史记录`。
- 新动态：保留底部红点 + 卡片红点 + 最新动态浅蓝高亮。
- 顶部和底部导航：图标保持小体量，不抢正文注意力。

## 禁用规则

- 不使用 `linear-gradient`、`radial-gradient` 或 `conic-gradient`。
- 不使用 `clip-path` 绘制装饰色块。
- 不使用黑色或深色填充块作为按钮、Toast、导航选中态或重点背景。
- 不新增通知中心、我的专题、编辑、删除或归档入口。

## 文案和逻辑锁定

- 推荐分类：`可能关心 / 当前热门 / 随机看看 / 历史记录`。
- 底部 Tab：`我的关注 / 时间轴 / 推荐`。
- 时间轴更多菜单：`新建时间线 / 分享 / 取消关注 / 时间顺序`。
- 新建流程：`新建时间线 -> 关键词 -> AI 扩写 -> 专题定义确认`。

## 交付文件

- `event-timeline-map-markers.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
