# 关注额度与游客合并后端接口清单 v1

## 一、目标

支持以下产品规则：

- 游客：可关注 `5` 个专题
- 免费登录用户：可关注 `10` 个专题
- 付费用户：可关注 `50` 个专题
- 游客关注先存在本地
- 登录后把游客关注合并进正式账号

## 二、接口清单

### 1. `GET /users/capabilities`

用途：前端获取当前用户能力和关注额度。

鉴权：

- 可匿名
- 已登录时返回正式账号能力
- 未登录时返回 guest 能力

未登录返回：

```json
{
  "success": true,
  "data": {
    "authenticated": false,
    "accountTier": "guest",
    "followLimit": 5,
    "followCount": null,
    "remainingFollowQuota": null
  }
}
```

已登录免费用户返回：

```json
{
  "success": true,
  "data": {
    "authenticated": true,
    "accountTier": "free",
    "followLimit": 10,
    "followCount": 4,
    "remainingFollowQuota": 6
  }
}
```

字段：

- `authenticated`
- `accountTier`
- `followLimit`
- `followCount`
- `remainingFollowQuota`

### 2. `POST /topics/{topicId}/follow`

用途：已登录用户正式关注专题。

鉴权：

- 必须登录

成功响应：

```json
{
  "success": true,
  "data": {
    "followed": true,
    "item": {
      "followId": "follow_001",
      "topicId": "topic_001",
      "isPinned": false,
      "followedAt": "2026-04-19T10:00:00Z"
    },
    "capabilities": {
      "accountTier": "free",
      "followLimit": 10,
      "followCount": 5,
      "remainingFollowQuota": 5
    }
  }
}
```

需要校验：

- 是否已登录
- `topicId` 是否有效
- 是否已关注
- 是否达到关注上限

错误码建议：

- `AUTH_REQUIRED`
- `TOPIC_NOT_FOUND`
- `TOPIC_ALREADY_FOLLOWED`
- `FOLLOW_LIMIT_REACHED`
- `UPGRADE_REQUIRED_FOR_MORE_FOLLOWS`

### 3. `DELETE /topics/{topicId}/follow`

用途：取消关注。

鉴权：

- 必须登录

成功响应：

```json
{
  "success": true,
  "data": {
    "followed": false,
    "topicId": "topic_001",
    "capabilities": {
      "accountTier": "free",
      "followLimit": 10,
      "followCount": 4,
      "remainingFollowQuota": 6
    }
  }
}
```

错误码建议：

- `AUTH_REQUIRED`
- `TOPIC_NOT_FOUND`
- `TOPIC_NOT_FOLLOWED`

### 4. `POST /users/merge-guest-follows`

用途：登录后，把游客本地关注列表合并到正式账号。

鉴权：

- 必须登录

请求示例：

```json
{
  "guestTopicIds": [
    "topic_001",
    "topic_002",
    "topic_003"
  ]
}
```

成功响应：

```json
{
  "success": true,
  "data": {
    "mergedTopicIds": ["topic_001", "topic_002"],
    "alreadyFollowedTopicIds": ["topic_003"],
    "skippedTopicIds": [],
    "followCount": 7,
    "followLimit": 10,
    "remainingFollowQuota": 3
  }
}
```

部分合并成功示例：

```json
{
  "success": true,
  "data": {
    "mergedTopicIds": ["topic_001"],
    "alreadyFollowedTopicIds": [],
    "skippedTopicIds": ["topic_002", "topic_003"],
    "followCount": 10,
    "followLimit": 10,
    "remainingFollowQuota": 0
  }
}
```

合并规则：

1. 先取账号已有关注
2. 再按 `guestTopicIds` 顺序处理
3. 无效 topic 跳过
4. 已关注的不重复写入
5. 达到上限后剩余全部跳过

错误码建议：

- `AUTH_REQUIRED`
- `INVALID_GUEST_TOPIC_IDS`
- `GUEST_FOLLOW_MERGE_EMPTY`

### 5. `GET /topics/followed`

用途：登录后刷新正式关注列表。

鉴权：

- 必须登录

说明：

- 合并 guest follows 后，前端应立即调用这个接口刷新“我的关注”

## 三、接口之间的关系

### 游客阶段

前端不调用正式 follow 接口。

前端只做：

- 本地保存 `guestFollowTopicIds`
- 本地控制最多 `5` 个

### 登录后

前端流程建议：

1. `POST /auth/login`
2. `POST /users/merge-guest-follows`
3. `GET /topics/followed`
4. 清空本地 `guestFollowTopicIds`

## 四、错误码清单建议

建议新增：

- `FOLLOW_LIMIT_REACHED`
- `LOGIN_REQUIRED_FOR_MORE_FOLLOWS`
- `UPGRADE_REQUIRED_FOR_MORE_FOLLOWS`
- `INVALID_GUEST_TOPIC_IDS`
- `GUEST_FOLLOW_MERGE_EMPTY`

建议语义：

- 游客超限：前端直接拦截并提示登录，不一定打后端错误
- 免费用户超限：返回 `UPGRADE_REQUIRED_FOR_MORE_FOLLOWS`
- 付费用户超限：返回 `FOLLOW_LIMIT_REACHED`

## 五、前端需要怎么配合

### 游客点击关注

- 未满 `5` 个：本地加入
- 满 `5` 个：提示“登录后可关注 10 个专题”

### 登录成功后

- 如果本地有 `guestFollowTopicIds`
- 自动调 `POST /users/merge-guest-follows`
- 刷新 `GET /topics/followed`
- 清空本地 guest 数据

### 已登录用户点击关注

- 直接调 `POST /topics/{topicId}/follow`
- 用返回里的 `capabilities` 更新剩余额度提示

## 六、推荐落地顺序

1. 先加 `GET /users/capabilities`
2. 再补 `POST /users/merge-guest-follows`
3. 再让前端接游客关注本地逻辑
4. 最后补更细的文案和引导

## 七、一句话版本

第一阶段后端新增 2 个核心能力就够了：

- `GET /users/capabilities`
- `POST /users/merge-guest-follows`

正式关注继续走现有 `follow/unfollow`，游客关注先本地存，登录后再合并。
