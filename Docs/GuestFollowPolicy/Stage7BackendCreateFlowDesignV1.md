# 阶段 7 后端创建链路设计草案 v1

本文用于定义“新建时间线 / 新建专题”在阶段 7 服务端化时的后端设计基线。

目标：

- 把当前前端本地 `custom-*` 草稿语义替换成服务端正式 `Topic`
- 支持游客创建专题
- 支持登录后合并关注关系
- 为后续 ownership 认领、AI 初始化、服务端更新留下正确扩展位

---

## 一、阶段 7 的核心目标

阶段 7 的后端目标不是“优化本地草稿”，而是把创建链路改成：

1. 前端提交专题定义
2. 服务端正式创建 `Topic`
3. 服务端返回正式 `topicId`
4. 创建链路如隐含自动关注，先经过 follow quota
5. 前端后续围绕正式 `topicId` 展示与缓存

这意味着：

- 现有 `custom-*` 本地 ID 不再作为长期事实源
- `seedEntries` 不再作为正式时间线事实
- 登录后 merge 的对象是关系，而不是本地草稿上传

---

## 二、创建链路的服务端语义

### 1. 创建对象

创建链路的核心对象是：

- `Topic`
- 可选的 `TopicDefinition`
- 可选的初始 AI 初始化任务

### 2. 创建完成后返回

第一阶段不要求同步生成完整时间线。

所以服务端创建后应返回：

- 正式 `topicId`
- 基本摘要信息
- 当前状态
- 是否已关注
- 当前额度状态

前端后续再用正式接口拉详情和时间线。

---

## 三、建议接口

建议新增或重构为统一接口：

### `POST /topics/create`

作用：

- 支持登录用户创建专题
- 后续扩展支持游客创建专题

请求示例：

```json
{
  "title": "低空经济试点",
  "summary": "关注试点城市、航线开放与商业化进度",
  "definition": {
    "coreKeywords": ["低空经济", "试点城市"],
    "extendedKeywords": ["航线开放", "商业化", "空域改革"],
    "excludedKeywords": ["无关评论"]
  },
  "autoFollow": true
}
```

响应示例：

```json
{
  "success": true,
  "data": {
    "topic": {
      "topicId": "topic_001",
      "title": "低空经济试点",
      "summary": "关注试点城市、航线开放与商业化进度",
      "status": "pending",
      "kind": "user_created",
      "visibility": "private"
    },
    "followed": true,
    "capabilities": {
      "authenticated": true,
      "accountTier": "free",
      "followLimit": 10,
      "followCount": 4,
      "remainingFollowQuota": 6
    }
  }
}
```

---

## 四、请求字段建议

### 必填

- `title`
- `summary`
- `definition.coreKeywords`

### 可选

- `definition.extendedKeywords`
- `definition.excludedKeywords`
- `autoFollow`
- 后续可扩展：
  - `startDate`
  - `guestCreateKey`
  - `seedHints`

### 规则

- `autoFollow` 默认建议为 `true`
- 只要 `autoFollow = true`，就必须先过 follow quota

---

## 五、响应字段建议

建议最小返回：

### `topic`

- `topicId`
- `title`
- `summary`
- `status`
- `kind`
- `visibility`

### 顶层

- `followed`
- `capabilities`

必要时可扩展：

- `initializationState`
- `queuedJobId`
- `ownerMode`

---

## 六、状态语义建议

创建成功后，不要求时间线立即完整。

建议引入最小状态：

- `draft`
- `pending`
- `active`

建议含义：

### `draft`
- 仅创建了基础记录
- 初始化尚未开始

### `pending`
- 已触发 AI / 检索 / 初始化任务
- 时间线可能暂时为空或不完整

### `active`
- 已具备基础可读时间线

前端应接受：

- 创建成功后先进入一个 `pending` 专题
- 再通过正式时间轴接口刷新

---

## 七、游客创建的特殊约束

### 1. 游客创建者标识

阶段 7 必须引入 guest create identity 概念。

第一阶段建议至少支持一个可扩展字段：

- `guest_create_key`

这个 key 不等于完整 guest 用户体系，但至少可以回答：

- 这个专题由哪个游客会话创建
- 登录后哪个账号可认领

### 2. 登录后 ownership 认领

对于游客创建的 `user_created topic`：

- 登录后不能只 merge follow
- 还要支持 ownership claim

建议默认规则：

- 登录时发现该 `guest_create_key` 与当前会话匹配
- 则把 topic owner 认领到当前用户

### 3. 游客创建单独限流

游客创建不能只看 follow quota。

建议单独加 create rate limit，例如：

- 每 guest session / 每设备 / 每 IP
- 每日 1~3 次

### 4. 默认不进公开推荐池

游客创建专题建议默认：

- `kind = user_created`
- `visibility = private`
- `status = draft` 或 `pending`
- 默认不进入公开推荐池

---

## 八、follow quota 规则

这条链路继续严格遵守当前正式规则：

- 游客：5
- 免费：10
- 付费：50
- `follow_limit_override` 优先

如果创建链路隐含自动关注：

1. 先计算当前 follow limit
2. 若超限，整条创建链路失败
3. 返回现有错误语义

不允许：

- 创建成功但未关注
- 创建成功但要求前端补 follow

---

## 九、错误语义

阶段 7 继续复用已有额度错误语义：

- `FOLLOW_LIMIT_REACHED`
- `UPGRADE_REQUIRED_FOR_MORE_FOLLOWS`

另外建议补创建链路相关错误：

- `TOPIC_CREATE_RATE_LIMITED`
- `TOPIC_DEFINITION_INVALID`
- `GUEST_CREATE_CLAIM_MISMATCH`
- `TOPIC_INITIALIZATION_FAILED`

但不建议新开“创建成功但未关注”类状态错误。

---

## 十、seedEntries 的处理原则

当前前端草稿里的 `seedEntries` 或同类初始节点提示，只能作为：

- 创建请求的辅助材料
- AI 初始化的 hint

不能继续作为：

- 正式时间线事实源
- 本地长期缓存的真相数据

正式事实应以后端生成/整理/返回为准。

---

## 十一、推荐的后端落地顺序

建议按这个顺序推进：

1. 设计并冻结 `POST /topics/create` 的请求/响应 DTO
2. 为 `Topic` 预留 guest create identity 字段或关联表
3. 在创建链路中加入 follow quota 校验
4. 返回最小 `topic + followed + capabilities + status`
5. 后续再补：
   - ownership claim
   - create rate limit
   - initialization job
   - pending -> active 状态流

---

## 十二、与当前实现的关系

当前后端已对齐的只有一部分：

- 创建链路不能绕过 follow quota
- 额度错误语义已存在

当前仍未实现的阶段 7 能力：

- guest create 入口
- guest create identity
- ownership claim
- create rate limit
- 正式 create response DTO
- initialization status lifecycle

因此这份文档是：

**阶段 7 后端设计基线，不代表当前已经全部实现。**

---

## 十三、一句话版本

**阶段 7 的后端创建链路应把“新建时间线”改成正式服务端 Topic 创建，返回正式 `topicId` 和最小状态信息；若隐含自动关注，则必须先过 follow quota，并为游客创建标识、ownership 认领和初始化状态留出扩展位。**
