# 关注额度与游客合并错误码与状态流说明 v1

## 一、目标

统一以下 3 件事：

1. 游客关注的本地限制怎么提示
2. 登录后合并时，前后端怎么走
3. 超限、重复、部分成功时，错误码和页面反馈怎么统一

## 二、错误码清单

### 1. `AUTH_REQUIRED`

用途：

- 需要登录的正式接口被匿名调用

典型场景：

- 游客直接调正式 `POST /topics/{topicId}/follow`
- 游客直接调 `POST /users/merge-guest-follows`

前端处理：

- 弹登录引导
- 不显示系统错误堆栈

### 2. `TOPIC_NOT_FOUND`

用途：

- `topicId` 无效
- 专题已下线或不可访问

前端处理：

- 提示“专题不存在或已不可用”
- 如果是游客合并里的某个 topic，记入 skipped

### 3. `TOPIC_ALREADY_FOLLOWED`

用途：

- 已登录用户重复关注同一专题

前端处理：

- 直接把按钮状态修正成“已关注”
- 不当成严重错误

### 4. `TOPIC_NOT_FOLLOWED`

用途：

- 用户取消关注时，目标其实不在已关注列表里

前端处理：

- 直接把按钮状态修正成“未关注”
- 可静默处理

### 5. `FOLLOW_LIMIT_REACHED`

用途：

- 已达到当前账号可关注上限

典型场景：

- `pro` 用户已达 50 个
- 有 override 的账号已达 override 上限

前端处理：

- 提示“已达到当前套餐关注上限”

### 6. `UPGRADE_REQUIRED_FOR_MORE_FOLLOWS`

用途：

- 免费用户超过 10 个后继续关注

前端处理：

- 提示“当前最多可关注 10 个专题，升级后可关注 50 个”

### 7. `LOGIN_REQUIRED_FOR_MORE_FOLLOWS`

用途：

- 游客本地关注达到 5 个后继续关注

说明：

- 第一阶段更推荐前端本地直接拦截，不一定真由后端返回
- 但保留这个错误码更统一

前端处理：

- 提示“游客最多可关注 5 个专题，登录后可关注 10 个”

### 8. `INVALID_GUEST_TOPIC_IDS`

用途：

- `merge-guest-follows` 请求体格式不对
- `guestTopicIds` 为空、不是数组、含非法值

前端处理：

- 记录埋点
- 清理本地异常 guest 数据
- 必要时重新拉正式关注列表

### 9. `GUEST_FOLLOW_MERGE_EMPTY`

用途：

- 登录后发起合并，但本地游客关注列表为空

前端处理：

- 可静默处理
- 不必提示用户

### 10. `GUEST_FOLLOW_MERGE_PARTIAL`

用途：

- 合并不是全成功
- 有些专题因为超限、无效、重复而未并入

说明：

- 更推荐放在成功响应里通过字段表达，不一定做成 HTTP 错误
- 但业务语义上要保留这个概念

前端处理：

- 提示“已合并 X 个专题，另有 Y 个未加入”

## 三、状态流说明

## 1. 游客点击“关注”

### 前端状态流

1. 判断当前是否未登录
2. 读取本地 `guestFollowTopicIds`
3. 如果未达 5 个：
   - 本地加入该 `topicId`
   - 按钮改成“已关注”
   - 可提示“已保存，登录后可同步”
4. 如果已达 5 个：
   - 不写入
   - 弹登录引导

### 后端状态流

- 第一阶段不参与游客关注写入
- 不落库

## 2. 已登录用户点击“关注”

### 前端状态流

1. 调 `POST /topics/{topicId}/follow`
2. 成功后：
   - 更新按钮状态
   - 更新“我的关注”
   - 更新剩余额度
3. 如果返回超限：
   - 免费用户：提示升级
   - 其他用户：提示达到上限

### 后端状态流

1. 校验登录态
2. 校验专题存在
3. 校验是否已关注
4. 计算当前关注上限
5. 若未超限则写 `user_topic_follows`
6. 返回最新 `followCount / followLimit / remainingFollowQuota`

## 3. 游客登录后自动合并

### 前端状态流

1. 登录成功
2. 读取本地 `guestFollowTopicIds`
3. 如果为空：
   - 不调合并接口，或调后静默返回
4. 如果不为空：
   - 调 `POST /users/merge-guest-follows`
5. 成功后：
   - 刷新 `GET /topics/followed`
   - 清空本地 `guestFollowTopicIds`
   - 根据结果提示：
     - 全成功
     - 部分成功
     - 全跳过

### 后端状态流

1. 校验登录态
2. 读取账号已有关注
3. 按顺序处理 `guestTopicIds`
4. 产出 3 组结果：
   - `mergedTopicIds`
   - `alreadyFollowedTopicIds`
   - `skippedTopicIds`
5. 返回新的关注数与上限信息

## 四、推荐的响应语义

### 1. 正式关注成功

```json
{
  "success": true,
  "data": {
    "followed": true,
    "item": {
      "followId": "follow_001",
      "topicId": "topic_001"
    },
    "capabilities": {
      "accountTier": "free",
      "followLimit": 10,
      "followCount": 6,
      "remainingFollowQuota": 4
    }
  }
}
```

### 2. 合并全部成功

```json
{
  "success": true,
  "data": {
    "mergedTopicIds": ["topic_001", "topic_002"],
    "alreadyFollowedTopicIds": [],
    "skippedTopicIds": [],
    "followCount": 8,
    "followLimit": 10,
    "remainingFollowQuota": 2
  }
}
```

### 3. 合并部分成功

```json
{
  "success": true,
  "data": {
    "mergedTopicIds": ["topic_001"],
    "alreadyFollowedTopicIds": ["topic_002"],
    "skippedTopicIds": ["topic_003"],
    "followCount": 10,
    "followLimit": 10,
    "remainingFollowQuota": 0
  }
}
```

## 五、前端提示文案建议

### 游客超限

- `游客最多可关注 5 个专题，登录后可关注 10 个`

### 免费用户超限

- `当前最多可关注 10 个专题，升级后可关注 50 个`

### 合并全部成功

- `已将游客关注同步到你的账号`

### 合并部分成功

- `已合并 2 个专题，另有 1 个因上限未加入`

### 已重复关注

- `该专题已在你的关注列表中`

## 六、推荐的实现原则

1. 超限判断以后端为准
2. 游客 5 个上限前端先拦截，后端保留统一错误码
3. 合并接口尽量返回“结果清单”，不要只返回成功/失败
4. `TOPIC_ALREADY_FOLLOWED` 和 `TOPIC_NOT_FOLLOWED` 都应视为可恢复状态，不必做成重错误
5. 前端所有提示都尽量转成用户语言，不直接显示错误码

## 七、一句话版本

游客关注本地限 5，登录后由后端合并；正式账号关注上限和合并结果都以后端返回为准，前端负责提示和引导。
