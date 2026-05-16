# 关注额度与游客合并数据库表调整建议 v1

## 一、总体建议

第一阶段不要为了“游客先关注，登录后合并”就把数据库做复杂。

最合适的是：

- 游客关注：前端本地保存
- 登录后合并：后端提供合并接口
- 数据库只先补：
  - 用户套餐层级
  - 用户关注上限
  - 合并记录/审计（可选）

第一阶段不建议建 guest 用户表。

## 二、第一阶段最小表调整

### 1. `users`

建议新增字段：

- `account_tier`
- `follow_limit_override`

建议含义：

- `account_tier`: `free | pro`
- `follow_limit_override`: 运营临时覆盖上限，可空

说明：

- 未登录游客不进 `users`
- 游客额度 `5` 由前端本地态 + 后端能力接口共同约定
- 已登录用户才看 `users.account_tier`

### 2. `user_topic_follows`

这张表第一阶段不用改核心结构。

继续存正式账号关注关系即可：

- `user_id`
- `topic_id`
- `is_pinned`
- `followed_at`

因为游客关注第一阶段不进库，所以这里不需要加 `guest_id`。

### 3. 可选审计表：`guest_follow_merge_logs`

如果希望后面可追踪“游客关注合并到账号”的情况，建议加这张表。

字段建议：

- `id`
- `user_id`
- `guest_follow_count`
- `merged_count`
- `skipped_count`
- `merged_topic_ids_json`
- `skipped_topic_ids_json`
- `created_at`

用途：

- 审计
- 排查用户投诉
- 观察游客转注册效果

## 三、第一阶段不建议新增的表

### 1. 不建议立刻建 `guest_users`

原因：

- 复杂度上升明显
- 当前仍在起步期
- 前端本地 guest follow 足够支持第一阶段产品验证

### 2. 不建议立刻建 `plans / subscriptions / billing_accounts`

原因：

- 现在只有 3 档规则：`guest / free / pro`
- 第一阶段完全可以用简单字段扛住
- 真接支付后再拆正式订阅体系

## 四、推荐的字段设计

### `users.account_tier`

建议类型：

- 字符串枚举

建议值：

- `free`
- `pro`

说明：

- `guest` 不建议存到 `users`
- `guest` 是未登录态，不是正式用户记录

### `users.follow_limit_override`

建议类型：

- 整数，可空

用途：

- 运营特殊账号
- 内部测试账号
- 临时补偿

规则：

- 有 override 就优先用
- 没有 override 就按 `account_tier`

## 五、后端计算规则建议

后端统一有一个函数：

```text
resolve_follow_limit(user):
  if user is null:
    return 5
  if user.follow_limit_override is not null:
    return user.follow_limit_override
  if user.account_tier == 'pro':
    return 50
  return 10
```

以后不管是：

- 关注
- 游客合并
- 展示剩余额度

都走这一条。

## 六、游客合并不入库的第一阶段方案

第一阶段建议流程：

1. 游客本地保存 `guestFollowTopicIds`
2. 用户登录
3. 前端调用 `POST /users/merge-guest-follows`
4. 后端读取当前账号已有关注
5. 去重 + 按上限合并
6. 返回：
   - 成功合并哪些
   - 跳过哪些
   - 当前总关注数
   - 当前上限

这个方案下，数据库不需要 guest follow 表。

## 七、如果以后要升级到正式 guest 体系

未来如果想支持：

- 游客换设备不丢
- 游客未登录也能跨会话保存
- 游客后续更强合并能力

再进入第二阶段，新增：

### `guest_sessions`

- `id`
- `guest_key`
- `device_id`
- `created_at`
- `last_seen_at`

### `guest_topic_follows`

- `id`
- `guest_session_id`
- `topic_id`
- `followed_at`

### `guest_merge_records`

- `id`
- `guest_session_id`
- `user_id`
- `merged_at`
- `merged_topic_ids_json`

这是第二阶段，不是现在。

## 八、数据库约束建议

### `user_topic_follows`

继续保持唯一约束：

- `(user_id, topic_id)` 唯一

这是必须的，保证不会重复关注。

### `guest_follow_merge_logs`

如果加这张表：

- 不需要太强约束
- 主要用于留痕

## 九、迁移顺序建议

1. 给 `users` 加：
   - `account_tier`
   - `follow_limit_override`
2. 后端实现 `resolve_follow_limit()`
3. 后端实现 `GET /users/capabilities`
4. 后端实现 `POST /users/merge-guest-follows`
5. 后面再考虑 `guest_follow_merge_logs`

## 十、一句话版本

数据库第一阶段只需要给 `users` 补“套餐层级 + 上限覆盖”字段，正式关注继续只存 `user_topic_follows`；游客关注不进库，登录后由后端合并。
