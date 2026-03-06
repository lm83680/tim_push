import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tim_push_platform_interface.dart';

/// An implementation of [TimPushPlatform] that uses method channels.
class MethodChannelTimPush extends TimPushPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tim_push');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
