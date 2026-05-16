# 事件时间轴 App · iOS Journal Seasalt v13 视觉规范
> 日期：2026-04-28  
> 范围：视觉设计交付，不修改 Flutter 代码  
> 关键要求：iOS Journal 风新配色；海盐蓝白主色；新闻文字阅读优先；不使用渐变色；不使用不规则多边形色块；不使用黑色或深色填充块；页面逻辑、入口、文案和业务规则保持当前截图语义

## 设计方向

方向名：**iOS Journal Seasalt / 海盐蓝白记录流**

- 保留 v8 的 iOS Journal 记录流结构。
- 背景由偏薄荷纸感调整为海盐蓝白，整体更清爽、更轻。
- 蓝色负责主导航、当前状态和已关注状态。
- 薄荷绿负责准备中、进度、正向状态。
- 珊瑚色只负责新动态、失败、额度提示等需要提醒的状态。
- 不新增任何当前产品未定义的入口或业务动作。

## 色彩 Token

```css
--canvas: #f6faff;
--canvas-mint: #f5fbff;
--surface: #ffffff;
--ink: #162238;
--muted: #728195;
--line: #dce9f4;
--blue: #4e97ff;
--blue-deep: #2f72d6;
--mint: #37c7ad;
--mint-soft: #e8faf5;
--coral: #ff7167;
--coral-soft: #fff1ef;
--lavender: #9b8ff7;
--lavender-soft: #f3f1ff;
--red: #e94c57;
--green: #1f9e85;
--paper: #ffffff;
--paper-blue: #eef7ff;
--paper-rose: #fff6f5;
--sky-soft: #eaf6ff;
```

## 组件原则

- 顶部栏：保留原入口位置，按钮为浅海盐蓝白描边。
- 底部 Tab：选中态为浅蓝胶囊，红点保留。
- 推荐卡片：以白卡为主，排名/推荐图标使用低饱和色。
- 我的关注卡片：新动态使用浅珊瑚底和红点；当前专题使用浅蓝底。
- 时间轴节点：卡片保持白底，重大节点只用小面积珊瑚提示。
- 新建与登录弹层：保留轻量 Journal 表单感，避免后台化。

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

- `event-timeline-ios-journal-seasalt.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
