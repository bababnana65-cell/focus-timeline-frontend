# Ownership Claim 后端接口与规则草案 v1

本文用于定义阶段 7B 之后，“游客创建的服务端专题在登录后如何正式认领到账号”的后端最小规则与接口草案。

目标：

- 不回退到本地草稿上传语义
- 登录后认领的是**服务端已存在专题的 ownership**
- 不影响已稳定的：
  - guest create
  - guest follow / merge
  - follow quota

---

## 一、核心结论

登录后 ownership claim 的本质是：

1. 游客创建的专题已经存在于服务端
2. 登录后，用户对这些专题发起“认领”
3. 后端校验该专题是否确实属于当前 `guestKey`
4. 校验通过后，把专题 `owner_user_id` 绑定到当前账号

也就是说：

- claim 的对象是**服务端 Topic**
- 不是上传一份本地草稿
- 也不是重新创建一遍 Topic

---

## 二、为什么要单独做 claim

当前阶段 7B 已经做到：

- guest create 是服务端专题
- 同一 `guestKey` 下可继续读取 detail / timeline

但如果没有 claim，登录后仍然缺这些能力：

- 无法明确“这个游客创建的专题正式归谁”
- 后续谁能编辑、删除、继续维护它不清楚
- 换设备后无法作为正式账号资产恢复
- guest 读权限和 user owner 权限会长期并存，语义混乱

因此：

**登录后不仅要 merge follow，还要为 guest-created topic 提供 ownership claim。**

---

## 三、最小数据语义

### 1. `topics.owner_user_id`

继续沿用现有字段。

语义：

- 登录用户创建：`owner_user_id = user.id`
- 游客创建：`owner_user_id = null`
- claim 成功后：`owner_user_id = current_user.id`

### 2. `topics.creator_guest_key`

继续沿用阶段 7B 的最小 guest create 设计。

语义：

- 只有 guest-created topic 才有值
- claim 时用它判断“当前 guest 是否有资格认领”

### 3. claim 后 `creator_guest_key` 如何处理

建议第一版：

- **保留** `creator_guest_key`
- 但专题 owner 已以 `owner_user_id` 为准

原因：

- 便于审计和排错
- 便于幂等 claim 判断
- 后续如要清理，再进入 v2

---

## 四、接口草案

### 1. `POST /users/claim-guest-topics`

用途：

- 登录后，把当前 `guestKey` 下创建的服务端专题认领到当前账号

鉴权：

- 必须登录
- 必须带 `Authorization: Bearer <token>`
- 必须带 `X-Timeliness-Guest-Key: <guestKey>`

---

## 五、请求体

建议最小请求体：

```json
{
  "topicIds": [
    "topic_001",
    "topic_002"
  ]
}
```

说明：

- 前端只提交需要认领的正式 `topicId`
- 不提交本地草稿内容
- 不提交 seed entries

---

## 六、响应草案

### 成功响应

```json
{
  "success": true,
  "data": {
    "claimedTopicIds": ["topic_001"],
    "alreadyOwnedTopicIds": ["topic_002"],
    "skippedTopicIds": [],
    "followCount": 6,
    "followLimit": 10,
    "remainingFollowQuota": 4
  }
}
```

字段说明：

- `claimedTopicIds`
  - 本次成功认领 ownership 的专题
- `alreadyOwnedTopicIds`
  - 这些专题本来就已经属于当前账号
- `skippedTopicIds`
  - 因 guestKey 不匹配、topic 不存在、或其他校验失败而跳过
- `followCount / followLimit / remainingFollowQuota`
  - 为了让前端在 claim 后顺手刷新额度态

---

## 七、认领资格规则

### 一个专题可被 claim 的前提

必须同时满足：

1. `topic.kind == user_created`
2. `topic.creator_guest_key == request guestKey`
3. `topic.owner_user_id is null`
   - 或已经是当前 `user.id`
4. 专题当前可被该用户读取

### 不允许 claim 的情况

以下情况应跳过或报错：

1. `creator_guest_key` 不匹配
2. 专题已经归属于其他用户
3. 专题不存在
4. 该专题不是 guest-created topic

