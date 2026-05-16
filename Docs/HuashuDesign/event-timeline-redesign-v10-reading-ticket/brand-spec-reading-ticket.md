# 事件时间轴 App · Reading Ticket v10 视觉规范
> 日期：2026-04-28  
> 范围：视觉设计交付，不修改 Flutter 代码  
> 关键要求：新闻文字阅读优先；图标低占比；轻票据风；不使用渐变色；不使用不规则多边形色块；不使用黑色或深色填充块；页面逻辑、入口、文案和业务规则保持当前截图语义

## 设计方向

方向名：**Reading Ticket Timeline / 阅读优先票据时间轴**

- 这是 v9 卡片票据风的收敛版：保留“事件凭证”的轻票据语义，但减少图标和装饰占宽。
- 关注列表、推荐列表和时间轴都以文字阅读为主，标题和摘要获得更宽的可读区域。
- 左侧图标只作为小章，不再承担大视觉焦点。
- 右侧票根只保留操作语义，宽度压缩，避免挤压正文。
- 时间轴节点保留日期和节点数量，不因票据化削弱阅读结构。

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
--paper: #ffffff;
--paper-blue: #f2f7ff;
--paper-rose: #fff7f6;
--ticket-line: #d5e2ec;
```

## 组件原则

- 推荐卡片：左章约 24px，右侧操作区约 58px，正文列使用剩余宽度。
- 我的关注卡片：左侧专题图标约 26px，右侧进入区约 30px，最新动态摘要优先显示。
- 时间轴节点：右侧箭头区约 28px，节点标题和辅助文案优先。
- 底部 Tab：图标收小为 18px，选中态仍清楚但不抢占页面注意力。
- 新动态：保留底部红点 + 卡片红点 + 最新动态浅蓝高亮。
- Sheet / 弹层：保留现有流程，不加入编辑、删除、归档等入口。

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

- `event-timeline-reading-ticket.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
