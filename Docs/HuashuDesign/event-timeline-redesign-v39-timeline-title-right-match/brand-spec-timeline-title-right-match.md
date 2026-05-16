# 事件时间轴 App · Timeline Title Right Match v39 视觉规范
> 日期：2026-04-29  
> 范围：基于 v38 的时间轴节点文字右边界调整，不修改 Flutter 代码  
> 关键调整：让时间轴节点标题右边界与“我的关注”专题标题右边界一致

## 本版调整

v39 只调整时间轴节点标题、摘要和右侧箭头：

- `.timeline .node h3 / p` 宽度调整为 `264px`。
- 目标：时间轴节点标题右边距与“我的关注”卡片里的专题标题右边距一致。
- `.timeline .node .chev` 从 `28px` 缩小为 `16px`。
- 箭头按钮位置为 `right: 1px; top: 17px`，不再占用标题文本框宽度。

## 继承调整

继承 v38 的长文案检查：

- 专题标题使用更长的描述，例如 `美伊战争总体进展与区域安全态势持续追踪`。
- 关注方向使用更完整的范围描述，覆盖冲突、军事、外交、能源航运和谈判窗口。
- 最新摘要使用更长的节点消息，用于检查段落换行、行高、卡片高度和右侧留白。
- 推荐卡片和我的关注卡片都会显示长文案。

继承 v36 的“我的关注”主题右上角新建按钮：

- `.app.mint .top .round:has(use[href="#plus"])` 使用当前“我的关注”主题色。
- 背景：`var(--theme-soft)`，即空列表页同款浅珊瑚底。
- 描边：`var(--theme-line)`。
- 图标：`var(--theme-deep)`，即空列表页同款珊瑚红。
- 推荐页、时间轴页和新建确认页的加号颜色不受影响。

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
- `.timeline .node h3, .timeline .node p`：`width: min(264px, calc(100% - 21px))`。
- `.timeline .node .chev`：`16px × 16px`，`right: 1px`。
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

- `event-timeline-timeline-title-right-match.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
