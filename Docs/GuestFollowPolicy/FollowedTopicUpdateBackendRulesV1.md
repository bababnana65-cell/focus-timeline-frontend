# 关注专题更新提醒后端规则 v1

## 一、目标

本文件用于固化“我的关注”里关注专题更新提醒的后端正式规则。

当前已经通过真实联调的能力包括：

- `GET /topics/followed` 返回关注专题列表
- 每个关注专题返回最近相关动态
- 前端根据 `hasRecentUpdate` 展示列表高亮
- 底部“我的关注”tab 根据是否存在未读更新显示红点
- 用户进入专题后，后端更新已读时间，后续刷新时提醒消失

本文件只定义当前版本已确认的后端行为，不扩展通知中心、系统推送或复杂未读数。

## 二、核心字段

`GET /topics/followed` 中每个 item 需要稳定返回：

- `topicId`
- `title`
- `summary`
- `followedAt`
- `lastViewedAt`
- `latestRelevantEventAt`
- `latestRelevantEventSummary`
- `hasRecentUpdate`
- `unreadSignalCount`

当前版本 `unreadSignalCount` 固定保留为扩展位，不作为前端红点和高亮的判断依据。

## 三、未读判断规则

当前专题级未读提醒只使用一条规则：

```text
latestRelevantEventAt > lastViewedAt
```

如果成立：

- `hasRecentUpdate = true`
- 前端可显示列表高亮
- 底部“我的关注”tab 可显示红点

如果不成立：

- `hasRecentUpdate = false`

当前不做逐事件未读，不做未读数量，不做消息中心。

## 四、空值规则

如果一个专题还没有最近事件：

- `latestRelevantEventAt = null`
- `latestRelevantEventSummary = null`
- `hasRecentUpdate = false`

如果一个用户从未打开过该专题：

- `lastViewedAt` 可以为 `null`
- 当前版本不强制把它视为未读
- 后续如需调整“首次关注后已有历史事件是否算未读”，另开 v2

当前已验证路径主要覆盖：

- `latestRelevantEventAt` 有值
- `lastViewedAt` 有值
- 两者比较后得出 `hasRecentUpdate`

## 五、最近相关动态来源

当前后端以专题下最新的 timeline event 作为最近相关动态：

- `latestRelevantEventAt` 来自最新 `EventNode.event_time_at`
- `latestRelevantEventSummary` 优先使用事件 `summary`
- 如果 `summary` 为空，可回退到事件 `title`

后端应保证：

- 不因为单个事件字段异常导致整个 `/topics/followed` 失败
- 不因为单个关注专题聚合异常清空整个关注列表
- 异常时可以对单个 item 使用安全回退

## 六、已读清除规则

用户成功打开专题详情或时间线时，后端记录一次 topic view：

```text
lastViewedAt = now
```

下一次请求 `GET /topics/followed` 时：

- 如果 `lastViewedAt >= latestRelevantEventAt`
- 则 `hasRecentUpdate = false`

前端不需要单独调用“标记已读”接口。

## 七、刷新行为

“我的关注”页下拉刷新时，前端会重新请求：

```http
GET /topics/followed
```

后端需要在每次请求时重新聚合：

- 当前关注列表
- 最近相关动态
- 最新已读时间
- `hasRecentUpdate`

当前不要求新增刷新接口，也不要求服务端主动推送。

## 八、时间精度兼容

后端 timeline 事件必须兼容以下时间精度：

- `minute`
- `hour`
- `day`
- `month`
- `year`
- `decade`
- `century`
- `era`
- `approximate`

本规则来自一次真实联调问题：

- 数据库中存在 `time_precision = minute`
- 后端模型缺少 `minute`
- 读取专题 timeline 时触发 500

因此后端必须保证：

- `TimePrecision.minute` 是合法值
- timeline 分桶支持 `minute`
- API 展示文案支持 `minute`
- smoke test 覆盖 minute 精度事件

## 九、错误处理要求

`GET /topics/followed` 是首页级关键接口，后端应尽量避免因为单个专题异常导致整体 500。

当前要求：

- 单个关注专题聚合失败时，记录后端日志
- 对该 item 返回安全回退字段
- 整体接口仍尽量返回 200

但如果是认证、数据库不可用等全局问题，仍按通用错误语义返回。

## 十、当前不做的范围

当前 v1 不做：

- 系统推送通知
- 通知中心
- 复杂未读数
- 逐事件已读
- 多设备已读冲突合并
- 用户级通知偏好页
- 推荐页红点
- 单独“标记全部已读”接口

这些如果后续需要，新增 v2 文档。

## 十一、最小回归清单

后端每次改动相关逻辑后至少确认：

1. `GET /topics/followed` 返回 200
2. 当 `latestRelevantEventAt > lastViewedAt` 时，`hasRecentUpdate = true`
3. 当用户打开专题后，再次请求时 `hasRecentUpdate = false`
4. `latestRelevantEventSummary` 有稳定回退
5. timeline 中存在 `time_precision = minute` 时，`GET /topics/{topicId}/timeline` 不返回 500
6. smoke test 通过

## 十二、版本规则

本文件作为后端正式规则 v1。

后续如果调整未读定义、加入推送、通知中心、未读数量或多设备同步，新增 v2，不直接覆盖 v1。
