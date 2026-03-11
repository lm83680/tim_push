import 'tim_push_platform_interface.dart';
import 'tim_push_listener.dart';
import 'tim_push_result.dart';

export 'tim_push_listener.dart';
export 'tim_push_message.dart';
export 'tim_push_result.dart';

class TimPush {
  TimPush._internal();

  factory TimPush() => _instance;
  static final TimPush _instance = TimPush._internal();

  Future<TimPushResult<void>> registerPush({
    int? sdkAppId,
    String? appKey,
    int? businessId,
  }) {
    return TimPushPlatform.instance.registerPush(
      sdkAppId: sdkAppId,
      appKey: appKey,
      businessId: businessId,
    );
  }

  Future<TimPushResult<void>> unRegisterPush() {
    return TimPushPlatform.instance.unRegisterPush();
  }

  Future<TimPushResult<void>> disablePostNotificationInForeground({
    required bool disable,
  }) {
    return TimPushPlatform.instance.disablePostNotificationInForeground(
      disable: disable,
    );
  }

  Future<TimPushResult<void>> addPushListener({
    required TimPushListener listener,
  }) {
    return TimPushPlatform.instance.addPushListener(listener: listener);
  }

  Future<TimPushResult<void>> removePushListener({
    required TimPushListener listener,
  }) {
    return TimPushPlatform.instance.removePushListener(listener: listener);
  }

  Future<TimPushResult<void>> setRegistrationID({
    required String registrationID,
  }) {
    return TimPushPlatform.instance.setRegistrationID(
      registrationID: registrationID,
    );
  }

  Future<TimPushResult<String>> getRegistrationID() {
    return TimPushPlatform.instance.getRegistrationID();
  }

  Future<TimPushResult<void>> forceUseFCMPushChannel({
    required bool enable,
  }) {
    return TimPushPlatform.instance.forceUseFCMPushChannel(enable: enable);
  }

  Future<TimPushResult<void>> clearAllNotifications() {
    return TimPushPlatform.instance.clearAllNotifications();
  }
}

@Deprecated('Use TimPush instead.')
typedef TencentCloudChatPush = TimPush;
