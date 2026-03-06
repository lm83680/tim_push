import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tim_push_method_channel.dart';
import 'tim_push_listener.dart';
import 'tim_push_result.dart';

abstract class TimPushPlatform extends PlatformInterface {
  /// Constructs a TimPushPlatform.
  TimPushPlatform() : super(token: _token);

  static final Object _token = Object();

  static TimPushPlatform _instance = MethodChannelTimPush();

  /// The default instance of [TimPushPlatform] to use.
  ///
  /// Defaults to [MethodChannelTimPush].
  static TimPushPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TimPushPlatform] when
  /// they register themselves.
  static set instance(TimPushPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<TimPushResult<void>> registerPush({
    int? sdkAppId,
    String? appKey,
    int? businessId,
  }) {
    throw UnimplementedError('registerPush() has not been implemented.');
  }

  Future<TimPushResult<void>> unRegisterPush() {
    throw UnimplementedError('unRegisterPush() has not been implemented.');
  }

  Future<TimPushResult<void>> disablePostNotificationInForeground({
    required bool disable,
  }) {
    throw UnimplementedError(
        'disablePostNotificationInForeground() has not been implemented.');
  }

  Future<TimPushResult<void>> addPushListener(
      {required TimPushListener listener}) {
    throw UnimplementedError('addPushListener() has not been implemented.');
  }

  Future<TimPushResult<void>> removePushListener(
      {required TimPushListener listener}) {
    throw UnimplementedError('removePushListener() has not been implemented.');
  }

  Future<TimPushResult<void>> setRegistrationID(
      {required String registrationID}) {
    throw UnimplementedError('setRegistrationID() has not been implemented.');
  }

  Future<TimPushResult<String>> getRegistrationID() {
    throw UnimplementedError('getRegistrationID() has not been implemented.');
  }

  Future<TimPushResult<void>> forceUseFCMPushChannel({required bool enable}) {
    throw UnimplementedError(
        'forceUseFCMPushChannel() has not been implemented.');
  }
}
