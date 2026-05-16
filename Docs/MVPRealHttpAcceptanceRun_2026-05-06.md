# MVP 真实 HTTP 验收记录 2026-05-06

对应清单：[MVPRealHttpAcceptanceChecklist_2026-05-06.md](./MVPRealHttpAcceptanceChecklist_2026-05-06.md)

## 1. 环境

- 日期：2026-05-06
- 前端仓库：`C:\Codex\Test\Timelinesss`
- 后端仓库：`C:\Codex\Test\Timelinesss_backend`
- 后端地址：`http://127.0.0.1:8010`
- 后端健康检查：通过
- 前端分支：`main`
- 后端分支：`main`

本次记录区分两类结果：

- `PASS`：已通过自动化或真实 HTTP API 探针确认。
- `MANUAL PENDING`：需要人工在 Windows App 里点击确认，不能用 API 探针替代。

## 2. 自动化基线

### 2.1 前端

```powershell
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' analyze
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' test
```

结果：

- `flutter analyze`：PASS，无 issues。
- `flutter test`：PASS，125 个测试通过。

### 2.2 后端

```powershell
.\.venv\Scripts\python.exe scripts\verify_bucket_favorites.py
.\.venv\Scripts\python.exe scripts\smoke_test.py
.\.venv\Scripts\python.exe scripts\verify_migrations.py
.\.venv\Scripts\python.exe scripts\verify_profile_interests_feedback.py
.\.venv\Scripts\python.exe scripts\verify_topic_context_classification.py
.\.venv\Scripts\python.exe -m compileall app scripts
```

结果：

- `verify_bucket_favorites.py`：PASS。
- `smoke_test.py`：PASS。
- `verify_migrations.py`：PASS。
- `verify_profile_interests_feedback.py`：PASS。
- `verify_topic_context_classification.py`：PASS。
- `compileall app scripts`：PASS。

说明：`smoke_test.py` 日志里的 `forced followed payload failure` 是脚本主动注入的降级测试，最终脚本返回 PASS。

## 3. 真实 HTTP API 探针

运行对象：正在运行的 `http://127.0.0.1:8010`，不是 TestClient 临时数据库。

测试标识：

- `runId`: `20260506160218`
- `guestKey`: `acceptance-20260506160218-e07a31be`
- `phone`: `13806160218`

结果：

| 路径 | 结果 | 记录 |
| --- | --- | --- |
| `GET /health` | PASS | environment=`local` |
| `GET /users/capabilities` guest | PASS | `accountTier=guest`, `followLimit=5` |
| `GET /recommendations` | PASS | 返回 `personalized,hot,explore` |
| `POST /topics/create` guest | PASS | 创建 `topicId=4ba13961-9ca9-4755-91c7-a0df167cee9a` |
| `GET /topics/{topicId}` guest | PASS | 可读取游客创建专题 |
| `GET /topics/{topicId}/timeline` guest | PASS | 初始化后 `active/ready`, `entries=1` |
| `GET /topics/{topicId}` anonymous | PASS | 无 guest key 被拒绝，访问隔离正常 |
| `POST /auth/send-code` + `POST /auth/login` | PASS | 测试手机号可登录 |
| `POST /users/merge-guest-follows` | PASS | `followCount=2`, `followLimit=10` |
| `POST /users/claim-guest-topics` | PASS | `claimed=1`, `already=0` |
| `GET /topics/followed` | PASS | 返回 2 个关注项 |
| `GET /me/interests` + `POST /me/interests` | PASS | 非法类别过滤、重复去重，保存 `politics,military,history` |
| `POST /feedback` | PASS | 返回 `status=received` |
| `POST /me/favorite-timeline-buckets` | PASS | 收藏 bucket 成功 |
| `GET /me/favorite-timeline-buckets` | PASS | 收藏 item 含 `entries`，可还原原文 |
| `GET /users/capabilities` auth | PASS | `tier=free`, `followCount/followLimit=2/10` |

## 4. 当前已覆盖验收项

已确认：

- 真实后端健康。
- 游客 capabilities 保持 5。
- 推荐接口可用。
- 游客可创建服务端正式专题。
- 游客创建专题自动关注。
- 游客同 guest key 可读取 detail/timeline。
- 无 guest key 不能读取游客创建专题。
- 专题初始化可进入 `active/ready`。
- 登录验证码链路可用。
- merge guest follows 可用。
- claim guest topics 可用。
- 登录用户关注列表可读取。
- 兴趣接口可读写，非法 id 过滤、重复去重。
- 反馈接口可提交。
- bucket favorite 可创建、查询，收藏列表包含 entries。
- 登录 capabilities 返回 free 用户 10 个关注额度。

## 5. Windows App 人工 UI 验收

人工验收结论：PASS。

测试方式：重置本机 Windows App 本地身份后，使用真实 HTTP 后端 `http://127.0.0.1:8010` 启动 Windows App，并按新用户路径手动点击验证。

本次测试手机号：

- `13805061609`
- 补充红点测试账号：`13800139114`

已人工确认：

- App 启动后首页视觉和推荐列表是否正常显示。
- 游客连续关注到 5 个后，第 6 个触发的登录弹窗是否符合预期。
- 登录弹窗是否不再显示重复额度对比卡片。
- 点击“稍后再说”后是否保持当前页面状态。
- 创建时间线弹窗中的关键词示例是否为词组形式。
- AI 扩写、确认创建、跳转时间轴的 UI 状态是否连贯。
- 登录页验证码输入和返回路径是否符合预期。
- 我的关注红点在 `off / major_only / all` 下的显示是否符合前端规则。
- 我的页会员、兴趣、反馈、收藏入口的视觉和返回路径是否正常。
- 刷新失败时前端是否保留旧数据并显示可理解提示。

补充人工验收：

- `13800139114` 账号下通过后端追加本地测试动态，确认 `major_only` 只展示重大节点红点，`all` 展示全部新动态红点。
- 本轮人工测试未提交正式反馈表。当前本地反馈表存在历史/探针测试记录，不作为本轮人工反馈问题处理。

## 6. 问题结论

当前没有发现 P0。

当前没有发现 API 契约阻塞。

当前没有发现人工 UI 验收阻塞。

当前没有收到需要处理的正式人工反馈。

下一步建议：

1. 进入内测准备。
2. 准备内测说明、反馈查看方式和测试数据处理策略。
3. 后续如出现问题，只按 `P0/P1/P2` 记录并小范围修复，不扩新功能。
