# 真实手机推送通道接入草案 v1

本草案用于定义“关注专题更新手机推送”的**真实推送通道接入**阶段。目标是把当前已完成的：

- 设备 token 注册
- 设备 token disable
- 手动 test-notification（模拟发送）

推进到：

- 真机能够收到系统推送
- 点击推送后能直接进入对应专题

## 1. 当前阶段目标

当前要解决的不是自动推送策略，而是先把真实推送通道本身打通：

1. 后端能调用真实推送 provider
2. 前端能拿到真实 provider token
3. 设备能收到系统推送
4. 点击推送能直达 topic detail / timeline

## 2. 当前范围

本阶段只做：

- 真实 provider 接入
- 真实 token 上报
- 手动 test-notification 通过真实 provider 发送
- 点击通知直达专题

本阶段不做：

- 关注专题自动推送触发
- 通知中心
- 推送设置页
- 复杂去重 / 节流
- 多种推送策略并行

## 3. Provider 建议

建议按平台分别接：

- Android：FCM
- iOS：APNs

如果前端当前统一使用一个聚合推送 SDK，也可以先按 SDK 的 provider 方案接入，但后端仍要保留统一抽象。

## 4. 后端最小实现建议

### 4.1 Provider 抽象

建议后端新增统一发送接口：

- `send_push_to_device(...)`

最小输入：

- `platform`
- `push_token`
- `title`
- `body`
- `data`

其中 `data` 至少包含：

- `type = topic_update`
- `topicId`

### 4.2 test-notification 升级

保留现有：

- `POST /users/push-devices/test-notification`

但把实现从：

- 模拟返回

升级成：

- 真实发送

### 4.3 发送结果

后端最小返回可继续保留：

- `sentCount`
- `devices`
- `generatedAt`

同时可增加：

- `provider = fcm / apns`
- `simulated = false`

## 5. 前端最小实现建议

### 5.1 真实 token 获取

前端需要：

- 请求系统通知权限
- 从真实 provider 获取 token
- 继续上报到：
  - `POST /users/push-devices`

### 5.2 点击推送后的行为

用户点击通知后：

1. 解析 payload
2. 读取 `topicId`
3. 直接打开对应专题

当前不要增加：

- 中间页
- 通知中心列表
- 复杂分流

## 6. 最小 payload 语义

建议真实推送 payload 延续当前测试语义：

```json
{
  "type": "topic_update",
  "topicId": "topic_123",
  "title": "你关注的专题有新动态",
  "body": "美伊战争总体进展出现新的关键节点。"
}
```

## 7. 最小联调检查项

本阶段只验证：

1. 真机能收到通知
2. 标题 / 正文显示正确
3. 点击通知后能直接进入对应专题
4. 进入后 detail / timeline 可正常读取

## 8. 当前不阻塞的内容

以下内容继续后置：

- 自动推送触发规则
- 重大节点筛选
- 置顶专题优先推送
- 推送去重 / 节流
- 推送设置页
- 通知中心

## 9. 一句话结论

当前先把 **模拟 test-notification 升级成真实手机系统推送**，先打通“能发、能收、能跳转”的真实闭环，再进入自动触发与策略细化。
