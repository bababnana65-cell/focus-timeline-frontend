# 事件时间轴 App 视觉重设计 · V33 Timeline Tab v59

本目录是 `huashu-design` 交付物，只做视觉设计，不修改 Flutter 业务代码。

## 本版方向

- 单独新建 v59 目录，没有覆盖 v57、v58 或其他版本。
- 以 v58 为基础，只调整底部中间 `时间轴` Tab。
- 取消 v58 自定义表盘 SVG 注入，恢复 v33 的标准 `clock` 图标方案。
- 底部中间 Tab 重新显示 `时间轴` 文字。
- 选中态继续跟随时间轴页绿色主题，未选中态保持柔和灰色。
- 其他页面、卡片、时间线节点、准备中状态、文案和业务规则不改。
- 不修改 Flutter 代码。

## 文件

- `event-timeline-v33-timeline-tab.html`：高保真移动端设计板。
- `brand-spec-v33-timeline-tab.md`：本版视觉规范。
- `figma-handoff.json`：Figma 重建参考 JSON，不是原生 `.fig` 文件。
- `render-v59-screenshots.cjs`：截图生成脚本。
- `screenshots/design-board.png`：完整设计板 PNG。
- `screens/*.png`：单页高保真 PNG。

## 覆盖页面

- 推荐页：当前热门 / 可能关心 / 随机看看 / 历史记录
- 我的关注：普通列表 / 有新动态 / 当前专题 / 空列表
- 时间轴：正常节点列表 / 更多菜单 / 正在准备中 / 初始化失败 / 空时间线
- 新建时间线：输入关键词 / AI 扩写后确认
- 手机号验证弹层
- 关注上限提示
- 刷新失败轻提示
- 组件规范
