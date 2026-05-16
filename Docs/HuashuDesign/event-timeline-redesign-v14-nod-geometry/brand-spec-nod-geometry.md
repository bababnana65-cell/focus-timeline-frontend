# 事件时间轴 App · NOD-inspired Geometry v14 视觉规范
> 日期：2026-04-28  
> 范围：视觉设计交付，不修改 Flutter 代码  
> 关键要求：NOD-inspired 几何阅读风；新闻文字阅读优先；图标低占比；不使用渐变色；不使用不规则多边形色块；不使用黑色或深色填充块；页面逻辑、入口、文案和业务规则保持当前截图语义

## 设计方向

方向名：**NOD-inspired Geometry Reading / 几何阅读流**

- 参考 Nod Young 相关视觉语言中的准确轮廓、节奏版式、强色彩点缀和极简几何。
- 不直接复制具体作品，不把 App 做成艺术海报；重点是把这些特征转译成可阅读的新闻 UI。
- 推荐和关注列表使用强编号、小几何角标和高权重标题形成节奏。
- 时间轴节点使用 GEOMETRIC NODE / MAJOR NODE 小标签，加强节点感。
- 高能量色只作为小面积状态和节奏标记，避免压过新闻文字。

## 色彩 Token

```css
--canvas: #f7fafe;
--surface: #ffffff;
--ink: #172237;
--muted: #68758a;
--line: #dce8f1;
--blue: #438cff;
--blue-deep: #2f72d6;
--mint: #32c89b;
--coral: #ff746b;
--red: #e94c57;
--nod-blue: #1f7cff;
--nod-mint: #21c7a8;
--nod-coral: #ff5d50;
--nod-violet: #7667ff;
--nod-inkline: #172237;
```

## 组件原则

- 推荐卡片：左侧强编号，编号角落加小几何色块；标题优先。
- 我的关注卡片：普通项保持索引行，新动态和当前专题才使用浅底框。
- 时间轴节点：节点标题前加入小型英文几何标签，强化节奏但不影响中文阅读。
- 新动态：保留底部红点 + 卡片红点 + 最新动态高亮。
- 顶部和底部导航：图标保持小体量，不抢正文注意力。
- 所有高能量颜色只在编号、点、标签、红点和细状态中出现。

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

- `event-timeline-nod-geometry.html`
- `screenshots/design-board.png`
- `screens/*.png`
- `figma-handoff.json`
