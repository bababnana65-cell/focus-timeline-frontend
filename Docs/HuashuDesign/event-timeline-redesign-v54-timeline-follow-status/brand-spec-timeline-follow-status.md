# 事件时间轴 App · Timeline Follow Status v54 视觉规范
> 日期：2026-04-30  
> 范围：基于 v53 的时间轴详情页上下文提示优化，不修改 Flutter 代码  
> 关键调整：轻量提示当前时间线是否已关注，并用一行弱化文字给出关注方向

## 本版调整

v54 只调整时间轴详情页顶部上下文：

- `.timeline-context` 放在统计条 `.stats` 上方，不占用时间节点列表空间。
- `.follow-state` 使用 `已关注` 小胶囊，提示当前时间线状态，但不替代更多菜单里的“取消关注”。
- `.direction` 使用一行灰色弱化文本，展示关注方向并以省略号收口。
- 关注方向示例：`跟踪冲突升级、军事动作、外交回应、能源航运风险与谈判窗口变化`。
- 不新增关注按钮、通知入口、详情编辑入口，也不改变时间轴节点结构。

## 继承调整

继承 v53 的“我的关注”页专题卡片：

- `.app.mint .topic-body > .copy` 降为一行弱化信息，避免每张卡都出现多段灰字。
- `.app.mint .topic-latest-row .latest` 改成两行浅色更新条，让用户优先读最新节点消息。
- 卡片 `padding / margin / line-height` 略增加，让列表更适合手机碎片化扫读。
- 未读卡片的红色降低面积感，只保留边框、红点和最新消息强调。
- 不改变关注列表业务信息、入口、状态流和点击模型。

## 继承调整

继承 v52 的绿色竖向轨道上下位置：

- `.timeline::after` 浅绿色轨道改为 `top: 4px; bottom: 0`。
- `.timeline::before` 深绿色轨道改为 `top: 4px; bottom: 0`。
- `.timeline .node:last-of-type::after` 最新节点虚线段改为 `bottom: 0`。
- 圆点、日期胶囊、横向连接线、节点卡片和文字位置不变。

## 继承调整

继承 v51 的最新节点侧边深色轨道：

- `.timeline .node:last-of-type::after` 覆盖原本连续的深绿色实线。
- 覆盖段使用同位置的绿色虚线，提示该节点是最新节点信息。
- 浅绿色轨道背景保留，圆点、日期胶囊、横向连接线、节点卡片和文字位置不变。
- 只作用在每组 `.timeline` 的最后一个节点。

## 继承调整

继承 v50 的时间轴节点日期胶囊：

- 普通节点 `.timeline .node .node-date` 使用白底、绿色描边、绿色文字，匹配普通绿色数字圆点。
- 重大节点 `.timeline .node.major .node-date` 使用珊瑚红底、珊瑚红描边、珊瑚红文字，匹配左侧 `1 / 4` 重大节点圆点。
- 不改变日期胶囊位置、卡片左边界、横线连接、标题和摘要排版。

## 继承调整

继承 v49 的时间轴左侧节点流线：

- `.timeline .node .count-dot` 从 v48 的视觉偏右位置复原，使用 `left: -41px`。
- `.timeline .node:not(.major) .count-dot` 加深绿色描边为 `rgba(127, 198, 62, .62)`。
- `.timeline .node::before` 横线从 `11px` 延长到 `17px`，从圆点右边缘连接到白色节点卡片左边缘。
- 不改变日期标签、标题、摘要、右侧箭头和底部 Tab。

## 继承调整

继承 v48 的时间轴节点卡片：

- `.timeline .node` 增加 `margin-left: 12px`，让白色卡片左边界向内收进。
- `.timeline .node .node-date / h3 / p` 的 `margin-left` 从 `21px` 调整为 `9px`，抵消卡片位移。
- 日期标签、节点标题、节点摘要的屏幕坐标保持不变。
- 右侧箭头位置和阅读列右边界保持 v47 状态。

## 继承调整

继承 v47 的底部中间时间轴 Tab：

- 选中态 `.wrap` 背景改为透明，去掉外层圆形背景。
- 选中和未选中图标都统一为 `52px`。
- 图标上沿对齐“我的关注”选中图标上沿，下沿对齐“我的关注”文字底部。
- 对照 `Docs/HuashuDesign/app icon/timeline_app_icon_mark_transparent.svg` 恢复原始 6 层结构：阴影层、主色块、两条后置线条、两条前置线条。
- 外层触控槽保持 `58px × 52px`，保证命中面积和左右 Tab 高度对齐。
- 选中图标配色：绿色主色块 `#DFF2C7`、绿色阴影 `#86A866`、低饱和珊瑚棕线条 `#B87667 / #C98778`。
- 未选中态保留阴影和双层线条结构，改为与“推荐”Tab 同类的中性灰配色，不抢当前页面主题。

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
- 未选中态：灰色主笔触 + 浅灰色底形，避免深色块。
- 底部 Tab 不显示 `时间轴` 文字，视觉上是纯图标入口。
- 图标选中和未选中尺寸均为 `52px`，外层触控槽为 `58px × 52px`。
- 纯图标入口的上下视觉高度对齐左右 Tab 的“图标 + 文字”组合。
- 语义仍为 `时间轴`，通过 `aria-label` 保留，不改变底部三 Tab 业务含义。
- 时间轴节点右侧箭头继承 v40：日期行右侧 `right: 8px`。

