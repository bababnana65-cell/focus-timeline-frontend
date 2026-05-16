# 真实后端接入与联调清单

本文只服务于阶段 4/5/6 已收口后的下一步工作：

1. 把前端运行时 remote service 从 Mock 切到真实 HTTP 后端  
2. 在真实后端环境下做一轮端到端联调  
3. 只记录契约问题、空值问题、状态流问题  

不在本阶段：
- 扩新模型
- 改视觉
- 重写 widget
- 进入阶段 7

## 1. 当前运行时入口

前端运行时 remote service 已统一收敛到：

- `lib/services/remote/app_remote_services.dart`
- `lib/services/remote/runtime_backend_config.dart`

当前默认行为：
- 未配置真实后端时，运行时继续注入 `Mock*RemoteService`
- 配置真实后端后，运行时切换到 `Http*RemoteService`

## 2. 启用真实后端的方法

当前通过 Dart define 控制：

- `TIMELINESS_USE_HTTP_BACKEND=true`
- `TIMELINESS_API_BASE_URL=http://<your-backend-base-url>`

示例：

```powershell
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' run -d windows --dart-define=TIMELINESS_USE_HTTP_BACKEND=true --dart-define=TIMELINESS_API_BASE_URL=http://127.0.0.1:8000
```

说明：
- `TIMELINESS_USE_HTTP_BACKEND=true` 但 `TIMELINESS_API_BASE_URL` 为空时，不会切换到真实后端
- base URL 应指向后端 API 根地址，例如 `http://127.0.0.1:8000`

## 3. 真实后端接入前置条件

后端环境就绪前，需要确认：

1. `Auth DTO` 已可用
2. `Followed Topic DTO` 已可用
3. `Topic Timeline DTO` 已可用
4. `Recommendation DTO` 已可用
5. `Share DTO` 已可用
6. 返回结构仍遵循统一壳层：
   - 成功：`{ "success": true, "data": {...} }`
   - 失败：`{ "success": false, "error": {...} }`

## 4. 本轮联调重点链路

### 4.1 登录 -> 我的关注

检查项：
- 发送验证码是否成功
- 登录后 session 是否恢复
- 登录后是否进入“我的关注”
- 关注列表是否来自真实后端
- 置顶 / 取消关注是否能正确回写

记录问题类型：
- 契约字段不一致
- 空值导致 UI 失败
- 状态恢复错误

### 4.2 打开时间轴

检查项：
- 进入时间轴后是否拉到真实后端 `topic + stats + filters + entries + page`
- `TimelineEntry.id` 是否稳定映射自 `topicEventLinkId`
- 重大节点筛选是否正常
- 分桶是否正常

记录问题类型：
- 缺字段
- bucket 语义不一致
- `topicEventLinkId` 不稳定

### 4.3 搜索时间轴

检查项：
- `GET /topics/{topicId}/timeline/search`
- 搜索结果是否覆盖当前页面
- 搜索后仍保持 `topicEventLinkId` 映射

记录问题类型：
- 搜索结果字段缺失
- 搜索排序异常
- 搜索状态覆盖异常

### 4.4 分享创建 / 分享解析 / 关注并查看

检查项：
- 分享创建是否走服务端 token
- 分享链接解析是否走服务端 resolve
- “仅查看 / 关注并查看”交互是否正常
- `allowFollow` / `expiresAt` 是否按契约工作

记录问题类型：
- token 无法解析
- preview 字段缺失
- 关注并查看状态未回写

### 4.5 推荐页

检查项：
- `/recommendations` 是否返回：
  - `personalized`
  - `hot`
  - `explore`
  - `history`
- controller 是否仍能投影成当前页面模式
- 前端不再本地生成 hot/random

记录问题类型：
- section 缺失
- section 顺序错误
- history 空值/时间值异常

## 5. 联调时允许的兼容保留

以下兼容逻辑可暂时保留：

- `custom/shared` 时间线继续保留本地时间线来源
- 推荐页搜索继续基于本地 `searchableRecommendationTopics`
- `custom/shared` 历史继续本地补位

但以下逻辑不允许继续扩展：

- 服务端专题时间轴回退到本地 repository 作为事实源
- 服务端专题分享创建失败时回退本地 payload
- 前端重新本地生成 hot/random 推荐列表

## 6. 联调输出要求

真实后端联调时，只记录这 3 类问题：

1. 契约问题
- 字段名不一致
- 字段类型不一致
- 必填字段缺失

2. 空值问题
- 字段为 null 但前端未兜底
- 空数组 / 空对象影响状态流

3. 状态流问题
- 登录后状态恢复异常
- follow / unfollow / pin / unpin 未回写
- 分享 follow-and-open 未闭环
- recommendation mode 投影异常

不在本轮记录：
- 视觉问题
- 交互动效问题
- 新功能需求

## 7. 本轮结束标准

满足以下条件即可视为“真实后端接入入口已准备完成”：

1. 前端运行时可以通过配置切到真实后端
2. 页面层不需要修改 widget 即可开始联调
3. 联调清单已经固定
4. 阶段 7 仍保持后置
