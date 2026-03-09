# tim_push

`tim_push` 是一个独立的 Flutter 推送插件，用于集成 Tencent Cloud TIMPush，支持 `Android / iOS / OpenHarmony (OHOS)`。

目标是提供与 `tencent_cloud_chat_push` 接近的调用体验，并补齐 `Flutter 3.27.5-ohos-1.0.0` 下的 OHOS 能力适配。

## 参考资料

- HarmonyOS 客户端 API: https://cloud.tencent.com/document/product/269/122608
- Flutter 接入文档: https://cloud.tencent.com/document/product/269/109906
- 推送服务说明: https://cloud.tencent.com/document/product/269/101962
- 官方 Flutter 插件: https://pub.dev/packages/tencent_cloud_chat_push

## 当前内置 SDK 版本

- Android TIMPush: `8.8.7357`
- iOS TIMPush: `8.8.7357`
- OHOS TIMPush/IMSDK: `8.7.7203`

## 安装

```yaml
dependencies:
  tim_push: ^latest
```

## 核心 API

- `TimPush().registerPush(...)`
- `TimPush().unRegisterPush()`
- `TimPush().setRegistrationID(...)`
- `TimPush().getRegistrationID()`
- `TimPush().addPushListener(...)`
- `TimPush().removePushListener(...)`
- `TimPush().disablePostNotificationInForeground(...)`
- `TimPush().forceUseFCMPushChannel(...)`（仅 Android）

## 基本使用

```dart
import 'package:tim_push/tim_push.dart';

final TimPush push = TimPush();

await push.registerPush(
  sdkAppId: 0,
  appKey: '',
);
```

## Android 配置要点

- 在应用侧创建并使用自定义 `Application`（继承 `TimPushApplication`）。
- 在 AndroidManifest 里声明该 `Application`。
- 按腾讯云文档补充厂商推送依赖和配置文件（如 `timpush-configs.json`）。

## iOS 配置要点

- 在 `AppDelegate.swift` 引入 `TIMPush` 与 `tim_push`。
- 让 `AppDelegate` 实现 `TIMPushDelegate`，并实现证书 ID、通知点击回调桥接。
- 按腾讯云文档配置 APNs 证书和控制台证书 ID。

## OHOS 配置要点

- 本插件在 `ohos/oh-package.json5` 中集成 `@tencentcloud/timpush` 与 `@tencentcloud/imsdk`。
- 在 Flutter 侧调用 `registerPush` / `addPushListener` 即可桥接 `TIMPushManager` 能力。
- 推荐在应用启动早期注册监听器（例如 `UIAbility.onCreate` 对应时机）。
