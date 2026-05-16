# MVP 真实 HTTP 验收与推进清单

用途：前端基本稳定后，用这份清单推进真实后端联调、内测准备和下一阶段开发排序。

## 1. 当前基线

- 前端仓库：`C:\Codex\Test\Timelinesss`
- 后端仓库：`C:\Codex\Test\Timelinesss_backend`
- 本地真实后端：`http://127.0.0.1:8010`
- 当前目标：先把真实用户核心路径跑稳，再考虑新功能扩展。

本阶段不做：

- 支付 / 订阅 / 恢复购买
- 系统推送通知闭环
- 通知中心
- 专题编辑 / 删除 / 归档
- 新 quota 规则
- 游客服务端账号体系
- 大规模 AI 工作流平台

## 2. 启动真实联调环境

### 2.1 启动后端

```powershell
cd C:\Codex\Test\Timelinesss_backend\backend
.\scripts\restart_local_8010.ps1
```

健康检查：

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8010/health -Method Get
```

预期：

```json
{
  "status": "ok",
  "appName": "Timeliness Backend",
  "environment": "local"
}
```

### 2.2 启动前端

```powershell
cd C:\Codex\Test\Timelinesss
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' run `
  --dart-define=TIMELINESS_USE_HTTP_BACKEND=true `
  --dart-define=TIMELINESS_API_BASE_URL=http://127.0.0.1:8010 `
  -d windows
