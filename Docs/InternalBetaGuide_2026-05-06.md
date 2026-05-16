# Timeliness 内测说明

用途：用于 5-20 人小规模内测。目标是验证核心路径是否清晰、稳定、值得继续使用，不收集新功能愿望清单。

## 1. 内测目标

本轮只验证 4 件事：

- 用户是否能理解“创建时间线”和“关注专题”。
- 推荐专题和时间线内容是否足够可读。
- 游客、登录、关注、收藏、反馈这些核心路径是否稳定。
- “我的关注”提醒是否帮助用户回到新更新。

不在本轮评价：

- 会员支付。
- 系统推送。
- 通知中心。
- 专题编辑、删除、归档。
- 复杂 AI 工作流。
- 大规模公开发布。

## 2. 测试环境

- App：Windows 桌面版。
- 后端：真实 HTTP 后端。
- 本地测试地址：`http://127.0.0.1:8010`。

启动真实 HTTP 前端：

```powershell
cd C:\Codex\Test\Timelinesss
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' run `
  --dart-define=TIMELINESS_USE_HTTP_BACKEND=true `
  --dart-define=TIMELINESS_API_BASE_URL=http://127.0.0.1:8010 `
  -d windows
```

测试前确认后端健康：

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8010/health -Method Get
```

## 3. 测试账号

内测手机号可使用任意未使用过的测试手机号。

本地开发环境可通过后端 debug code 获取验证码；正式外部分发前必须换成真实短信或明确说明验证码由测试负责人提供。

测试建议：

- 每位测试者使用一个独立手机号。
- 不复用上一次测试的本地 App 状态。
- 如需模拟新用户，先备份或清空 Windows App 本地 `shared_preferences.json`。

Windows 本地状态位置：

```text
C:\Users\yifei\AppData\Roaming\com.example\event_timeline\shared_preferences.json
```

## 4. 必测路径

### 4.1 游客路径

- 启动 App。
- 浏览首页推荐。
- 打开任意专题。
- 查看时间线节点。
- 返回首页。

通过标准：

- 页面不白屏。
- 推荐卡片和时间线内容能看懂。
- 不登录也能完成浏览。

### 4.2 游客关注上限

- 以游客身份连续关注 5 个专题。
- 尝试关注第 6 个专题。
- 查看登录提示。
- 点击“稍后再说”。

通过标准：

- 第 6 个关注被阻止。
- 登录提示文案清楚。
- 不再显示重复额度对比卡片。
- 点击“稍后再说”后当前页面不乱跳。

### 4.3 创建时间线

- 点击底部“创建”。
- 查看关键词示例。
- 输入 2-4 个关键词。
- 点击“AI 扩写”。
- 确认创建。
- 查看创建后的时间线。

通过标准：

- 关键词示例是词组形式，不是短句。
- AI 扩写结果可理解。
- 创建后进入正式专题时间线。
- 达到游客关注上限时不能继续创建。

### 4.4 登录与状态合并

- 使用测试手机号登录。
- 查看游客关注是否合并。
- 查看游客创建专题是否仍可打开。
- 进入“我的”页。

通过标准：

- 登录流程可完成。
- 关注列表不重复。
- 游客创建专题不丢失。
- 登录后关注额度显示为免费用户规则。

### 4.5 我的页

- 查看会员页。
- 保存兴趣。
- 提交反馈。
- 查看收藏。

通过标准：

- 会员页只做权益展示，不要求支付。
- 兴趣保存成功后状态不丢失。
- 反馈提交后显示成功。
- 收藏内容可展开并阅读原文。

### 4.6 我的关注提醒

- 查看“我的关注”列表。
- 切换提醒模式。
- 观察底部红点和列表红点。

通过标准：

- `off` 不显示红点。
- `major_only` 只对重大更新显示红点。
- `all` 对所有 recent update 显示红点。
- 首次打开 App 的历史数据不应全部变成红点。

## 5. 反馈规则

反馈只按下面格式记录：

```text
测试者：
日期：
设备：
路径：游客 / 登录 / 创建 / 关注 / 收藏 / 我的页
问题描述：
复现步骤：
预期：
实际：
严重级别：P0 / P1 / P2
截图或录屏：
```

严重级别定义：

- P0：崩溃、无法登录、无法创建、核心页面无法打开。
- P1：核心路径可继续，但用户明显困惑或关键状态错误。
- P2：体验建议、文案建议、边缘问题。

本轮不接受泛化需求，例如“加推送”“加支付”“做后台管理”。这些统一进入后续产品池，不打断 MVP 验收。

## 6. 反馈查看

用户在 App 内提交的反馈会进入后端 `user_feedback` 表。

开发侧可用后端脚本导出：

```powershell
cd C:\Codex\Test\Timelinesss_backend\backend
.\.venv\Scripts\python.exe scripts\export_feedback.py --format json --limit 100
.\.venv\Scripts\python.exe scripts\export_feedback.py --format csv --output runtime\feedback-export.csv
```

常用筛选：

```powershell
.\.venv\Scripts\python.exe scripts\export_feedback.py --category bug --format csv --output runtime\feedback-bugs.csv
.\.venv\Scripts\python.exe scripts\export_feedback.py --source profile --format json
```

## 7. 内测出口标准

满足以下条件后，可以进入下一阶段：

- P0 清零。
- P1 有明确结论：已修复、接受现状、或延后处理。
- 至少 5 位测试者完成游客路径和登录路径。
- 至少 3 位测试者完成创建时间线路径。
- 至少 3 条有效反馈被记录并分类。
- 前端和后端自动化验证继续通过。

## 8. 下一阶段候选

内测稳定后再考虑：

- 全局搜索接口。
- 我的页历史记录。
- 收藏列表分页。
- 反馈查看后台。
- 会员能力字段与真实 enforcement。
- 系统推送通知偏好。

这些都不应在当前内测前插入。
