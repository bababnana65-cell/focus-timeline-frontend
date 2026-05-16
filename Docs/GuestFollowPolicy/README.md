# 游客与专题生命周期文档索引

本目录用于保存“游客模式、专题创建、ownership claim、初始化状态与专题生命周期”相关的正式参考文档，供前端与后端开发时统一对照。

当前文档：

1. `GuestFollowQuotaAndMergePlanV1.md`
   关注额度与游客合并方案总览。

2. `GuestFollowQuotaDatabaseAdjustmentsV1.md`
   数据库表调整建议。

3. `GuestFollowQuotaApiDraftV1.md`
   后端接口清单与请求/响应草案。

4. `GuestFollowQuotaErrorAndStateFlowV1.md`
   错误码、状态流与前端提示建议。

5. `GuestModeExecutionChecklistV1.md`
   游客模式、关注额度与登录后合并的执行清单。

6. `GuestCreateTopicPolicyV1.md`
   游客创建专题的历史 v1 产品语义、后端约束与阶段 7 基线；其中“游客创建限流”已被 v2 取代。

7. `Stage7BackendCreateFlowDesignV1.md`
   阶段 7 后端创建链路的接口、状态和扩展位设计草案。

8. `LoginRegistrationAndGuestEntryConvergenceChecklistV1.md`
   登录/注册入口文案与游客入口的统一语义、触发时机和收口清单。

9. `Stage7GuestCreateIdentityAndApiDraftV1.md`
   阶段 7B 的 guest create identity、guest read access、ownership claim 与限流草案。

10. `OwnershipClaimBackendApiAndRulesDraftV1.md`
   ownership claim 的后端接口、资格校验、幂等规则与前端触发顺序草案。

11. `OwnershipClaimImplementationChecklistV1.md`
   ownership claim 的后端最小实现顺序、测试点与前端配合清单。

12. `Stage7CTopicInitializationFlowDesignV1.md`
   阶段 7C 的服务端专题初始化状态语义、最小任务链路与前端状态映射草案。

13. `Stage7CTopicInitializationImplementationChecklistV1.md`
   阶段 7C 的后端最小实现顺序、状态推进要求、测试点与前端配合清单。

14. `TopicImmutableAndUnfollowOnlyPolicyV1.md`
   专题创建后不可修改、不可删除、不可归档，用户仅可取消关注的正式规则。

15. `OwnedTopicStatusAndRetryCapabilityDraftV1.md`
   自建专题的“我的专题”、状态展示与初始化失败后重试能力草案。

16. `CurrentVersionRegressionChecklistV1.md`
   当前版本发版前与联调后的固定回归清单，覆盖已冻结主路径能力。

17. `FollowedTopicUpdateAwarenessCapabilityDraftV1.md`
   “我的关注”里关注专题更新提醒与最小未读感知能力草案。

18. `FollowedTopicUpdateNotificationAndBadgeRulesV1.md`
   关注专题更新时的列表提示、底部按钮红点与后续推送规则草案。

19. `FollowedTopicUpdatePushNotificationCapabilityDraftV1.md`
   关注专题更新手机推送的最小实现范围、触发语义、去重节流与前后端分工草案。

20. `PushDeviceTokenRegistrationApiDraftV1.md`
   手机推送第一步：登录用户设备 token 注册、更新与关闭接口草案。

21. `ManualTestPushNotificationFlowDraftV1.md`
   手机推送第二步：手动测试推送、最小 payload 语义与点击后直达专题的联调草案。

22. `RealMobilePushProviderIntegrationDraftV1.md`
   手机推送第三步：真实推送 provider 接入、真机接收与点击后直达专题的最小闭环草案。

23. `FcmMinimalBackendIntegrationDraftV1.md`
   真实手机推送第四步：FCM 最小后端接入、测试接口升级成真实发送与 Android 真机联调草案。

24. `FollowedTopicUpdateBackendRulesV1.md`
   关注专题更新提醒的后端正式规则，覆盖未读判定、已读清除、刷新聚合、minute 时间精度兼容与最小回归清单。

25. `GuestCreateTopicPolicyV2.md`
   游客创建专题的当前正式规则：取消 24 小时创建次数限制，不再返回 `TOPIC_CREATE_RATE_LIMITED`，仅受 follow quota 限制。

26. `GuestFollowMergeOverflowPolicyV1.md`
   游客关注合并遇到账号满额时的处理规则：不突破 follow quota，不丢弃因 `FOLLOW_LIMIT_REACHED` 未同步的游客专题。

27. `CurrentVersionFreezeRecordV1.md`
   当前真实 HTTP 最终回归通过后的版本冻结记录，覆盖已跑通能力、冻结规则、非范围与后续处理规则。

建议使用方式：

- 产品讨论时先读方案总览。
- 后端开发时优先参考数据库调整与接口草案。
- 前端开发时优先参考接口草案与错误码/状态流说明。
- 后续如果规则调整，新增 `v2` 文档，不直接覆盖 `v1`。
