# 事件时间轴 App · Bottom Timeline App Icon v34 视觉规范
> 日期：2026-04-29  
> 范围：基于 v33 的底部中间 Tab 图标微调，不修改 Flutter 代码  
> 关键调整：用用户提供的 App 图标内标记替换“时间轴”Tab 原 clock 图标

## 本版调整

v34 只调整底部导航中间“时间轴”Tab：

- 图标资产来自 `Docs/HuashuDesign/app icon/timeline_app_icon_mark_transparent.svg`。
- 使用内联 SVG symbol，便于根据状态调色。
- 选中态：时间轴主题绿色为主，辅以柔和珊瑚色时间线笔触。
- 未选中态：灰色主笔触 + 浅灰绿色底形，避免深色块。
- 图标尺寸为 `30px`，位于原 `34px` 高的 Tab 图标槽内，和“我的关注”上下对齐。
- 文案仍为 `时间轴`，底部三 Tab 语义不变。
- 时间轴节点右侧箭头继续继承 v33：卡片内 `right: 10px`。

## 组件规则

- `.timeline-tab-mark`：`30px × 30px`，放在第二个 Tab 的 `.wrap` 中。
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
- 底部 Tab：`我的关注 / 时间轴 / 推荐`。
- 时间轴更多菜单：`新建时间线 / 分享 / 取消关注 / 时间顺序`。
- 不新增通知中心、我的专题、编辑、删除或归档入口。

## 交付文件

- `event-timeline-bottom-timeline-app-icon.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
