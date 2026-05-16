# 事件时间轴 App · Timeline Tab Full Height Green v45 视觉规范
> 日期：2026-04-29  
> 范围：基于 v44 的底部时间轴 Tab 尺寸和配色调整，不修改 Flutter 代码  
> 关键调整：时间轴 Tab 选中图标高度对齐“我的关注”图标+文字整体，并改为绿色大色块、珊瑚红线条

## 本版调整

v45 只调整底部中间时间轴 Tab：

- 选中态 `.wrap` 背景改为透明，去掉外层圆形背景。
- 选中图标尺寸从 `38px` 放大到 `52px`，未选中图标为 `34px`。
- 选中图标上沿对齐“我的关注”选中图标上沿，下沿对齐“我的关注”文字底部。
- 外层触控槽保持 `58px × 52px`，保证命中面积和左右 Tab 高度对齐。
- 选中图标配色：绿色大色块 `#DFF2C7`、内部线条 `#F06F5D`。
- 未选中态继续保持低对比灰色，不抢当前页面主题。

## 继承调整

继承 v43 的推荐页专题卡片关注方向弱化：

- `.rec .copy` 使用 `12.4px / 500 / #8C93A3`。
- 推荐页里“跟踪冲突升级、军事动作、外交回应、能源航运风险与谈判窗口变化”与关注页同层级。
- 推荐页标题、已关注标签、关注人数不改。

## 继承调整

继承 v42 的“我的关注”专题卡片关注方向弱化：

- `.topic-body > .copy` 从 `12.8px / 580 / #6F7584` 调整为 `12.4px / 500 / #8C93A3`。
- 关注方向仍保留两行阅读，但显著低于标题和最新节点消息。
- `.topic-latest-row` 和 `.topic-latest-row .latest` 不降级，继续保持强权重与浅色底。

## 继承调整

继承 v41 的时间轴节点标题阅读列：

- `.timeline .node h3 / p` 宽度调整为 `248px`。
- `.timeline .node h3 / p` 显式使用 `text-wrap: wrap`，取消 `pretty` 的自动优化换行。
- 目标：让“伊朗导弹发射由威慑表态转为实际行动。”和“霍尔木兹航运专题开始出现实质性风险升级节点。”在同一阅读列内稳定换行。
- `.timeline .node .chev` 继续保持 `22px × 22px`。
- 箭头按钮位置继续为 `right: 8px; top: 15px`，位于日期胶囊同一行右侧。
- 这样标题阅读列和箭头控件形成固定分区，不再互相挤占。

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
- 图标选中尺寸为 `52px`，未选中尺寸为 `34px`，外层触控槽为 `58px × 52px`。
- 纯图标入口的上下视觉高度对齐左右 Tab 的“图标 + 文字”组合。
- 语义仍为 `时间轴`，通过 `aria-label` 保留，不改变底部三 Tab 业务含义。
- 时间轴节点右侧箭头继承 v40：日期行右侧 `right: 8px`。

## 组件规则

- `.app.mint .top .round:has(use[href="#plus"])`：我的关注页右上角新建按钮，统一为空列表页同款珊瑚色。
- `.topic-body > .copy`：`color: #8C93A3; font-size: 12.4px; font-weight: 500; line-height: 1.42`。
- `.rec .copy`：`color: #8C93A3; font-size: 12.4px; font-weight: 500; line-height: 1.42`。
- `.timeline .node h3, .timeline .node p`：`width: min(248px, calc(100% - 21px)); text-wrap: wrap`。
- `.timeline .node .chev`：`22px × 22px`，`right: 8px`，`top: 15px`。
- `.timeline-tab-mark`：默认 `30px × 30px`，第二个 Tab 纯图标态未选中为 `34px × 34px`，选中为 `52px × 52px`。
- `.bottom .nav:nth-child(2).timeline-icon-only .wrap`：`58px × 52px`，选中和未选中都不显示背景。
- `.bottom .nav:nth-child(2).timeline-icon-only`：移除文字节点，`gap: 0`，居中显示。
- `.bottom .nav:nth-child(2).active .timeline-tab-mark .mark-blob`：`#DFF2C7`。
- `.bottom .nav:nth-child(2).active .timeline-tab-mark .mark-main`：`#F06F5D`。
- `.bottom .nav:nth-child(2).active .timeline-tab-mark .mark-accent`：`#F06F5D`。
- `.bottom .nav:nth-child(2):not(.active)`：保持柔和灰色图标，不抢当前页面主题。

## 继承规则

- 时间轴箭头继承 v40：日期行右侧轻量圆形控件。
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

- `event-timeline-tab-full-height-green.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
