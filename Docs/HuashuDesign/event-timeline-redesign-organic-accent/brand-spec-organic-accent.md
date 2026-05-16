# 事件时间轴 App · Polygon Accent v6 视觉规范
> 日期：2026-04-28  
> 范围：视觉设计交付，不修改 Flutter 代码  
> 关键要求：少量使用微妙不规则多边形色块，棱角采用小圆角；不使用渐变色；不使用黑色或深色填充块；页面逻辑、入口、文案和业务规则保持当前截图语义

## 设计方向

方向名：**Polygon Accent Timeline / 圆角多边形时间轴**

- 基础仍是纯色浅蓝白界面，保持极简、轻松和可读。
- 不规则多边形色块只作为关键位置的“气氛与层级提示”，不作为装饰铺满页面。
- 色块使用纯色、低对比、轻透明感的配色语义：浅蓝、薄荷、淡紫、珊瑚浅底。
- 信息结构和当前截图保持一致，色块不承担新功能含义。

## 色彩 Token

```css
--canvas: #f6f9fc;
--canvas-mint: #f5faf7;
--surface: #ffffff;
--ink: #121a2b;
--muted: #647086;
--line: #dfe8f0;
--blue: #3478f6;
--blue-deep: #225ecb;
--mint: #35c59b;
--mint-soft: #e8f8f1;
--coral: #f26b5e;
--coral-soft: #fff0ed;
--lavender: #9b8cf5;
--lavender-soft: #f0eeff;
--shape-blue: #e7f0ff;
--shape-mint: #e1f7ee;
--shape-coral: #fff0ed;
--shape-lavender: #efecff;
```

## 不规则多边形色块使用规则

- 只在关键位置使用：首张推荐卡片、当前专题、新动态专题、准备中状态、时间轴头部、新建确认卡、登录/额度弹层、空状态。
- 普通列表项不加色块，避免信息噪音。
- 色块必须在内容后方，不能遮挡文字、按钮或红点。
- 色块使用纯色填充，不使用 `linear-gradient`、`radial-gradient` 或 `conic-gradient`。
- 色块边界使用不规则 path，多边形拐点带小圆角，避免锐利碎片感。
- 黑色和深色只保留给正文文字，不作为按钮、Toast、导航选中态或手机框填充。

## 文案和逻辑锁定

- 推荐分类：`可能关心 / 当前热门 / 随机看看 / 历史记录`。
- 底部 Tab：`我的关注 / 时间轴 / 推荐`。
- 时间轴更多菜单：`新建时间线 / 分享 / 取消关注 / 时间顺序`。
- 新建流程：`新建时间线 -> 关键词 -> AI 扩写 -> 专题定义确认`。
- 不新增通知中心、我的专题、编辑、删除或归档入口。

## 交付文件

- `event-timeline-organic-accent.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
