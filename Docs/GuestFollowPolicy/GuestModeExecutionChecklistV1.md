# 游客模式落地执行清单 v1

本文用于把“游客可先浏览、可先关注、登录后再合并到账号”的产品方向，拆成前端、后端和联调三部分的执行清单。

## 一、目标

本阶段只完成这条闭环：

1. 新用户首次打开 App，不再强制先登录
2. 游客可先浏览推荐、时间轴、搜索、分享查看
3. 游客可先关注，但最多 `5` 个
4. 登录免费用户最多关注 `10` 个
5. 付费用户最多关注 `50` 个
6. 游客登录后，前端把本地 guest follows 合并到正式账号

## 二、本阶段不做

- 不做支付订阅系统
- 不做服务端 guest 用户体系
- 不做阶段 7 的服务端“新建时间线”全链路
- 不改大视觉和大 widget 结构
- 不扩新的推荐模型

## 三、前端执行清单

### 1. 启动流

- 新用户首次打开 App，直接进入 `HomeShell`
- 默认落到“推荐”页
- `RegistrationGateScreen` 从“启动必经页”改成“按需触发页”

### 2. 游客浏览能力

- 游客可正常浏览：
  - 推荐页
  - 时间轴页
  - 时间轴搜索
  - 分享查看
- 游客不要求先拿正式账号才能阅读内容

### 3. 游客关注本地暂存

- 本地保存 `guestFollowTopicIds`
- 游客点击“关注”时：
  - 未达 `5` 个：本地写入
  - 已达 `5` 个：弹登录引导
- 本地 guest follow 不进入正式“服务端已关注”状态

### 4. 额度提示

- 游客：提示“最多关注 5 个，登录后可关注 10 个”
- 免费用户：提示“最多关注 10 个，升级后可关注 50 个”
- 付费用户：提示“已达到当前套餐上限”

### 5. 登录后自动合并

- 登录成功后，如果本地存在 `guestFollowTopicIds`
- 自动调用 `POST /users/merge-guest-follows`
- 成功后刷新 `GET /topics/followed`
- 再清空本地 guest 数据

### 6. 前端完成标志

- 游客不登录也能进入推荐页和时间轴
- 游客本地关注上限为 `5`
- 登录后会自动触发 merge
- merge 后“我的关注”能显示正式账号关注结果

## 四、后端执行清单

### 1. 关注额度规则

- 匿名：`5`
- `free`：`10`
- `pro`：`50`
- 有 `follow_limit_override` 时优先使用 override

### 2. 能力接口

实现并稳定：

- `GET /users/capabilities`

要求：

- 匿名返回 `guest`
- 已登录返回 `free / pro`
- 返回：
  - `accountTier`
  - `followLimit`
  - `followCount`
  - `remainingFollowQuota`

### 3. 正式关注上限校验

在以下接口内执行正式限额校验：

- `POST /topics/{topicId}/follow`

返回规则：

- 成功时返回最新 `capabilities`
- 免费用户超限时返回：
  - `UPGRADE_REQUIRED_FOR_MORE_FOLLOWS`
- 其他超限时返回：
  - `FOLLOW_LIMIT_REACHED`

### 4. 游客关注合并接口

实现并稳定：

- `POST /users/merge-guest-follows`

合并规则：

1. 先保留账号原有关注
2. 再按 `guestTopicIds` 顺序尝试合并
3. 已有的不重复写入
4. 达到上限后剩余记入 `skippedTopicIds`

### 5. 后端完成标志

- `GET /users/capabilities` 在匿名/登录态都可正常返回
- `follow` 已做正式限额校验
- `merge-guest-follows` 已能返回：
  - `mergedTopicIds`
  - `alreadyFollowedTopicIds`
  - `skippedTopicIds`
  - `followCount`
  - `followLimit`
  - `remainingFollowQuota`

## 五、联调顺序

按以下顺序，不要乱跳：

1. 游客启动进入推荐页
2. 游客浏览推荐和时间轴
3. 游客关注 1-5 个专题
4. 游客第 6 个专题触发登录引导
5. 登录成功
6. 自动调用 `merge-guest-follows`
7. 刷新“我的关注”
8. 再验证正式账号 follow limit

## 六、联调只记录的问题类型

- `capabilities` 字段缺失或空值不一致
- guest/local follow 与正式 follow 状态流不一致
- merge 结果和前端本地 guest 列表不一致
- follow quota 提示与后端错误码不一致
- 登录后没有自动 merge 或 merge 后未刷新

## 七、建议执行顺序

### 前端先做

1. 启动流改成游客直达推荐页
2. 游客浏览开放
3. 游客本地关注和上限提示

### 后端并行做

1. `GET /users/capabilities`
2. `POST /users/merge-guest-follows`
3. follow 上限校验

### 最后一起联调

1. 游客本地关注
2. 登录后 merge
3. 正式关注上限

## 八、当前阶段的结论

当前最优先的不是阶段 7，而是先把“游客模式 + 关注额度 + 登录后合并”这条链路做完整。

只有这条链路稳定后，再进入“新建时间线”的服务端创建链路，返工风险才最低。
