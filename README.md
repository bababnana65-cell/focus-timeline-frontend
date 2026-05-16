# 事件时间轴 Flutter MVP

当前目录现在以 `Flutter` 方案为主，适合你在 `Windows 11` 上继续开发。此前生成的原生 iOS 原型仍然保留在 [EventTimelineApp](/C:/Codex/Test/Timelinesss/EventTimelineApp)，作为需求和交互参考，不影响 Flutter 版本继续推进。

## 当前实现

- 竖向时间轴展示事件发展进度
- 默认按天分组，最近 24 小时按小时展示
- 45 天前自动按月归档
- 日期后显示梗概和事件数量
- 重大事件节点高亮
- 点击展开细节，再次点击显示全文
- 注册后支持多个关注事件
- 热门事件推荐
- 手动刷新
- 升序 / 降序排列
- 默认正序，最近事件在底部

## 主要文件

- [pubspec.yaml](/C:/Codex/Test/Timelinesss/pubspec.yaml)
  Flutter 依赖配置
- [lib/main.dart](/C:/Codex/Test/Timelinesss/lib/main.dart)
  应用入口
- [lib/app.dart](/C:/Codex/Test/Timelinesss/lib/app.dart)
  应用根部与导航壳
- [lib/services/timeline_controller.dart](/C:/Codex/Test/Timelinesss/lib/services/timeline_controller.dart)
  状态管理、排序、归档、关注逻辑
- [lib/services/mock_timeline_repository.dart](/C:/Codex/Test/Timelinesss/lib/services/mock_timeline_repository.dart)
  Mock 数据源
- [lib/screens/timeline_screen.dart](/C:/Codex/Test/Timelinesss/lib/screens/timeline_screen.dart)
  时间轴页面
- [lib/widgets/timeline_bucket_card.dart](/C:/Codex/Test/Timelinesss/lib/widgets/timeline_bucket_card.dart)
  节点卡片、展开细节、全文弹层
- [Docs/FlutterSetup.md](/C:/Codex/Test/Timelinesss/Docs/FlutterSetup.md)
  Windows 安装与启动说明

## Windows 现在需要安装的软件

最少安装这几个：

1. `Git for Windows`
2. `Flutter SDK`
3. `Android Studio`
4. `VS Code`
5. `VS Code` 插件：
   `Flutter`
   `Dart`

如果你想在 Windows 上顺手跑桌面版调试，再补：

1. `Visual Studio 2022 Community`
2. 安装工作负载：
   `Desktop development with C++`

## 安装后怎么启动

安装完 `Flutter SDK` 后，在当前目录执行：

```powershell
flutter doctor
flutter create .
flutter pub get
flutter run -d chrome
```

如果你要跑 Android 模拟器：

```powershell
flutter run -d android
```

如果你要跑 Windows 桌面版：

```powershell
flutter config --enable-windows-desktop
flutter run -d windows
```

## 重要说明

虽然现在已经改成 `Flutter`，你可以在 `Windows` 上完成大部分开发工作，但如果最终要打包 `iOS` 安装包，仍然必须在 `macOS + Xcode` 环境下完成。

## 下一步建议

1. 先按 [Docs/FlutterSetup.md](/C:/Codex/Test/Timelinesss/Docs/FlutterSetup.md) 把 Windows 开发环境补齐
2. 安装完后执行 `flutter create .`
3. 运行项目确认界面无误
4. 然后我继续帮你补：
   登录注册真页面
   后端 API 接口
   本地持久化
   推送提醒和事件搜索
