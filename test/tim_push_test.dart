import 'package:flutter_test/flutter_test.dart';
import 'package:tim_push/tim_push.dart';
import 'package:tim_push/tim_push_platform_interface.dart';
import 'package:tim_push/tim_push_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTimPushPlatform
    with MockPlatformInterfaceMixin
    implements TimPushPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final TimPushPlatform initialPlatform = TimPushPlatform.instance;

  test('$MethodChannelTimPush is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTimPush>());
  });

  test('getPlatformVersion', () async {
    TimPush timPushPlugin = TimPush();
    MockTimPushPlatform fakePlatform = MockTimPushPlatform();
    TimPushPlatform.instance = fakePlatform;

    expect(await timPushPlugin.getPlatformVersion(), '42');
  });
}
