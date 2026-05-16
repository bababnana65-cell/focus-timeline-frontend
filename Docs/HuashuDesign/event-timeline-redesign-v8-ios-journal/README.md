# 事件时间轴 App 视觉重设计 · iOS Journal v8

本目录是 `huashu-design` 交付物，只做视觉设计，不修改 Flutter 业务代码。

## 本版方向

- 单独新建 v8 目录，没有覆盖 v7 或更早版本。
- 采用 iOS Journal 式记录流：浅纸感背景、柔和卡片、轻状态标签、清晰红点。
- 不使用渐变色。
- 不使用不规则多边形色块。
- 不使用黑色或深色填充块；深色只用于正文文字和必要线性图标。
- 保留当前截图里的入口、页面结构、按钮文案、分类文案和业务规则。

## 文件

- `event-timeline-ios-journal.html`：高保真移动端设计板。
- `brand-spec-ios-journal.md`：iOS Journal 风视觉规范。
- `screenshots/design-board.png`：完整设计板 PNG。
- `screens/*.png`：单页高保真 PNG。
- `figma-handoff.json`：Figma 重建参考 JSON，不是原生 `.fig` 文件。

## 覆盖页面

- 推荐页：当前热门 / 可能关心 / 随机看看 / 历史记录
- 我的关注：普通列表 / 有新动态 / 当前专题 / 空列表
- 时间轴：正常节点列表 / 更多菜单 / 正在准备中 / 初始化失败 / 空时间线
- 新建时间线：输入关键词 / AI 扩写后确认
- 手机号验证弹层
- 关注上限提示
- 刷新失败轻提示
- 组件规范