```

前端启动日志应出现：

```text
Using HTTP backend: http://127.0.0.1:8010
```

## 3. 提交前固定验证

前端改动后：

```powershell
cd C:\Codex\Test\Timelinesss
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' analyze
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' test
```

后端改动后：

```powershell
cd C:\Codex\Test\Timelinesss_backend\backend
.\.venv\Scripts\python.exe scripts\verify_bucket_favorites.py
.\.venv\Scripts\python.exe scripts\smoke_test.py
.\.venv\Scripts\python.exe scripts\verify_migrations.py
.\.venv\Scripts\python.exe scripts\verify_profile_interests_feedback.py
.\.venv\Scripts\python.exe scripts\verify_topic_context_classification.py
.\.venv\Scripts\python.exe -m compileall app scripts
```

## 4. MVP 核心验收路径

每轮正式联调都按下面顺序跑。每项只记录：通过 / 失败 / 阻塞原因。

### 4.1 游客首次使用

- App 首次启动成功。
- 首页推荐能加载。
- 专题卡片能打开详情。
- 时间轴能加载 entries、stats、favoriteBuckets。
- 不登录也能浏览推荐专题和时间轴。
- 网络失败时主页面不白屏，旧数据或空状态可用。

通过标准：

- 无崩溃。
- 无主路径 500 文案裸露。
- 时间轴节点、分桶、来源入口可正常阅读。

### 4.2 游客关注 quota

- 游客可关注最多 5 个专题。
- 第 6 个关注触发登录提示。
- 登录提示不重复展示额度对比卡片。
- 点击“稍后再说”后不改变已关注状态。
- 取消关注后，游客 quota 释放，可继续关注或创建专题。

通过标准：

- 游客上限保持 5。
- UI 不暗示服务端已改变 quota。
- 不出现超过 5 个游客关注。

### 4.3 游客创建专题

- 游客点击“创建”打开创建时间轴。
- 关键词示例使用词组形式，例如 `霍尔木兹海峡 航运`。
- AI 扩写后可确认创建。
- 创建后返回正式 `topicId`，不是长期本地 `custom-*`。
- 创建成功后自动关注。
- 游客同一设备可打开 detail 和 timeline。

通过标准：

- 创建流程不产生本地假专题作为事实源。
- 达到 5 个关注时，创建被阻止并提示登录。

### 4.4 登录与 merge / claim

- 手机号验证码流程可完成登录。
- 登录后 session 可恢复。
- 游客关注 merge 到登录账号。
- 游客创建专题 claim 到登录账号。
- merge / claim 不额外改变 quota 规则。
- 登录后刷新推荐和我的关注。

通过标准：

- 游客本地待合并状态清理正确。
- 已关注专题不重复。
- claim 失败不影响已成功 merge 的关注关系。

### 4.5 我的关注与提醒

- `GET /topics/followed` 返回关注列表。
- 列表项显示 `hasRecentUpdate`、`latestNode`、`latestNode.isMajor`。
- 首次打开 app 或登录后的初始快照不触发红点。
- 后续刷新出现新更新后，前端按提醒模式显示红点。
- `latestNode.isMajor` 只表示节点是否重大，不受用户提醒设置影响。

通过标准：

- `off` 不显示红点。
- `major_only` 只显示重大节点红点。
- `all` 对所有 recent update 显示红点。

### 4.6 我的页

- 会员页只展示现有 capabilities：
  - `accountTier`
  - `followLimit`
  - `followCount`
  - `remainingFollowQuota`
- 兴趣页登录后可读取和保存兴趣类别。
- 兴趣保存使用覆盖语义，不是增量追加。
- 反馈页登录后可提交反馈。
- 收藏页可查看已收藏 bucket，并能展开阅读原文。

通过标准：

- 前端不自己计算未来会员权益。
- 后端未 enforce 的会员字段不要求本轮返回。
- 反馈失败不影响其他主流程。

### 4.7 收藏 bucket

- 时间轴 bucket 收藏按 `topicId + [bucketStart, bucketEnd)` 生效。
- 收藏状态按时间范围 overlap 判断。
- 取消收藏幂等。
- 游客收藏本地保存。
- 登录后游客收藏 merge 到账号。
- 收藏列表 item 包含 `entries`，可准确打开原文。

通过标准：

- 同一 bucket 不重复收藏。
- 收藏页能稳定还原 sourceUrl / sourceName。

### 4.8 刷新与降级

- 推荐页下拉刷新调用 `/recommendations`。
- 我的关注下拉刷新调用 `/topics/followed`。
- 刷新失败时保留旧数据。
- 真实后端异常不导致整页崩溃。

通过标准：

- 刷新失败只出现可理解提示。
- 主页面仍可继续浏览旧内容。

## 5. 问题记录格式

每个问题按这个格式记录，避免混入新需求：

```text
编号：
日期：
环境：Windows / real HTTP / 127.0.0.1:8010
路径：游客 / 登录 / 创建 / 关注 / 收藏 / 我的页
复现步骤：
实际结果：
预期结果：
判断类型：契约问题 / 空值问题 / 状态流问题 / UI 文案问题 / 性能问题
阻塞级别：P0 / P1 / P2
截图或日志：
处理结论：
```

阻塞级别：

- P0：阻断核心路径或导致崩溃，必须修。
- P1：核心路径可继续，但真实用户会明显困惑，发布前修。
- P2：体验优化或边缘问题，可排期。

## 6. MVP 出口标准

满足下面条件后，可以进入小规模内测：

- 前端 `flutter analyze` 通过。
- 前端 `flutter test` 通过。
- 后端固定验证脚本通过。
- 4.1 到 4.8 核心验收路径全部通过。
- P0 问题清零。
- P1 问题有明确修复计划，且不影响内测核心路径。
- 已确认暂缓范围没有被误做。

## 7. 下一阶段推进顺序

### 阶段 A：真实联调收口

目标：把本地真实 HTTP 路径跑稳。

工作项：

- 按第 4 节跑完整验收。
- 修 P0 / P1 问题。
- 补缺失测试。
- 保持前后端 main 可随时运行。

### 阶段 B：内测准备

目标：让 5-20 个真实用户可以试用。

工作项：

- 准备内测说明。
- 准备反馈收集流程。
- 后端反馈数据可查看或导出。
- 明确数据重置策略。
- 明确隐私和测试账号说明。

### 阶段 C：内容质量与推荐

目标：提高用户打开后的有效信息密度。

工作项：

- 优化推荐 topic 种子。
- 提高 timeline node 标题、摘要、来源质量。
- 增强 topic 分类和 signal 分类稳定性。
- 先做结构化 hint，不急于做生成图片。

### 阶段 D：上线基础设施

目标：从本地 demo 走向可部署服务。

工作项：

- 正式数据库方案。
- secrets 和环境变量管理。
- HTTPS / 域名 / CORS。
- 错误日志和请求追踪。
- 备份与迁移流程。
- GitHub Actions 保持前后端 CI 可靠。

## 8. 暂缓但保留的产品方向

- 全局搜索接口。
- 我的页历史记录接口。
- 收藏列表分页和详情稳定化。
- 会员状态 / 权益接口。
- 提醒设置持久化。
- 系统推送通知偏好。
- 支付 / 订阅 / 恢复购买。

这些能力只有在 MVP 真实联调和小规模内测稳定后再进入设计。
