# FCM 最小后端接入草案 v1

本草案用于定义“真实手机推送通道接入”的第一步：**后端先接入 FCM 最小发送能力**。

目标不是一次做完自动推送，而是先把：

- `POST /users/push-devices/test-notification`
- 真实 FCM 发送
- 真机收到通知
- 点击通知后直达专题

这条最小闭环打通。

## 1. 为什么先做 FCM

当前建议：

- Android 优先
- Provider 先选 FCM

原因：

- Android 真机联调通常更直接
- 前端拿 FCM token 和后端发送 payload 的对齐成本更低
- 可以先把真实推送闭环打通，再考虑 iOS / APNs

## 2. 当前范围

本阶段只做：

- 后端 FCM 最小发送能力
- `test-notification` 从模拟发送升级成真实发送
- 推送 payload 中包含 `topicId`
- 真机收到通知后可点进对应专题

本阶段不做：

- 自动推送触发
- 推送去重 / 节流
- 通知中心
- 推送设置页
- iOS / APNs 首发支持

## 3. 后端最小实现建议

### 3.1 配置项

建议新增最小配置：

- `TIMELINESS_PUSH_PROVIDER=fcm`
- `TIMELINESS_FCM_PROJECT_ID`
- `TIMELINESS_FCM_CREDENTIALS_JSON` 或服务账号文件路径

当前只要能在 local / dev 环境跑通即可。

### 3.2 发送抽象

建议后端统一抽象为：

- `send_push_to_device(...)`

最小参数：

- `platform`
- `push_token`
- `title`
- `body`
- `data`

其中 `data` 至少包含：

- `type = topic_update`
- `topicId`

### 3.3 接口复用

继续复用现有：

- `POST /users/push-devices/test-notification`

升级方式：

- 当前：`simulated = true`
- 升级后：真实走 FCM

建议返回增加：

- `provider = "fcm"`
- `simulated = false`

## 4. 最小 payload 建议

通知最小 payload 建议保持：

```json
{
  "type": "topic_update",
  "topicId": "topic_123",
  "title": "你关注的专题有新动态",
  "body": "美伊战争总体进展出现新的关键节点。"
}
```

点击通知后，前端只需要根据 `topicId` 跳转。

## 5. 前端最小配合点

前端当前只需保证：

1. 能拿到真实 FCM token
2. 用现有 `POST /users/push-devices` 上报
3. 收到通知后读取 `topicId`
4. 点击通知直达对应专题

当前不要增加：

- 中间页
- 推送设置页
- 复杂通知分类

## 6. 最小联调检查项

本阶段只验证：

1. 真机已登录
2. 真机 token 已注册成功
3. 调 `POST /users/push-devices/test-notification`
4. 真机收到系统通知
5. 点击通知后直接进入对应专题
6. 进入后 detail / timeline 可正常打开

## 7. 当前不阻塞的内容

以下内容后置：

- 自动推送触发规则
- 重大节点 / 置顶专题优先策略
- 去重 / 节流
- 通知中心
- iOS / APNs

## 8. 一句话结论

当前先做 **FCM 最小后端接入**，把 `test-notification` 从模拟发送升级成真实推送发送，先打通“能发、能收、能跳”的真机闭环。