---

## 八、幂等规则

claim 必须支持幂等。

建议语义：

### 情况 A：topic 尚未被认领
- 执行 claim
- `owner_user_id = current_user.id`
- 返回到 `claimedTopicIds`

### 情况 B：topic 已经属于当前用户
- 不重复写
- 返回到 `alreadyOwnedTopicIds`

### 情况 C：topic 已属于其他用户
- 不覆盖
- 返回到 `skippedTopicIds`

这能避免：

- 登录后反复 claim
- 前端重试导致异常
- 不必要的冲突

---

## 九、与 follow merge 的关系

claim 和 `merge-guest-follows` 不是一回事。

### `merge-guest-follows`
- 合并的是关注关系
- 作用对象：guest 本地 follow 列表

### `claim-guest-topics`
- 认领的是 ownership
- 作用对象：guest 已创建的服务端专题

建议前端登录后的顺序：

1. `merge-guest-follows`
2. `claim-guest-topics`
3. 刷新“我的关注” / 我的专题

原因：

- 先把 follow 状态归到账号
- 再认领 owner 权限
- 最终状态更稳定

---

## 十、follow quota 与 claim 的关系

claim 本身**不应再次消耗新的 follow quota**。

原因：

- guest create 时，这个专题在 guest 语义里已经视为“已关注”
- 登录后 claim 是把已有资产归到账号，不是新增一个完全无关的专题

因此建议：

1. 如果 claim 的专题当前账号还未 follow
   - 且该专题本来属于该 guest create 资产
   - 则 claim 过程中允许把它作为“已有 guest 资产”并入账号关系
2. 这一步不单独再按普通 follow 新增计算

但是：

- 如果你们后续希望更保守，也可以要求 claim 前先走过 guest merge
- 第一版建议不要把它做复杂，保持 claim 成功后最终账号状态一致即可

---

## 十一、错误码草案

建议新增：

- `GUEST_TOPIC_CLAIM_EMPTY`
- `GUEST_TOPIC_CLAIM_INVALID`
- `GUEST_TOPIC_CLAIM_FORBIDDEN`
- `GUEST_TOPIC_CLAIM_PARTIAL`

建议语义：

### `GUEST_TOPIC_CLAIM_EMPTY`
- 请求里没有可认领的 `topicIds`

### `GUEST_TOPIC_CLAIM_INVALID`
- 请求体格式错误
- 或 topicIds 非法

### `GUEST_TOPIC_CLAIM_FORBIDDEN`
- 当前 `guestKey` 与 topic 的 `creator_guest_key` 不匹配

### `GUEST_TOPIC_CLAIM_PARTIAL`
- 更推荐作为“成功响应里的业务语义”
- 不一定做成 HTTP error
- 即：部分 claim 成功，部分 skipped

---

## 十二、前端触发建议

登录成功后，如果当前运行时存在：

- `guestKey`
- `guestCreatedTopicIds`

前端应自动执行：

1. `POST /users/merge-guest-follows`
2. `POST /users/claim-guest-topics`
3. 刷新专题列表 / 当前专题状态

前端不需要在 claim 时上传：

- 本地草稿内容
- seed entries
- 本地完整 custom facts

只上传正式 `topicId` 列表即可。

---

## 十三、推荐的后端处理顺序

后端实现建议顺序：

1. 校验登录态
2. 校验 `guestKey`
3. 校验 `topicIds`
4. 逐个 topic 做：
   - 是否存在
   - 是否 `user_created`
   - 是否 `creator_guest_key` 匹配
   - 是否已被其他用户认领
5. 成功的设置：
   - `owner_user_id = current_user.id`
6. 如需要，顺手对当前账号补齐 follow 关系
7. 返回 claimed / alreadyOwned / skipped 列表

---

## 十四、一句话版本

**ownership claim 不是上传本地草稿，而是把 guest 已在服务端创建的 Topic 正式认领到登录账号；它应作为 `merge-guest-follows` 之后的独立步骤，并且必须支持幂等。**
