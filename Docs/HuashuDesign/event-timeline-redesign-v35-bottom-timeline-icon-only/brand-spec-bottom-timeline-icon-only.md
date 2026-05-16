# 事件时间轴 App · Bottom Timeline Icon Only v35 视觉规范
> 日期：2026-04-29  
> 范围：基于 v34 的底部中间 Tab 图标与文字关系微调，不修改 Flutter 代码  
> 关键调整：移除底部中间 Tab 的“时间轴”文字，只保留放大的 App 图标

## 本版调整

v35 只调整底部导航中间“时间轴”Tab：

- 图标资产来自 `Docs/HuashuDesign/app icon/timeline_app_icon_mark_transparent.svg`。
- 使用内联 SVG 路径，便于根据状态调色。
- 选中态：时间轴主题绿色为主，辅以柔和珊瑚色时间线笔触。
- 未选中态：灰色主笔触 + 浅灰绿色底形，避免深色块。
- 底部 Tab 不显示 `时间轴` 文字，视觉上是纯图标入口。
- 图标尺寸为 `42px`，外层触控槽为 `58px × 52px`。
- 纯图标入口的上下视觉高度对齐左右 Tab 的“图标 + 文字”组合。
- 语义仍为 `时间轴`，通过 `aria-label` 保留，不改变底部三 Tab 业务含义。
- 时间轴节点右侧箭头继续继承 v33：卡片内 `right: 10px`。

## 组件规则

- `.timeline-tab-mark`：默认 `30px × 30px`，第二个 Tab 纯图标态提升为 `42px × 42px`。
- `.bottom .nav:nth-child(2).timeline-icon-only .wrap`：`58px × 52px`。
- `.bottom .nav:nth-child(2).timeline-icon-only`：移除文字节点，`gap: 0`，居中显示。
- `.bottom .nav:nth-child(2).active .timeline-tab-mark .mark-main`：使用 `var(--theme-deep)`。
- `.bottom .nav:nth-child(2).active .timeline-tab-mark .mark-accent`：使用 `var(--accent-b)`。
- `.bottom .nav:nth-child(2):not(.active)`：保持柔和灰色图标，不抢当前页面主题。

## 继承规则

- 时间轴箭头继承 v33：卡片内原位置。
- 文本右边界继承 v32：推荐、我的关注、时间轴主阅读列保持统一。
- 推荐卡片继承 v30：左侧原图标保留，已关注放到图标下方。
- 当前专题继承 v31：当前状态只通过卡片态表达。
- 时间轴顶部统计区保持单行胶囊。
- 时间轴节点圆点保持 v23 放大样式。
- 推荐分类：`可能关心 / 当前热门 / 随机看看 / 历史记录`。
- 底部 Tab 业务语义：`我的关注 / 时间轴 / 推荐`，其中中间入口视觉上只显示图标。
- 时间轴更多菜单：`新建时间线 / 分享 / 取消关注 / 时间顺序`。
- 不新增通知中心、我的专题、编辑、删除或归档入口。

## 交付文件

- `event-timeline-bottom-timeline-icon-only.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
