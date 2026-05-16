# 事件时间轴 App · Visual Redesign Spec
> 采集日期：2026-04-27  
> 资产来源：用户提供的 7 张当前 App 截图、本仓库 `Docs/ProductSpec.md`、`Docs/GuestFollowPolicy` 冻结规则  
> 资产完整度：产品流程完整；无独立品牌 logo，当前设计不引入新品牌标识

## 设计假设

- 这是移动端优先的信息追踪 App，不是新闻客户端，也不是后台系统。
- 当前截图只作为信息架构、状态和入口参考，不继承现有深蓝 + 棕橙的视觉语言。
- 设计不新增接口、不新增通知中心、不新增“我的专题”入口，不提供编辑、删除、归档专题。
- 游客优先使用，手机号验证只在触发同步、额度、续接创建等场景出现。

## 视觉方向

主方向：**Breeze Ribbon / 清爽时间丝带**

- 气质关键词：极简、轻盈、明亮、年轻、可扫读。
- 页面背景使用浅蓝白和微冷薄荷灰，不做深色科技感。
- 用浅蓝、薄荷绿、珊瑚橙、淡紫分担状态语义，避免单一蓝色统治界面。
- 卡片保持低半径、低阴影，信息靠层级和留白组织，不靠厚重边框。
- 时间轴使用“日期标签 + 细线 + 节点点位”的轻量表达，减少复杂装饰。

## 色彩

```css
:root {
  --app-canvas: #f7fbff;
  --app-canvas-cool: #f3fbf8;
  --app-surface: #ffffff;
  --app-ink: #17213a;
  --app-muted: #63708a;
  --app-soft: #eef3f7;
  --app-line: #e2e8ef;
  --app-blue: #4b8dff;
  --app-blue-deep: #245bd8;
  --app-mint: #79dfbd;
  --app-coral: #ff7a66;
  --app-lavender: #cfc7ff;
  --app-lilac: #d8cdfd;
  --app-danger: #e5484d;
  --app-success: #1d9a6c;
}
```

## 字体层级

- Display / page title：22px / 700 / line-height 1.18
- Section title：18px / 700 / line-height 1.25
- Card title：16px / 700 / line-height 1.3
- Body：14px / 500 / line-height 1.55
- Meta：12px / 600 / line-height 1.35
- Bottom navigation label：11px / 700

字体栈：

```css
font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont,
  "Segoe UI", "PingFang SC", "Microsoft YaHei UI", "Microsoft YaHei", sans-serif;
```

## 间距与尺寸

- 页面左右安全内边距：16px，360px 小屏可降为 14px。
- 列表项间距：10px 到 12px。
- 主按钮触控高度：48px。
- 小按钮触控高度：44px。
- 底部导航高度：76px，内容列表底部预留 104px。
- 手机设计基准：390px 宽；同时检查 360px 与 430px。

## 圆角与阴影

- 列表卡片：8px。
- 输入框 / 分段控件：14px 到 18px。
- 底部弹层：顶部 28px。
- 轻阴影：`0 10px 28px rgba(31, 48, 74, 0.08)`。
- 避免卡片套卡片；只有重复项、弹窗、底部弹层使用卡片形态。

## 状态语义

- 有新动态：专题卡片内使用珊瑚红点 + 最新摘要浅蓝高亮；底部“我的关注”Tab 显示红点。
- 当前正在查看：蓝色描边 + “正在查看”状态标签。
- 置顶专题：使用小 pin 状态标签，不增加独立入口。
- 初始化中：薄荷绿进度条 + “正在准备中”，不把空 timeline 当最终空状态。
- 初始化失败：保留专题信息，给失败提示和轻量重试语义；不新增复杂后台任务入口。
- 刷新失败：保留旧内容，用 toast/snackbar 轻提示。

## 业务边界

- 游客最多关注 5 个专题。
- 登录免费用户最多关注 10 个专题。
- 游客新建专题不限制历史次数；新建后自动关注，仍受当前关注数上限限制。
- 登录后合并游客关注，不突破账号关注上限。
- 专题创建后不可修改、不可删除、不可归档。
- 唯一收口动作是取消关注。
- 我的关注下拉刷新请求关注列表。
- 推荐页下拉刷新请求推荐列表。
- 新动态提醒只做红点和列表高亮，不做通知中心。
- 不新增“我的专题”独立入口。

## 交付文件

- 高保真设计板：`event-timeline-mobile-redesign-no-yellow.html`
- 渲染截图输出目录：`screenshots/`
