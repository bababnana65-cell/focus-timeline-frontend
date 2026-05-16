# Ownership Claim 后端最小实现规划清单 v1

本文用于把 `ownership claim` 从规则草案推进到“可实现的后端最小任务清单”。

目标：

- 不扩大范围
- 不一次性做完整 guest 账户体系
- 先把登录后认领 guest-created topic 的最小链路跑通

适用前提：

- `guest create` 已经是服务端专题
- `creator_guest_key` 已存在
- 同 `guestKey` 下的 guest read access 已跑通

---

## 一、这轮实现的目标

本轮只做最小 `ownership claim` 能力：

1. 登录后可认领 guest-created topic
2. 认领成功后：
   - `owner_user_id = current_user.id`
3. 幂等返回：
   - `claimedTopicIds`
   - `alreadyOwnedTopicIds`
   - `skippedTopicIds`
4. 不引入新的复杂状态流

这轮不做：

- 完整 guest 用户体系
- guest topic 批量转移审计大系统
- UI 大改
- 复杂权限模型

---

## 二、后端实现顺序

建议按这个顺序做。

### 1. 先补最小接口

新增：

- `POST /users/claim-guest-topics`

请求要求：

- `Authorization: Bearer <token>`
- `X-Timeliness-Guest-Key`
- body:

```json
{
  "topicIds": ["topic_001", "topic_002"]
}
```

---

### 2. 先做最小资格校验

每个 `topicId` 逐个校验：

1. `topic` 是否存在
2. `topic.kind == user_created`
3. `topic.creator_guest_key == request guestKey`
4. `topic.owner_user_id is null`
   - 或已等于当前用户

不符合条件的直接记入：

- `skippedTopicIds`

---

### 3. 幂等处理

三种结果必须分开：

#### A. 未认领

- `owner_user_id is null`
- `creator_guest_key` 匹配
- 执行认领
- 进入 `claimedTopicIds`

#### B. 已属于当前用户

- `owner_user_id == current_user.id`
- 不重复写
- 进入 `alreadyOwnedTopicIds`

#### C. 不可认领

包括：

- 不存在
- guestKey 不匹配
- 已属于其他用户
- 不是 `user_created`

进入：

- `skippedTopicIds`

---

### 4. claim 成功后的写入动作

建议最小写入：

1. `topic.owner_user_id = current_user.id`
2. 保留 `creator_guest_key`
   - 第一版先不清空
3. 如当前账号尚未 follow 该 topic：
   - 可补一条 follow 关系
   - 但不要把它当成“新增普通 follow”去再扣额度

---

## 三、和 follow quota 的关系

这轮建议固定成：

- `claim` 本身不单独再消耗新的 follow quota

原因：

- 被 claim 的专题原本就是当前 guest 已拥有/已关注语义下的资产
- 不是登录后凭空新增的陌生 topic

实现建议：

- 如果登录后该用户尚未正式 follow 此 topic
- claim 时一并补齐 follow 关系
- 但不再额外触发普通 follow 超限错误

注意：

这条规则要和现有 `merge-guest-follows` 协同，不要造成重复 follow 写入冲突。

---

## 四、建议的登录后顺序

前后端统一建议：

1. `merge-guest-follows`
2. `claim-guest-topics`
3. 刷新：
   - 我的关注
   - 当前专题 / 我的专题

不要反过来。

原因：

- 先把关系并入账号
- 再把 owner 权限认领到账号
- 最终状态更稳定

---

## 五、错误语义建议

建议新增或明确这些错误码：

- `GUEST_TOPIC_CLAIM_EMPTY`
- `GUEST_TOPIC_CLAIM_INVALID`
- `GUEST_TOPIC_CLAIM_FORBIDDEN`

但第一版更推荐：

- 把大多数“单个 topic 不可认领”的情况放到成功响应里的 `skippedTopicIds`
- 不轻易把“部分失败”做成整请求失败

所以：

- **空请求 / 格式错误**：返回错误
- **部分 claim 成功**：返回 200 + 结果列表

---

## 六、最小响应草案

```json
{
  "success": true,
  "data": {
    "claimedTopicIds": ["topic_001"],
    "alreadyOwnedTopicIds": ["topic_002"],
    "skippedTopicIds": ["topic_003"],
    "followCount": 6,
    "followLimit": 10,
    "remainingFollowQuota": 4
  }
}
```

说明：

- 额度字段继续带回，便于前端统一刷新状态
- 即使 claim 本身不再单独扣额度，也允许前端借此刷新当前能力态

---

## 七、数据库与模型最小改动

这轮原则上不需要再新增表。

依赖已有字段：

- `topics.owner_user_id`
- `topics.creator_guest_key`
- `user_topic_follows`

第一版不新增：

- `guest_claim_records`
- `guest_claim_audit`

如果后续需要运营审计，再进入 v2。

---

## 八、测试建议

后端最小测试建议补这 6 个点：

1. 未登录调用 claim -> `AUTH_REQUIRED`
2. guestKey 缺失 -> `GUEST_TOPIC_CLAIM_INVALID` 或同等错误
3. claim 成功 -> `owner_user_id` 被写入
4. 再次 claim 同一 topic -> 进入 `alreadyOwnedTopicIds`
5. claim 他人/不匹配 topic -> 进入 `skippedTopicIds`
6. claim 后 detail/timeline 用登录账号可继续访问

---

## 九、前端配合点

前端这轮不需要大改，只要：

1. 登录成功后，在已有 `merge-guest-follows` 后面追加调用 claim
2. 本地保留 `guestCreatedTopicIds`
3. claim 成功后刷新：
   - 我的关注
   - 当前专题

不需要：

- 上传本地草稿
- 上传 seedEntries
- 重新创建 topic

---

## 十、实现完成的标志

满足以下条件即可认为这轮最小实现完成：

1. guest-created topic 登录后能被当前账号认领
2. 已认领的 topic 再次 claim 不报错
3. 认领后当前账号能稳定读取和维护该 topic
4. 前端不需要重新创建或上传草稿

---

## 一句话版本

**ownership claim 的后端最小实现，只需要新增一个 `POST /users/claim-guest-topics`，基于 `guestKey + topicIds` 把 guest-created topic 的 `owner_user_id` 认领到当前账号，并保证幂等即可。**
