# 当前版本回归清单 v1

## 一、目标

本清单用于当前版本的发版前回归、联调回归与较大改动后的稳定性检查。

当前原则：

- 只覆盖已经确认“已跑通、先冻结”的能力
- 不在回归时扩新范围
- 如果规则变化，统一走 `v2`，不回写当前 `v1`

## 二、联调环境基线

### 后端

- 健康检查：`GET /health`
- 联调地址默认：
  - `http://127.0.0.1:8010`

### 前端

真实 HTTP 模式：

```powershell
flutter run --dart-define=TIMELINESS_USE_HTTP_BACKEND=true --dart-define=TIMELINESS_API_BASE_URL=http://127.0.0.1:8010
```

## 三、必须回归的冻结能力

### 1. guest follow 主链路

检查：

1. 新用户首次进入推荐页
2. 游客可先浏览推荐 / 时间轴
3. 游客关注 1~5 个专题正常
4. 第 6 个关注触发登录引导
5. 登录成功后自动补上第 6 个关注
6. `merge-guest-follows` 正常执行
7. 取消关注后释放游客额度，可继续关注或新建专题

通过标准：

- 不出现重复 follow 重试
- “我的关注”与 follow quota 状态一致
- 游客额度按当前有效关注数判断，不按历史创建次数判断

### 2. guest create 最小服务端链路

检查：

1. 游客创建专题走服务端创建
2. 创建成功后直接进入专题
3. 页面可正确显示初始化态
4. 同一 guest 会话下，重启后仍可读取 detail / timeline
5. 同一 guestKey 连续创建第 4 个专题不再返回 `TOPIC_CREATE_RATE_LIMITED`

通过标准：

- 不再生成本地 `custom-*` 作为正式事实源
- 同一 `guestKey` 可继续读自己的私有专题
- 创建专题不再按 24 小时次数限流，只受当前 follow quota 限制
- 游客关注 + 游客新建合计仍受未登录关注上限 5 控制

### 3. 登录用户创建专题

检查：

1. 登录用户创建走 `POST /topics/create`
2. 创建后直接进入正式服务端专题
3. 初始空 timeline 可正常处理

通过标准：

- 不再把本地 `custom-*` 当正式事实源

### 4. 第 6 个新建专题续接

检查：

1. 游客达到上限后点击新建专题
2. 先触发登录
3. 登录成功后自动继续创建
4. 不需要重新填写

### 5. ownership claim 最小链路

检查：

1. 登录后顺序：
   - `merge-guest-follows`
   - `claim-guest-topics`
   - 刷新状态
2. claim 成功
3. 再次 claim 幂等
4. claim 他人 topic 进入 `skipped`
5. claim 成功后当前账号可继续读 detail / timeline
6. 账号满额时，claim 不会绕过账号 follow quota

### 5A. 游客关注合并遇到账号满额

检查：

1. 登录账号已有 10 个关注
2. 退出登录
3. 以游客身份关注 / 创建若干专题
4. 再次登录后触发 `merge-guest-follows`
5. 账号关注数仍保持 10，不变成 15
6. 因额度不足未合并的游客专题不会被直接丢弃

通过标准：

- 登录合并不会突破账号 quota
- 后端返回 `skippedTopics.reason = FOLLOW_LIMIT_REACHED`
- 前端保留待合并 topicId，用户取消账号关注腾出额度后可继续同步

### 6. 推荐页下拉刷新

检查：

1. 下拉时直接请求 `GET /recommendations`
2. 服务端最新返回覆盖当前推荐数据
3. 刷新失败时保留旧数据
4. 有轻提示反馈

### 7. “我的关注”页下拉刷新

检查：

1. 下拉时直接请求 `GET /topics/followed`
2. 服务端重新聚合最新动态字段
3. 刷新失败时保留旧数据
4. 有轻提示反馈

### 8. 阶段 7C 主路径

检查：

1. 新建专题后先进入 `draft / pending`
2. 主路径从 `pending -> ready`
3. timeline 不再长期为空
4. 专题最终可进入可阅读状态

说明：

- `draft / running`
- `draft / failed`

当前仍可作为补充验证项，但不阻塞主路径通过。

### 9. 登录验证码体验

检查：

1. 验证码重试等待时间显示正确
2. 前端使用 `cooldownSeconds`
3. 不再误用 `expiresInSeconds`

### 10. 关注专题更新提醒

检查：

1. 后端给已关注专题返回：
   - `hasRecentUpdate = true`
   - `latestRelevantEventSummary` 有值
   - `latestRelevantEventAt` 晚于 `lastViewedAt`
2. “我的关注”页下拉刷新请求 `GET /topics/followed`
3. 列表内对应专题显示更新摘要和时间
4. 底部“我的关注”tab 显示红点
5. 用户点进专题详情 / 时间线后，后端记录新的 `lastViewedAt`
6. 再次回到“我的关注”并刷新后，红点和列表高亮消失

通过标准：

- 前端只按 `hasRecentUpdate` 决定红点和列表高亮
- 刷新失败时保留旧内容，不清空页面
- `GET /topics/followed` 不因单个专题聚合异常导致整体 500

### 11. timeline 时间精度兼容

检查：

1. 专题 timeline 中存在 `time_precision = minute` 的事件
2. 请求 `GET /topics/{topicId}/timeline`
3. 接口返回 200
4. entries 中可正常返回 `precision = minute`

通过标准：

- 后端 `TimePrecision` 支持 `minute`
- timeline 分桶支持分钟级精度
- spec API 展示文案支持分钟级精度
- 不再出现 `LookupError: 'minute' is not among the defined enum values`

## 四、当前底层已接通但不对外暴露的能力

以下能力目前保留为底层能力，不作为当前版本主路径 UI 入口：

- `GET /topics/mine`
- `POST /topics/{topicId}/retry-initialization`

如果后续重新开放“我的专题 / 状态 / 重试”入口，应单独开新范围。

## 五、回归时只记录的问题类型

- 契约字段问题
- 空值 / 默认值问题
- 排序问题
- token / session 问题
- guest merge / claim / follow quota 状态流问题
- 初始化状态推进问题
- 刷新失败时页面保留旧数据的问题
- 关注更新提醒的已读 / 未读状态问题
- timeline 时间精度兼容问题

## 六、当前不在回归范围内的内容

本清单当前不覆盖：

- 编辑专题定义
- 删除专题
- 归档专题
- 更完整的 ownership claim 扩展
- 完整任务平台
- 更大 AI 工作流
- 系统推送通知
- 通知中心
- 复杂未读数
- 逐事件已读

## 七、一句话结论

当前版本回归应围绕“已经冻结的稳定能力”进行。

只要这些冻结能力持续通过，就可以认为当前版本主路径稳定。