## 组件规则

- `.app.mint .topic`：更大留白与间距，`padding: 18px 18px 19px; margin-bottom: 18px`。
- `.app.mint .topic-body > .copy`：一行截断，`12.1px / 480 / #9AA1AD`。
- `.app.mint .topic-latest-row .latest`：两行截断，浅色更新条，强化最新节点消息。
- `.app.mint .topic.unread`：降低红色面积感，保留未读红点和最新消息高亮。
- `.timeline::after`：`top: 4px; bottom: 0`，只调整浅绿色轨道上下边界。
- `.timeline::before`：`top: 4px; bottom: 0`，只调整深绿色轨道上下边界。
- `.timeline .node:last-of-type::after`：`bottom: 0`，让最新节点虚线段与轨道底部对齐。
- `.timeline .node:last-of-type::after`：在最新节点侧边绘制 `2px` 深绿色虚线。
- 虚线覆盖范围：`top: 30px; bottom: 18px; left: -34px; width: 10px`。
- `.timeline .node .node-date`：`background: #fff; border: 2px solid rgba(127, 198, 62, .62); color: var(--theme-deep)`。
- `.timeline .node.major .node-date`：`background: var(--coral-soft); border-color: rgba(240, 91, 85, .20); color: #c84843`。
- `.timeline .node .count-dot`：`left: -41px`，复原圆形节点图标位置。
- `.timeline .node:not(.major) .count-dot`：`border-color: rgba(127, 198, 62, .62)`。
- `.timeline .node::before`：`left: -17px; width: 17px`，横线完整连接圆点和卡片边缘。
- `.timeline .node`：`margin-left: 12px`，只改变白色卡片左边界。
- `.timeline .node .node-date, .timeline .node h3, .timeline .node p`：`margin-left: 9px`，让内部内容维持原位置。
- `.app.mint .top .round:has(use[href="#plus"])`：我的关注页右上角新建按钮，统一为空列表页同款珊瑚色。
- `.topic-body > .copy`：`color: #8C93A3; font-size: 12.4px; font-weight: 500; line-height: 1.42`。
- `.rec .copy`：`color: #8C93A3; font-size: 12.4px; font-weight: 500; line-height: 1.42`。
- `.timeline .node h3, .timeline .node p`：`width: min(248px, calc(100% - 21px)); text-wrap: wrap`。
- `.timeline .node .chev`：`22px × 22px`，`right: 8px`，`top: 15px`。
- `.timeline-tab-mark`：默认 `30px × 30px`，第二个 Tab 纯图标态未选中和选中均为 `52px × 52px`。
- `.bottom .nav:nth-child(2).timeline-icon-only .wrap`：`58px × 52px`，选中和未选中都不显示背景。
- `.bottom .nav:nth-child(2).timeline-icon-only`：移除文字节点，`gap: 0`，居中显示。
- `.bottom .nav:nth-child(2).active .timeline-tab-mark .mark-shadow`：`#86A866`，`opacity: .52`。
- `.bottom .nav:nth-child(2).active .timeline-tab-mark .mark-blob`：`#DFF2C7`。
- `.bottom .nav:nth-child(2).active .timeline-tab-mark .mark-main`：`#C98778`。
- `.bottom .nav:nth-child(2).active .timeline-tab-mark .mark-accent`：`#B87667`。
- `.bottom .nav:nth-child(2).timeline-icon-only .timeline-tab-mark .mark-shadow`：`#6F7484`，`opacity: .22`。
- `.bottom .nav:nth-child(2).timeline-icon-only .timeline-tab-mark .mark-blob`：`#F2F4F6`。
- `.bottom .nav:nth-child(2).timeline-icon-only .timeline-tab-mark .mark-main`：`#6F7484`。
- `.bottom .nav:nth-child(2).timeline-icon-only .timeline-tab-mark .mark-accent`：`#8B93A1`。
- `.bottom .nav:nth-child(2):not(.active)`：与“推荐”Tab 同灰度，不再带偏绿倾向。

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

- `event-timeline-follow-status.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
