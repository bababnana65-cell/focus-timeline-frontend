# Flutter Windows 安装说明

## 1. 建议安装的软件

### 必装

- `Git for Windows`
- `Flutter SDK`
- `Android Studio`
- `VS Code`
- `VS Code Flutter` 插件
- `VS Code Dart` 插件

### 如果要跑 Windows 桌面版

- `Visual Studio 2022 Community`
- 工作负载：`Desktop development with C++`

## 2. Flutter SDK 建议放置位置

建议解压到不带中文和空格的目录，例如：

`C:\dev\flutter`

然后把以下目录加入系统 `Path`：

`C:\dev\flutter\bin`

## 3. 检查安装

打开新的 PowerShell：

```powershell
flutter doctor
```

如果提示 Android 工具链未完整安装，打开 `Android Studio` 补全：

- `Android SDK`
- `Android SDK Platform`
- `Android SDK Command-line Tools`

## 4. 在当前项目生成 Flutter 平台目录

当前目录已经有 `lib/` 和 `pubspec.yaml`，所以安装 Flutter 后直接在项目根目录运行：

```powershell
flutter create .
flutter pub get
```

这样会补齐：

- `android/`
- `ios/`
- `windows/`
- `web/`
- 其他 Flutter 平台文件

## 5. 启动方式

### 浏览器调试

```powershell
flutter run -d chrome
```

### Android 模拟器或真机

```powershell
flutter devices
flutter run -d android
```

### Windows 桌面版

```powershell
flutter config --enable-windows-desktop
flutter run -d windows
```

## 6. iOS 说明

你现在可以在 Windows 上完成 Flutter 业务开发，但最终要生成 iOS App 仍然需要：

- `macOS`
- `Xcode`
- `CocoaPods`

## 7. 推荐工作流

1. 在 Windows 上写页面、状态逻辑、接口、数据层
2. 用 `Chrome / Android / Windows` 做日常调试
3. 到有 `Mac` 的环境后再补 iOS 打包和真机验证

