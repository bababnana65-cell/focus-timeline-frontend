# Timeliness MVP Release Candidate 检查清单

用途：在单人 dogfooding 连续通过后，把当前版本整理成可追踪的 MVP RC 基线。当前不打正式 release tag，不做公网分发。

## 1. RC 基线

状态：本机 RC 验证通过。

当前基线：

- 前端仓库：`C:\Codex\Test\Timelinesss`
- 前端应用代码基线：`5eb3dbb`
- 后端仓库：`C:\Codex\Test\Timelinesss_backend`
- 后端 commit：`298bfd3`
- 后端地址：`http://127.0.0.1:8010`
- 客户端形态：Windows App，真实 HTTP 后端

当前范围：

- 只支持本机单人测试。
- 不对外发布安装包。
- 不接支付。
- 不接系统推送。
- 不新增功能。

## 2. Go / No-Go 标准

Go 条件：

- 前端静态检查通过。
- 前端测试通过。
- 后端 smoke / migration / classification / bucket favorite / feedback export 验证通过。
- Windows App 真实 HTTP 人工主流程通过。
- 当前没有 P0 / P1 未解决问题。
- API 契约没有前后端阻塞。

No-Go 条件：

- App 无法启动或持续连接失败。
- 登录、关注、创建、时间线读取任一主流程不可用。
- 后端出现主路径 500。
- 数据状态错乱，例如关注数、quota、merge/claim、收藏状态错误。
- 红点规则与 `hasRecentUpdate` / `latestNode.isMajor` 明显不一致。

## 3. 本机验证命令

前端：

```powershell
cd C:\Codex\Test\Timelinesss
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' analyze
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' test
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' build windows --debug
```

后端：

```powershell
cd C:\Codex\Test\Timelinesss_backend\backend
.\.venv\Scripts\python.exe scripts\verify_bucket_favorites.py
.\.venv\Scripts\python.exe scripts\smoke_test.py
.\.venv\Scripts\python.exe scripts\verify_migrations.py
.\.venv\Scripts\python.exe scripts\verify_topic_context_classification.py
.\.venv\Scripts\python.exe scripts\verify_profile_interests_feedback.py
.\.venv\Scripts\python.exe scripts\verify_feedback_export.py
.\.venv\Scripts\python.exe -m compileall app scripts
```

真实后端启动：

```powershell
cd C:\Codex\Test\Timelinesss_backend\backend
.\scripts\restart_local_8010.ps1
```

健康检查：

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8010/health -Method Get
```

## 4. 人工验收路径

每次 RC 前至少确认：

| 路径 | 状态 |
| --- | --- |
| Windows App 启动 | TODO |
| 首页推荐/热门/探索可读 | TODO |
| 游客关注 5 个限制 | TODO |
| 登录验证码 | TODO |
| 登录后 merge / claim | TODO |
| 创建时间线 | TODO |
| 详情页 / 时间线读取 | TODO |
| 我的关注红点 `off / major_only / all` | TODO |
| 我的页会员/兴趣/反馈/收藏入口 | TODO |
| 收藏 bucket 创建/取消/列表读取 | TODO |
| 后端断开时提示与旧数据保留 | TODO |

## 5. 当前已知限制

- 当前后端仍是本机地址 `127.0.0.1:8010`，只能在本机测试。
- 当前没有公网 HTTPS 后端。
- 当前没有安装包签名、自动更新、崩溃上报。
- 当前反馈表存在历史/探针数据，需要按时间和账号过滤。
- `.tmp/` 是前端本地未跟踪临时目录，不进入版本库。

## 6. 暂不推进项

本 RC 不做：

- 支付 / 订阅。
- 系统推送通知。
- 通知中心。
- 专题编辑、删除、归档。
- 新增 quota 规则。
- 完整后台管理系统。
- 复杂推荐算法重构。

## 7. 下一步决策

如果继续只有自己测试：

- 维持本机真实 HTTP dogfooding。
- 每天记录 PASS / P0 / P1 / P2。
- 不打正式 release tag。

如果准备给别人测试：

- 先部署公网 HTTPS 后端。
- 固定前端 API base URL 配置方式。
- 生成 Windows 可分发包。
- 准备测试账号、反馈收集方式和数据清理策略。

## 8. 2026-05-07 RC 验证记录

结论：PASS。

版本：

- 前端应用代码基线：`5eb3dbb`
- 后端代码基线：`298bfd3`
- 验证环境：Windows App + 本机真实 HTTP 后端 `http://127.0.0.1:8010`

