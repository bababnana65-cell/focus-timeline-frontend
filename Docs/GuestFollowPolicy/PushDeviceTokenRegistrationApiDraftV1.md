# 推送设备 Token 注册接口草案 v1

## 一、目标

为“关注专题更新手机推送”提供第一步能力：

- 前端申请通知权限
- 获取设备推送 token
- 上报给后端保存

当前先不做自动推送策略、通知中心或设置页，只先打通：

- token 注册
- token 更新
- token 关闭

---

## 二、当前范围

### 当前要做

1. 注册设备推送 token
2. 更新设备推送 token
3. 关闭当前设备的推送接收

### 当前不做

- 推送中心
- 多设备推送偏好管理 UI
- 静默时段
- 分类通知
- 复杂平台差异抽象

---

## 三、后端接口建议

### 1. `POST /users/push-devices`

用途：

- 登录用户注册当前设备的推送 token
- 若同设备已存在记录，则更新 token

鉴权：

- 必须登录

请求头：

- `Authorization: Bearer <token>`

请求体示例：

```json
{
  "deviceId": "ios-abc-123",
  "platform": "ios",
  "pushToken": "example-device-token",
  "appVersion": "1.0.0",
  "enabled": true
}
```

字段建议：

- `deviceId`
- `platform`
- `pushToken`
- `appVersion`
- `enabled`

响应示例：

```json
{
  "success": true,
  "data": {
    "deviceId": "ios-abc-123",
    "platform": "ios",
    "enabled": true,
    "updatedAt": "2026-04-22T10:00:00Z"
  }
}
```

---

### 2. `POST /users/push-devices/disable`

用途：

- 关闭当前设备的推送接收

鉴权：

- 必须登录

请求体示例：

```json
{
  "deviceId": "ios-abc-123"
}
```

响应示例：

```json
{
  "success": true,
  "data": {
    "deviceId": "ios-abc-123",
    "enabled": false,
    "updatedAt": "2026-04-22T10:05:00Z"
  }
}
```

---

## 四、后端最小数据模型建议

建议新增一张表，例如：

- `user_push_devices`

最小字段：

- `id`
- `user_id`
- `device_id`
- `platform`
- `push_token`
- `app_version`
- `enabled`
- `last_seen_at`
- `created_at`
- `updated_at`

唯一约束建议：

- `(user_id, device_id)` 唯一

这样同一账号同一设备可更新 token，而不是重复插入。

---

## 五、前端最小分工

### 1. 请求通知权限

前端在合适时机请求：

- 系统通知权限

### 2. 获取设备 token

前端拿到：

- `deviceId`
- `platform`
- `pushToken`

### 3. 上报后端

前端调用：

- `POST /users/push-devices`

### 4. 关闭推送

若用户关闭通知或系统 token 失效：

- 调 `POST /users/push-devices/disable`

---

## 六、最小后端规则

### 1. 必须登录

设备 token 先只和登录用户绑定。

当前不做：

- guest 推送 token
- 匿名设备推送

### 2. 同设备重复注册视为更新

如果同一 `userId + deviceId` 已存在：

- 更新 `pushToken`
- 更新 `appVersion`
- 更新 `enabled`
- 更新 `last_seen_at`

### 3. 当前只做保存，不立刻触发自动推送

这一步只负责：

- 让后端知道应该往哪台设备推送

自动推送规则后续再接。

---

## 七、错误语义建议

建议至少预留：

- `PUSH_DEVICE_INVALID`
- `PUSH_DEVICE_NOT_FOUND`
- `PUSH_PLATFORM_UNSUPPORTED`

但第一版可以先只用通用 400/404 语义，不一定一开始就补完整错误码表。

---

## 八、联调最小验证点

### 前端联调

1. 请求通知权限
2. 获取 token
3. 调 `POST /users/push-devices`
4. 返回成功

### 后端联调

1. 同一设备首次注册成功
2. 同一设备再次注册走更新
3. disable 后 `enabled = false`

---

## 九、与后续推送能力的关系

这份草案只是推送能力的第一步。

后续完整链路会在此基础上再补：

1. 自动触发规则
2. 去重/节流
3. 点击推送直达专题

---

## 一句话结论

当前先做登录用户的设备推送 token 注册与关闭接口，不直接上完整推送闭环。
