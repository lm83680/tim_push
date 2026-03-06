import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tim_push_method_channel.dart';

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
