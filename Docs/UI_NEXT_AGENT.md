# Next Agent Handoff · S2 Midnight UI · 续接 Codex

> 上一位 agent (Claude) 在 `ui-work` 分支上推到 commit `0a315c3`。这份文档告诉你接下来怎么做，不要让它丢上下文。

## 0. 必读三份手册（按这个顺序看完再动手）

1. `Docs/FrontendUiHandoff_bd9ba8f.md` — baseline 行为契约（什么不能动）
2. `design_handoff_s2_midnight/README.md` — S2 午夜色板视觉规范
3. **本文档** — 上一轮已经做了什么、约定了什么、还在调什么

> 三者冲突时：行为契约 > 本文档 > 视觉规范。

## 1. 当前分支与代码状态

```powershell
cd C:\Codex\Test\Timelinesss
git status
git log --oneline -5
```

预期：
- 分支：`ui-work`
- HEAD：`0a315c3 ui: home masthead + typography refresh + design polish`
- 前一个 commit：`cc59a56 ui: S2 midnight palette + logo + per-screen polish`
- base：`origin/ui-from-bd9ba8f`
- 远端：`origin/ui-work`

未跟踪不要 commit：
- `.tmp/`（包含 `flutter-run-http.*.log`、`codex-provider-sync.zip` 等本地日志）
- `design_handoff_s2_midnight/`（设计交接，仅作本地参考）

## 2. 跑起来 · 验证

后端：本机 `http://127.0.0.1:8010`（确保它在跑，否则 HTTP 接口都 404）。

```powershell
# 静态检查（必须 0 issues）
'C:\Users\yifei\Fult\flutter\bin\flutter.bat' analyze

# 测试（必须 142/142 全绿）
'C:\Users\yifei\Fult\flutter\bin\flutter.bat' test

# 在真实 HTTP 后端下跑 Windows 桌面
'C:\Users\yifei\Fult\flutter\bin\flutter.bat' run `
  --dart-define=TIMELINESS_USE_HTTP_BACKEND=true `
  --dart-define=TIMELINESS_API_BASE_URL=http://127.0.0.1:8010 `
  -d windows