自动验证：

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| `flutter analyze` | PASS | `No issues found` |
| `flutter test` | PASS | `125` tests passed |
| `flutter build windows --debug` | PASS | 生成 `build\windows\x64\runner\Debug\event_timeline.exe` |
| `verify_bucket_favorites.py` | PASS | `bucket favorite checks passed` |
| `smoke_test.py` | PASS | `smoke test passed`；日志里的 `forced followed payload failure` 是脚本主动注入的降级路径验证 |
| `verify_migrations.py` | PASS | `migration verification passed` |
| `verify_topic_context_classification.py` | PASS | `topic context classification checks passed` |
| `verify_profile_interests_feedback.py` | PASS | `profile interests and feedback checks passed` |
| `verify_feedback_export.py` | PASS | `feedback export checks passed` |
| `python -m compileall app scripts` | PASS | 退出码 `0` |

真实 HTTP：

- 首次 `/health` 检查发现 `127.0.0.1:8010` 未启动，连接被拒绝。
- 已执行 `backend\scripts\restart_local_8010.ps1` 重启本机真实后端。
- 重启后 `/health` 返回 `{"status":"ok","appName":"Timeliness Backend","environment":"local"}`。

人工验证：

- 用户确认当前测试没有问题。

遗留：

- 当前仍是本机单人 RC，不对外发布。
- 未打正式 release tag。
- 未生成公网后端配置或可分发安装包。
- 前端 `.tmp/` 仍为本地未跟踪临时目录，不进入版本库。

## 9. 2026-05-07 RC Tag 记录

已创建并推送本机 RC tag：

| 仓库 | tag | 指向 |
| --- | --- | --- |
| 前端 `Timelinesss` | `mvp-local-rc-20260507` | `015350f` |
| 后端 `Timelinesss_backend` | `mvp-local-rc-20260507` | `298bfd3` |

说明：

- 该 tag 只表示本机 MVP RC 验证基线。
- 不是正式公开 release。
- 不包含公网后端、安装包签名、自动更新或对外分发承诺。

## 10. 2026-05-07 RC 二次验证记录

结论：PASS。

触发原因：用户继续单人测试，反馈当前没有问题；重新跑完整本机验证，补充最新证据。

版本：

- 前端当前 HEAD：`0e734f3`
- 前端应用代码基线：仍为 `5eb3dbb`，之后仅有 RC 文档提交
- 后端当前 HEAD：`298bfd3`
- 验证环境：Windows App + 本机真实 HTTP 后端 `http://127.0.0.1:8010`

自动验证：

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| `flutter analyze` | PASS | `No issues found!` |
| `flutter test` | PASS | `+125: All tests passed!` |
| `flutter build windows --debug` | PASS | 生成 `build\windows\x64\runner\Debug\event_timeline.exe` |
| `verify_bucket_favorites.py` | PASS | `bucket favorite checks passed` |
| `smoke_test.py` | PASS | `smoke test passed` |
| `verify_migrations.py` | PASS | `migration verification passed` |
| `verify_topic_context_classification.py` | PASS | `topic context classification checks passed` |
| `verify_profile_interests_feedback.py` | PASS | `profile interests and feedback checks passed` |
| `verify_feedback_export.py` | PASS | `feedback export checks passed` |
| `python -m compileall app scripts` | PASS | 退出码 `0` |

备注：

- `smoke_test.py` 日志中的 `forced followed payload failure` 是脚本主动注入，用于验证关注列表 payload 构建失败时可降级且接口仍返回 `200`。
- Windows debug build 输出 `Nuget is not installed` 和 CMake dev warning，但构建命令退出码为 `0`，可执行文件已生成。
- 前端工作区仍只有未跟踪 `.tmp/`，未进入版本库。
- 后端工作区 clean。
