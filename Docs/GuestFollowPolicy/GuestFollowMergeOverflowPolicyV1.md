# 游客关注合并遇到账号满额的处理规则 v1

## 一、问题场景

用户可能出现以下流程：

1. 登录账号后已经关注 10 个专题
2. 退出登录
3. 以游客身份继续关注或创建 5 个专题
4. 再次登录同一个账号

此时不能把游客 5 个专题直接合并进账号，否则免费用户 10 个关注上限会被绕过。

## 二、核心结论

账号满额时：

- 不突破 follow quota
- 不把账号关注数从 10 变成 15
- 不直接丢弃游客阶段选择
- 因额度不足未合并的游客专题应保留为待合并

用户后续取消部分关注，腾出额度后，可以再次合并这些待合并专题。

## 三、后端 merge 规则

接口：

```http
POST /users/merge-guest-follows
```

后端按当前账号 follow quota 执行合并：

- 可合并：进入 `mergedTopicIds`
- 已关注：进入 `alreadyFollowedTopicIds`
- 无法合并：进入 `skippedTopicIds`

当前已新增 `skippedTopics` 明细：

```json
{
  "topicId": "...",
  "reason": "FOLLOW_LIMIT_REACHED"
}
```

当账号已满额时，相关游客专题必须返回：

```text
reason = FOLLOW_LIMIT_REACHED
```

## 四、前端保留规则

前端登录后执行 merge 时：

- 清掉已合并的 `mergedTopicIds`
- 清掉已存在的 `alreadyFollowedTopicIds`
- 保留 `skippedTopics.reason == FOLLOW_LIMIT_REACHED` 的 topicId

这样用户取消账号内部分关注后，仍可继续重试 merge。

前端不应在存在额度不足 skipped 项时直接清空所有游客关注缓存。

## 五、ownership claim 规则

`POST /users/claim-guest-topics` 也必须防止绕过 follow quota。

如果 claim 需要同时补 follow，而当前账号已满额：

- 不 claim
- 不补 follow
- 返回 skipped：

```json
{
  "topicId": "...",
  "reason": "FOLLOW_LIMIT_REACHED"
}
```

这样可以避免通过 claim 链路把账号关注数从 10 推到 11 或更多。

## 六、用户体验建议

当登录后有游客专题因为额度不足未同步时，前端可提示：

```text
账号关注已满，部分游客关注暂未同步。取消一些关注后可继续同步。
```

当前版本不要求新增复杂“待同步列表”页面；先保留本地待合并 topicId 即可。

## 七、当前不做的范围

当前 v1 不做：

- 突破免费关注上限
- 自动替换账号已有关注
- 自动取消旧关注
- 待同步专题管理页
- 复杂冲突解决 UI

如需产品化“待同步列表”，另开 v2。
