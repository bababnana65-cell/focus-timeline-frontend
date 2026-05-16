# 阶段 7C：服务端专题初始化后端最小实现规划清单 v1

本文用于把“阶段 7C 初始化链路设计草案”推进成可执行的后端最小实现清单。

目标：

- 不扩大范围
- 不一口气做完整任务平台
- 先把“创建后初始化 -> 进入可读状态”的最小链路跑通

---

## 一、这轮实现的目标

本轮只做最小初始化能力：

1. 创建后专题进入初始化队列
2. 初始化状态可推进：
   - `pending`
   - `running`
   - `ready`
   - `failed`
3. 初始化成功后写入最小初始 timeline 内容
4. 初始化失败时前端可见

这轮不做：

- 完整任务平台
- 多级优先级调度
- 完整后台监控
- 推送系统
- 自动重试大系统

---

## 二、后端实现顺序

建议按这个顺序做。

### 1. 先补状态字段语义

当前至少要统一：

- `Topic.status`
- `topic.initializationState`

建议最小状态：

- `draft / pending`
- `draft / running`
- `active / ready`
- `draft / failed`

如果当前 `Topic.status` 枚举不想立刻扩太多，
也至少要保证：

- `status`
- `initializationState`

这两个组合能完整表达上述语义。

---

### 2. 先补最小初始化任务入口

创建成功后：

1. 写入基础 `Topic`
2. 返回创建成功响应
3. 立即触发初始化任务入口

第一版可以先是：

- 进程内后台任务
- 轻量 job runner

不要求立刻上完整队列系统。

---

### 3. 初始化任务的最小步骤

第一版建议固定这几步：

1. 将 `initializationState` 置为 `running`
2. 读取 topic definition
3. 生成最小初始 timeline entries
4. 写入初始 summary / counters / latestEventTime
5. 成功则：
   - `status = active`
   - `initializationState = ready`
6. 失败则：
   - `status = draft`
   - `initializationState = failed`

---

### 4. 最小 timeline 产出要求

第一版不追求复杂质量，但至少保证：

1. 初始化成功后，`GET /topics/{topicId}/timeline` 不再永远为空
2. `entryCount > 0`
3. `latestEventTime` 被更新
4. `topic.summary` 可按初始化结果更新或补全

如果暂时做不到高质量检索，也可以先生成：

- 最小 seed-based timeline
- 或结构化占位节点

但正式事实必须以后端写入为准。

---

## 三、失败语义

这轮必须解决“失败可见”，不要静默卡死。

### 最小要求

当初始化失败时：

1. `GET /topics/{topicId}` 能看到：
   - `status = draft`
   - `initializationState = failed`
2. `GET /topics/{topicId}/timeline` 仍可访问
3. 前端可基于状态显示：
   - `初始化失败，请稍后重试`

---

## 四、与前端的最小契约

前端这轮最终会依赖：

1. 创建响应里的 `initializationState`
2. detail / timeline 返回里的 `status + initializationState`
3. 初始化成功后 timeline 从空变为可读
4. 初始化失败后明确看到 `failed`

因此后端必须保证：

- 创建接口、detail、timeline 三处状态语义一致

---

## 五、建议的最小接口影响

这轮尽量不新增太多新接口。

优先复用：

- `POST /topics/create`
- `GET /topics/{topicId}`
- `GET /topics/{topicId}/timeline`

如果后续要加重试接口，可后置到 v2，例如：

- `POST /topics/{topicId}/retry-initialization`

但第一版不强制。

---

## 六、最小测试要求

后端至少补这 6 个点：

1. 创建后初始状态为：
   - `draft / pending`
2. 初始化任务开始后状态进入：
   - `draft / running`
3. 初始化成功后：
   - `active / ready`
   - timeline 非空
4. 初始化失败后：
   - `draft / failed`
5. detail / timeline 的状态字段一致
6. 创建响应、detail、timeline 三者状态语义一致

---

## 七、前端最小配合点

前端这轮不需要大改，只需要：

1. 继续识别：
   - `pending`
   - `running`
   - `ready`
   - `failed`
2. 不再把“空 timeline”直接理解成最终态
3. 继续把状态映射成：
   - 正在准备中
   - 初始化失败
   - 可阅读

---

## 八、当前阶段不要扩的新范围

先不要顺手做这些：

- 完整任务平台
- 后台任务监控系统
- 更大 AI workflow
- 推送提醒
- 自动重试策略平台化

第一版先把最小状态推进链路跑通。

---

## 九、完成标志

满足以下条件即可认为阶段 7C 最小实现完成：

1. 新建专题不会长期停留在 `draft / pending + 空 timeline`
2. 后端能推进到：
   - `active / ready`
   或：
   - `draft / failed`
3. 前端能明确感知：
   - 正在准备中
   - 初始化失败
   - 可正常阅读

---

## 十、一句话版本

**阶段 7C 的后端最小实现，就是在创建成功后补一条异步初始化链路，把专题从 `draft / pending` 推进到 `active / ready`，并在失败时明确落到 `draft / failed`。**
