# 阶段 7B 后端 Guest Create Identity 与接口草案 v1

本文用于定义阶段 7B 中“游客创建服务端专题”的后端最小设计，重点解决：

- guest create identity
- 游客创建后的专题读写边界
- 登录后 ownership claim
- 游客创建限流
- 不影响已稳定的 guest follow / merge v1 链路

---

## 一、目标

阶段 7B 的目标不是引入完整 guest 用户体系，而是在不扩大范围过多的前提下，让游客也能：

1. 在服务端正式创建 `Topic`
2. 持续读取自己刚创建的服务端专题
3. 登录后把“游客创建关系”认领到正式账号
4. 继续遵守：
   - follow quota
   - create rate limit
   - 默认不进公开推荐池

---

## 二、最小 guest identity 方案

### 1. 统一使用 `guestKey`

阶段 7B 建议采用一个最小而稳定的游客标识：

- `guestKey`

来源建议：

- 前端首次安装 / 首次进入时生成 UUID
- 保存在本地持久化存储中
- 在游客模式下持续复用

### 2. 传输方式

建议统一通过请求头传递：

- `X-Timeliness-Guest-Key: <uuid>`

原因：

- 不污染已有 DTO 主体
- 后端可在多个接口复用
- 便于后续接入 guest read / guest create / claim

### 3. 当前不做的事

当前不引入：

- `guest_users` 表
- 完整 guest session 认证体系
- guest token 刷新机制

---

## 三、最小数据模型建议

### 1. `topics`

建议新增字段：

- `creator_guest_key`：可空、索引

用途：

- 标识该专题是否由某个游客创建
- 支撑后续 guest read access
- 支撑登录后 ownership claim

建议语义：

- 登录用户创建：`creator_guest_key = null`
- 游客创建：`creator_guest_key = <guestKey>`

### 2. `owner_user_id`

继续沿用现有字段。

建议语义：

- 登录用户创建时：`owner_user_id = user.id`
- 游客创建时：`owner_user_id = null`
- 登录后 claim 成功：`owner_user_id = current_user.id`

### 3. 当前不额外新增的表

第一阶段先不新增：

- `guest_topics`
- `guest_claim_records`
- `guest_sessions`

如后续确有需要，再进入 v2。

---

## 四、游客创建接口

### 1. 路由建议

继续复用：

- `POST /topics/create`

### 2. 调用条件

允许两种调用方式：

1. 已登录用户：
   - 走现有 Bearer token
2. 游客：
   - 不带 Authorization
   - 但必须带 `X-Timeliness-Guest-Key`

### 3. 请求体

延续阶段 7A：

```json
{
  "title": "低空经济试点",
  "summary": "关注试点城市、航线开放与商业化进度",
  "definition": {
    "coreKeywords": ["低空经济", "试点城市"],
    "extendedKeywords": ["航线开放", "商业化"],
    "excludedKeywords": ["无关评论"]
  },
  "autoFollow": true
}
```

### 4. 游客创建时的默认写入规则

建议默认：

- `kind = user_created`
- `visibility = private`
- `status = draft`
- `owner_user_id = null`
- `creator_guest_key = guestKey`

### 5. 创建响应

建议和阶段 7A 保持一致：

```json
{
  "success": true,
  "data": {
    "id": "topic_001",
    "topic": {
      "topicId": "topic_001",
      "title": "低空经济试点",
      "summary": "关注试点城市、航线开放与商业化进度",
      "status": "draft",
      "kind": "user_created",
      "visibility": "private",
      "initializationState": "pending",
      "topicDefinition": {
        "coreKeywords": ["低空经济", "试点城市"],
        "extendedKeywords": ["航线开放", "商业化"],
        "excludedKeywords": ["无关评论"]
      }
    },
    "followed": true,
    "capabilities": {
      "authenticated": false,
      "accountTier": "guest",
      "followLimit": 5,
      "followCount": null,
      "remainingFollowQuota": null
    },
    "initializationState": "pending"
  }
}
```

说明：

- 对游客返回 `followed = true` 表示“当前游客本地语义应视为已关注”
- 不代表已写入正式 `user_topic_follows`

---

## 五、游客读取权限

### 1. 问题

游客创建的专题默认是：

- `visibility = private`
- `owner_user_id = null`

如果没有额外规则，游客自己创建后将无法再次读取。

### 2. 最小规则

对以下接口增加 guest read access：

- `GET /topics/{topicId}`
- `GET /topics/{topicId}/timeline`
- `GET /topics/{topicId}/timeline/search`