```

**每一处视觉改动改完都跑 analyze + test，绿了才能进下一步。**

## 3. 这次已经定好的视觉规则（不要再来回翻）

### 3.1 主色调（按重要程度配色）

| 等级 | 用途 | 主色 | 软底 | 字色 |
|---|---|---|---|---|
| 重大（major）| 主行动 / 重要节点 / 重大事件 | `AppTheme.accent` 余烬橙 #E07A3B | `AppTheme.accentSoft` 18% | `AppTheme.accentStrong` #EC8C4F |
| 持续追踪（非 major）| 普通节点 / 追踪态 / live | `AppTheme.highlight` 暖琥珀 #F2B544 | `AppTheme.highlightSoft` 16% | `AppTheme.highlightStrong` #E0A02E |

**这条规则在所有"按 major / 非 major 区分"的地方都要遵守**：date chip、时间轴节点圆点、节点边框、节点字色、卡片左边 inline bar、节点光晕。

`hasRecentUpdate` 在卡片 inline bar 里是反着用的：`hasRecentUpdate=true → highlight (黄)`，`false → accent (橙)`。原因是设计稿默认假设"绝大多数被关注的专题都是重大"，黄色留给"只是在追踪、近期有微更新"的次要状态。

### 3.2 字体栈

`headlineLarge / Medium / Small + titleLarge` 走衬线：

```dart
fontFamily: 'Noto Serif SC',
fontFamilyFallback: [
  'Source Han Serif SC', 'Source Han Serif CN',
  'Noto Serif CJK SC', 'Songti SC', 'STSong',
  'SimSun', 'NSimSun', 'serif',
  'PingFang SC', 'Microsoft YaHei',
],
```

`titleMedium / titleSmall / body* / label*` 保留无衬线（PingFang SC / Noto Sans CJK SC / Microsoft YaHei UI / Microsoft YaHei）。

### 3.3 当前字号（用户已经手动调过、不要再轻易变）

| 元素 | 字号 | 字重 | letterSpacing | 备注 |
|---|---|---|---|---|
| 首页 masthead "焦点时轴" | 16 | w800 | -0.05 | titleLarge 派生 |
| 卡片标题 topic.name | 15 | w800 | -0.05 | titleLarge 派生（关注 + 推荐两屏） |
| 卡片副标 topic.tagline | 12.5 | w500 | — | bodyMedium 派生，色 textSecondary |
| inline note bar 文字 | 13 | w600 | — | bodySmall 派生，色 textPrimary |
| 时间轴详情顶部标题 | 17 | w800 | -0.05 | titleLarge 派生 |
| 数据 ledger 大数字（4 / 2025·05 等）| 16 | w800 | -0.05 | titleMedium 派生，色 textPrimary |
| 数据 ledger 标签（起始时间 等）| 10.2 | w500 | — | labelSmall |
| 时间轴节点 "起" 字 | inherit | w500 | — | 比"1/2/3"细，因为是首节点 |
| 时间轴节点 "1/2/3" 数字 | inherit | w900 | — | labelMedium |
| 我的页 "我的" 大字 | 32 | w800 | -0.3 | headlineMedium 派生 |
| 我的页章节标 "内容管理 / 偏好设置" | 10.5 | w800 | 2.0em | labelSmall + Mono caps |

> 用户改字号是按截图 1:1 对照拍板的。**只有用户明确说"还不对"才动，不要主动 bump。**

### 3.4 时间轴竖线

- `_TimelineRailPainter` 的 `strokeWidth: 1.4`（不是 2）。
- 用 `AppTheme.accent` 余烬橙画线。
- 每个节点 marker 用 `Stack` 在最底加了一层 `timelineBackground` 实心圆，**强行遮线**。下次有"线穿过节点"的反馈先检查这层是不是还在。

### 3.5 图标背景

`lib/widgets/topic_icon_resolver.dart` + `lib/widgets/timeline_signal_resolver.dart` **不再用浅色 pastel 当 backgroundColor**。所有类目统一 `AppTheme.surfaceMuted` 深底 + `AppTheme.border` 细边；前景按色系映射到 `lavender / highlight / danger / textSecondary` 这 4 个 token。**不要再引入硬编码 hex。**

## 4. 行为护栏（绝不能破，破了等于退步）

- `lib/services/**`、`lib/services/timeline_controller.dart`、`lib/models/**`、`lib/dto/**` — **整目录禁动**。
- `lib/widgets/create_timeline_sheet.dart` 行为护栏：
  - 候选方向卡点击直接走 `_selectDirectionCandidate(candidate)`（约 line 921）→ 不能加 confirm 弹窗 / "确定" 按钮 / 候选后确认页。
  - 状态值字符串 `'searching'` / `'creating'` 不可改名。
- 不切到 main，所有 commit 落在 `ui-work`。
- 不引入新依赖、不打包字体（按 README §9）。
- 不 commit `.tmp/` 或 `design_handoff_s2_midnight/`。
- 不删时间轴卡片左边的 `AppTopicIconBadge` icon —— 用户明确要求保留。

## 5. 还能继续打磨的方向（用户没明说，但已经在路上）

如果用户给新截图、对比 `design_handoff_s2_midnight/design_refs/*.jsx` 还说不对，最可能的差距点：

1. **创建时间轴 sheet（`lib/widgets/create_timeline_sheet.dart`）** — 这次没有按 README §3.3 全部铺到位（01/02 Mono 序号、置信度进度条等没做，因为 `TimelineDirectionCandidate` 没有 confidence 字段；动 model 越界）。下一轮可以问用户要不要 mock 一个本地字段。
2. **登录验证页** — 上一轮加了 BrandLogoMark + "焦点时轴" 衬线大字 + Mono caps 副标，没再做细调。
3. **节点卡内部排版** — 内部段落（如 "成都 SU7 起火致 1 死" + 三段正文）跟设计稿 `design_refs/app-redesign-s2.jsx` 对比可能还有间距差。
4. **来源徽章 `lib/widgets/source_attribution_badges.dart`** — 已经迁了 reliability bg → highlightSoft / danger.alpha16，但 `lavender` 系来源徽章（README §3.2 提的"背景 lavenderSoft，文字 lavender #7AB6EA"）没全部铺开。

## 6. 工作节奏（务必照做）

1. 用户指一处 / 给一张截图 → 改对应位置 → analyze + test → 重启 Windows app → 报"哪几行改了什么"。
2. **改一处就停下来等用户反馈**，不要批量改多处一起放。
3. 字号 / 颜色不要主动 bump，等用户说"太大 / 太小 / 反了"。
4. Commit 不要每屏一次；攒一批用户认可的改动再 commit 一次，commit message 列清单。
5. 推之前必须 analyze + test 都绿。

---

## 7. 给用户的一句话提示（你照搬给 Codex）

```
请阅读 C:\Codex\Test\Timelinesss\Docs\UI_NEXT_AGENT.md 接手上一位 agent
的 S2 午夜调前端工作。先 git status / git log 确认在 ui-work 分支、
HEAD 是 0a315c3 0a315c3，然后等我指下一处再动。
```
