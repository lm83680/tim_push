# tim_push

`tim_push` 是一个 Flutter 推送插件，用于集成 Tencent Cloud TIMPush，支持 `Android / iOS / OpenHarmony (OHOS)`。

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
- `TimPush().clearAllNotifications()`

## 使用者教程

以下步骤按接入顺序组织，建议逐项完成。

### 1. 准备业务参数

配置位置：应用侧常量文件、环境注入层或启动配置层。推荐通过 `dart-define` 或环境变量统一注入：

```dart
final class AppOptions {
  static const int timPushAppId = int 'TIM_PUSH_APP_ID';
  static const String timPushAppKey = 'TIM_PUSH_APP_KEY';
  static const int timPushBusinessId = int'TIM_PUSH_BUSINESS_ID';
}
```

### 2. Flutter 最佳实践：

```dart
class AppPush {
  AppPush._();

  static bool _isRegistered = false;
  static String _currentRegistrationID = 'N/A';
  static String get registrationID => _currentRegistrationID;

  static Future<void> register() async {
    if (_isRegistered) return;
    AppLogger.d("开始注册离线推送服务");
    AppPermission.request(PermissionTypes.notification, PermissionApplyLevel.request).then((res) {
      AppLogger.d("通知栏通知权限是否可用：${res.isAllow}");
    });
    final TimPush timPush = TimPush();

    timPush.clearAllNotifications().then((res) {
      AppLogger.d("清除所有通知: code=${res.code}, message=${res.message}");
    });

    if (defaultTargetPlatform == TargetPlatform.android) {
      final googleAvailability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
      if (googleAvailability == GooglePlayServicesAvailability.success) {
        AppLogger.d("Google Play Services 可用，切换到 FCM 通道");
        await timPush.forceUseFCMPushChannel(enable: true);
      }
    }

    final result = await timPush.registerPush(
      sdkAppId: AppOptions.timPushAppId,
      appKey: AppOptions.timPushAppKey,
      ohosBusinessId: AppOptions.timPushBusinessId,
    );
    AppLogger.d('初始化推送服务: code=${result.code}, message=${result.message}');

    final result2 = await timPush.getRegistrationID();
    _currentRegistrationID = result2.data?.isNotEmpty == true ? result2.data! : 'Unavailable';
    AppLogger.d('获取本机推送ID: code=${result2.code}, registrationId=$_currentRegistrationID');

    final result3 = await timPush.addPushListener(
      listener: TimPushListener(
        onMessageReceived: onMessageReceived,
        onRevokePushMessage: null,
        onNotificationClicked: onNotificationClicked,
      ),
    );
    AppLogger.d('监听推送事件内容: code=${result3.code}, message=${result3.message}');
    _isRegistered = true;
  }

  /// 收到推送消息后的回调
  static void onMessageReceived(TimPushMessage message) {
    AppLogger.d('[TIMPush] onMessageReceived: id=${message.messageId}, ext=${message.ext}, raw=${message.rawData}');
  }

  /// 推送消息被点击后的回调
  static void onNotificationClicked({
    required String ext,
    String? userID,
    String? groupID,
  }) {
    AppLogger.d('[TIMPush] onNotificationClicked: ext=$ext, userID=$userID, groupID=$groupID');
  }
}
```

### 3. Android 宿主工程配置

Android 侧除了 Flutter 调用代码，还需要在宿主工程中补齐 Manifest、Gradle、厂商依赖和配置文件。

#### 3.1 配置位置：无需额外自定义 `Application`

当前版本插件通过 Android 库级 `ContentProvider` 自动完成初始化，宿主工程不需要创建 `MainApplication`，也不需要继承特定 `Application`。

如果业务工程显式修改了 manifest merge 规则，请确保不要移除插件合并进来的初始化 `provider`。

#### 3.2 配置位置：`android/app/src/main/AndroidManifest.xml`

至少补齐这些权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### 3.3 配置位置：`android/build.gradle`

如果要接入 FCM、华为、荣耀等厂商通道，宿主工程需要声明对应仓库与 Gradle 插件：

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://developer.huawei.com/repo/' }
        maven { url 'https://developer.hihonor.com/repo' }
    }
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
        classpath 'com.huawei.agconnect:agcp:1.9.5.302'
        classpath 'com.hihonor.mcs:asplugin:2.0.1.300'
    }
}
```

#### 3.4 配置位置：`android/app/build.gradle`

如需接入 FCM、华为、荣耀、Vivo、Oppo、小米、魅族等厂商通道，在这里添加对应依赖与 Gradle 插件：

```gradle
dependencies {
    implementation "com.tencent.timpush:xiaomi:8.8.7357"
    implementation "com.tencent.timpush:huawei:8.8.7357"
    implementation "com.tencent.timpush:vivo:8.8.7357"
    implementation "com.tencent.timpush:oppo:8.8.7357"
    implementation "com.tencent.timpush:meizu:8.8.7357"
    implementation "com.tencent.timpush:honor:8.8.7357"
    implementation "com.tencent.timpush:fcm:8.8.7357"
}

apply plugin: 'com.google.gms.google-services'
apply plugin: 'com.huawei.agconnect'
apply plugin: 'com.hihonor.mcs.asplugin'
```

如果你启用了 Vivo、Honor 等通道，还需要在 `defaultConfig` 中补充 `manifestPlaceholders`：

```gradle
defaultConfig {
    manifestPlaceholders += [
        "VIVO_APPKEY": "替换为你的值",
        "VIVO_APPID": "替换为你的值",
        "HONOR_APPID": "替换为你的值"
    ]
}
```

#### 3.5 配置位置：`android/app/` 与 `android/app/src/main/assets/timpush-configs.json`

将厂商平台要求的配置文件放到 `android/app/` 目录：

- `google-services.json`
- `agconnect-services.json`
- `mcs-services.json`

主配置文件：

- `timpush-configs.json` 在腾讯云下载

#### 3.6 FCM 默认通知通道

如果使用FCM，还需要在`android/app/src/main/AndroidManifest.xml`声明
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="@string/default_notification_channel_id" />
```

### 4. iOS 配置说明

宿主侧仍需要完成这些基础项：

- 开启 Push Notifications 能力。
- 动态申请通知权限（建议`permission_handler`）
- 在 Apple Developer 与腾讯云控制台配置 APNs 证书或密钥。
- 使用与 Android 相同的 Flutter 注册代码调用 `registerPush` / `addPushListener`。
- 开启 Remote notifications 后台模式 `Info.plist`。
```xml
<key>UIBackgroundModes</key>
<array>
	<string>remote-notification</string>
</array>
```
- 在 `AppDelegate` 内提供离线推送证书 ID
```diff
@main
@objc class AppDelegate: FlutterAppDelegate {
+  @objc func offlinePushCertificateID() -> Int32 {
+    #if DEBUG
+    return 0 // 开发环境证书 ID
+    #else
+    return 1 // 生产环境证书 ID
+    #endif
+  }
}
```

如果你已经按上面步骤完成，而 iOS 仍无法收推送，优先检查 APNs 证书、Bundle ID、环境（开发/生产）是否一致。
> 于我而言，ios 平台是最省事的

### 5. OHOS 配置说明

- 鸿蒙侧 `ohosBusinessId` 从 `registerPush` 函数中传递
- 其余无
