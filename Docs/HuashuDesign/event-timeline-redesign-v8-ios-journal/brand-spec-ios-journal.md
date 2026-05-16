# 事件时间轴 App · iOS Journal v8 视觉规范
> 日期：2026-04-28  
> 范围：视觉设计交付，不修改 Flutter 代码  
> 关键要求：iOS Journal 式记录流；不使用渐变色；不使用不规则多边形色块；不使用黑色或深色填充块；页面逻辑、入口、文案和业务规则保持当前截图语义

## 设计方向

方向名：**iOS Journal Timeline / 记录流时间轴**

- 把“关注专题”看成用户持续保存的一组事件笔记，而不是新闻列表。
- 背景使用浅纸感绿色白，卡片更柔和、更有呼吸感。
- 重点状态用浅色标签、红点、边框和文字权重表达。
- 时间轴节点像 Journal 里的按日期记录，降低新闻客户端的沉重感。
- 不新增任何当前产品未定义的入口或业务动作。

## 色彩 Token

```css
--canvas: #f7faf8;
--canvas-mint: #f4fbf7;
--surface: #ffffff;
--ink: #152033;
--muted: #6d7788;
--line: #dfe9e4;
--blue: #3d8bff;
--blue-deep: #2d73d9;
--mint: #39c99a;
--mint-soft: #e9f9f1;
--coral: #ff7668;
--coral-soft: #fff0ee;
--lavender: #8f87f7;
--lavender-soft: #f0eeff;
--red: #e94c57;
--green: #1f9e74;
--paper: #fffefa;
--paper-blue: #f2f7ff;
--paper-rose: #fff6f4;
```

## 组件原则

- 顶部栏：保留原入口位置，按钮改为浅色圆角方形，避免深色主按钮。
- 底部 Tab：白色轻浮层，选中态用浅蓝胶囊，不用深色块。
- 推荐分类：四等分轻分段控件，文案固定为 `可能关心 / 当前热门 / 随机看看 / 历史记录`。
- 专题卡片：更像 Journal 条目，卡片圆角更大，间距更松。
- 新动态：底部红点 + 卡片红点 + 最新动态浅蓝高亮。
- 当前专题：浅蓝纸感卡片和细边框，不改变点击逻辑。
- 时间线节点：日期保留在左侧，节点卡片像日期记录。
- Sheet / 弹层：圆角更大，输入框和确认卡片保持轻表单感。

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

- `event-timeline-ios-journal.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
