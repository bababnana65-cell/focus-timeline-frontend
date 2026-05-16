# 当前版本冻结记录 v1

## 一、记录目的

本文记录当前真实 HTTP 最终回归通过后的版本冻结结论。

本记录只用于确认已经跑通的主路径能力，不新增规则，不扩展新功能。

## 二、冻结时间

- 冻结日期：2026-04-25
- 联调环境：真实 HTTP
- 后端地址：`http://127.0.0.1:8010`
- 后端健康检查：`GET /health`
- 后端回归：`scripts/smoke_test.py` 已通过

说明：

- smoke test 中出现的 `forced followed payload failure` 是测试主动注入的异常，用于验证 `/topics/followed` 单条专题聚合失败时不会导致整个接口 500。
- 该异常不是当前 live 服务的真实业务失败。

## 三、本轮已通过并冻结的能力

### 1. guest follow 主链路

- 游客可先浏览推荐与时间轴
- 游客关注 1 到 5 个专题正常
- 第 6 个关注触发登录引导
- 登录成功后自动补上第 6 个关注
- `merge-guest-follows` 正常执行
- 取消关注后释放游客额度，可继续关注或新建专题

### 2. guest create 服务端链路

- 游客新建专题走服务端创建
- 创建成功后直接进入专题
- 不再把本地 `custom-*` 当正式事实源
- 同一 guest 会话下，重启后仍可读取 detail / timeline
- 游客新建专题不再受 24 小时 3 次创建限制
- 创建后自动关注仍受当前有效关注数上限 5 控制

### 3. 登录用户创建专题

- 登录用户新建专题走 `POST /topics/create`
- 创建后直接进入正式服务端专题
- 初始空 timeline 可正常处理

### 4. 第 6 个新建专题续接

- 游客达到上限后新建第 6 个专题会先触发登录
- 登录成功后自动继续创建
- 用户不需要重新填写

### 5. merge / claim 与账号 quota

- 登录后 `merge-guest-follows` 不突破账号 quota
- `claim-guest-topics` 不突破账号 quota
- 免费登录用户关注上限为 10
- 账号满额时，后端返回 `skippedTopics.reason = FOLLOW_LIMIT_REACHED`
- 因额度不足未同步的游客专题不应被直接丢弃

### 6. 刷新能力

- 推荐页下拉刷新请求 `GET /recommendations`
- “我的关注”页下拉刷新请求 `GET /topics/followed`
- 刷新成功时用服务端最新数据覆盖当前展示
- 刷新失败时保留旧内容并给轻提示

### 7. 阶段 7C 初始化主路径

- 新建专题后先进入 `draft / pending`
- 主路径可从 `pending` 推进到 `ready`
- timeline 不再长期为空
- 专题最终可进入可阅读状态

说明：

- `draft / running`
- `draft / failed`

以上两个状态保留为后续补充验证项，不阻塞当前主路径冻结。

### 8. 关注专题更新提醒

- `/topics/followed` 返回 `hasRecentUpdate = true` 时，列表卡片显示最新摘要和时间
- 任一关注专题有未读更新时，底部“我的关注”tab 显示红点
- 用户进入专题详情 / 时间线后，后端更新 `lastViewedAt`
- 再次刷新后，红点和列表高亮消失
- `/topics/followed` 不因单个专题聚合异常导致整体 500

### 9. 登录验证码体验

- 验证码重试等待时间使用 `cooldownSeconds`
- 不再误用 `expiresInSeconds`

### 10. timeline 时间精度兼容

- 后端支持 `time_precision = minute`
- `GET /topics/{topicId}/timeline` 可正常返回分钟级事件
- 不再出现 `TimePrecision.minute` 枚举缺失导致的 500

## 四、当前冻结规则

当前版本按以下规则冻结：

- 专题创建后不可编辑
- 专题不可删除
- 专题不可归档
- 用户唯一收口动作是取消关注
- 游客创建专题是服务端正式 Topic，不是长期本地草稿
- 登录后合并的是关注关系与 ownership，不是上传本地草稿
- 游客关注额度按当前有效关注数判断
- 游客创建专题不再按历史创建次数限流
- 创建后自动关注仍受 follow quota 限制

## 五、当前不再扩展的范围

本轮冻结后不继续扩展：

- 编辑专题定义
- 删除专题
- 归档专题
- 完整任务平台
- 更大 AI 工作流
- 系统推送通知
- 通知中心
- 复杂未读数
- 逐事件已读
- 独立“我的专题”入口

底层能力 `GET /topics/mine` 与 `POST /topics/{topicId}/retry-initialization` 可以保留，但当前不作为对外 UI 主路径。

## 六、后续处理规则

冻结后只接受以下类型工作：

- 明确 bugfix
- 回归失败修复
- 契约字段修正
- 空值 / 默认值修正
- 状态流不一致修正
- 日志与诊断增强

如果产品规则变化：

- 新增 `v2` 文档
- 不直接覆盖本 `v1` 记录
- 不在当前冻结版本里顺手扩新功能

## 七、一句话结论

当前真实 HTTP 最终回归已通过，本版本按“已跑通、先冻结”处理。

后续不再扩新范围，只做 bugfix / 回归。