规则：

如果：

- `topic.creator_guest_key == request guestKey`

则允许游客读取该专题，即使它是 private。

### 3. 实现建议

在现有 `ensure_topic_access(...)` 之外，增加一个最小 guest 分支：

- 读接口若无用户但有 `guestKey`
- 且 `creator_guest_key` 匹配
- 则允许访问

---

## 六、follow quota 规则

游客创建若隐含自动关注，必须继续受当前 follow quota 限制。

固定规则仍然是：

- guest：5
- free：10
- pro：50
- `follow_limit_override` 优先

### 关键点

游客创建的 follow quota 与“正式 user_topic_follows 数量”不是同一套存储。

阶段 7B 最小方案建议：

- 由前端继续维护 guest 本地已关注 topicIds
- 创建请求前前端先做 guest 额度门禁
- 后端同时保留防御性校验入口（后续如补 guest create count / guest topic list，可进一步收紧）

当前阶段不要为了 guest follow quota 新增完整 guest relation 表。

---

## 七、游客创建限流

follow quota 不是 create rate limit 的替代。

建议新增单独限流：

- 每 `guestKey` 每日最多 `3` 次创建
- 可额外叠加 IP 维度限流

建议错误码：

- `TOPIC_CREATE_RATE_LIMITED`

建议提示语义：

- 游客今日创建次数已达上限，请稍后再试或登录后继续

---

## 八、登录后 ownership claim

### 1. 为什么需要单独 claim

guest create 不仅是 follow 关系问题，还涉及：

- 谁是 owner
- 谁能后续编辑 / 删除 / 重跑 AI

所以登录后必须考虑 ownership claim。

### 2. 建议接口

建议新增：

- `POST /users/claim-guest-topics`

鉴权：

- 必须登录
- 同时要求 `X-Timeliness-Guest-Key`

请求示例：

```json
{
  "guestTopicIds": ["topic_001", "topic_002"]
}
```

### 3. claim 规则

对于每个 `topicId`：

1. topic 必须存在
2. topic 必须是 `user_created`
3. `creator_guest_key` 必须与当前请求头的 `guestKey` 匹配
4. `owner_user_id` 必须为空或已是当前用户
5. 满足条件后：
   - `owner_user_id = current_user.id`

### 4. 响应建议

```json
{
  "success": true,
  "data": {
    "claimedTopicIds": ["topic_001"],
    "alreadyOwnedTopicIds": ["topic_002"],
    "skippedTopicIds": []
  }
}
```

### 5. 与 merge-guest-follows 的关系

建议：

- `merge-guest-follows` 继续只管 follow 关系
- `claim-guest-topics` 只管 ownership

不要在当前阶段把两个稳定语义强行混在一个接口里。

---

## 九、推荐池与可见性

游客创建的专题默认不应进入公开推荐池。

建议保持：

- `kind = user_created`
- `visibility = private`
- `status = draft/pending`

只有后续满足更严格条件时，才考虑：

- 转公开
- 进入公开推荐池

---

## 十、错误码建议

阶段 7B 建议使用：

- `FOLLOW_LIMIT_REACHED`
- `UPGRADE_REQUIRED_FOR_MORE_FOLLOWS`
- `TOPIC_CREATE_RATE_LIMITED`
- `GUEST_IDENTITY_REQUIRED`
- `GUEST_CREATE_CLAIM_MISMATCH`
- `TOPIC_DEFINITION_INVALID`

其中：

- 游客无 `guestKey` 调用 guest create：`GUEST_IDENTITY_REQUIRED`
- claim 时 key 不匹配：`GUEST_CREATE_CLAIM_MISMATCH`

---

## 十一、推荐落地顺序

建议按这个顺序推进：

1. 冻结 `guestKey` 语义与传输方式
2. 给 `Topic` 补 `creator_guest_key`
3. 支持 guest `POST /topics/create`
4. 支持 guest read access
5. 补 `TOPIC_CREATE_RATE_LIMITED`
6. 新增 `POST /users/claim-guest-topics`

---

## 十二、一句话版本

阶段 7B 的最小方案是：

**用 `guestKey` 标识游客创建者；游客可通过服务端 `POST /topics/create` 创建 private draft 专题，并在带同一 `guestKey` 时继续读取；登录后再通过单独的 `claim-guest-topics` 接口认领 ownership，同时继续沿用现有的 follow quota 与 guest merge 语义。**

