# 事件时间轴 App · My Following Plus Color v36 视觉规范
> 日期：2026-04-29  
> 范围：基于 v35 的“我的关注”顶部新建按钮颜色微调，不修改 Flutter 代码  
> 关键调整：将当前专题页右上角加号调整为与空列表页一致的珊瑚色状态

## 本版调整

v36 只调整“我的关注”主题里的右上角新建按钮：

- `.app.mint .top .round:has(use[href="#plus"])` 使用当前“我的关注”主题色。
- 背景：`var(--theme-soft)`，即空列表页同款浅珊瑚底。
- 描边：`var(--theme-line)`。
- 图标：`var(--theme-deep)`，即空列表页同款珊瑚红。
- 推荐页、时间轴页和新建确认页的加号颜色不受影响。

## 继承调整

继承 v35 的底部导航中间“时间轴”Tab：

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

- `.app.mint .top .round:has(use[href="#plus"])`：我的关注页右上角新建按钮，统一为空列表页同款珊瑚色。
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

- `event-timeline-my-following-plus-color.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
