import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tim_push/tim_push.dart';
import 'package:tim_push/tim_push_method_channel.dart';
import 'package:tim_push/tim_push_platform_interface.dart';

class MockTimPushPlatform extends TimPushPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<TimPushResult<void>> registerPush({
    int? sdkAppId,
    String? appKey,
    int? businessId,
  }) {
    return Future<TimPushResult<void>>.value(TimPushResult<void>(code: 0));
  }

  @override
  Future<TimPushResult<void>> unRegisterPush() {
    return Future<TimPushResult<void>>.value(TimPushResult<void>(code: 0));
  }

  @override
  Future<TimPushResult<void>> setRegistrationID(
      {required String registrationID}) {
    return Future<TimPushResult<void>>.value(TimPushResult<void>(code: 0));
  }

  @override
  Future<TimPushResult<String>> getRegistrationID() {
    return Future<TimPushResult<String>>.value(
        TimPushResult<String>(code: 0, data: 'mock_registration_id'));
  }

  @override
  Future<TimPushResult<void>> addPushListener(
      {required TimPushListener listener}) {
    return Future<TimPushResult<void>>.value(TimPushResult<void>(code: 0));
  }

  @override
  Future<TimPushResult<void>> removePushListener(
      {required TimPushListener listener}) {
    return Future<TimPushResult<void>>.value(TimPushResult<void>(code: 0));
  }

  @override
  Future<TimPushResult<void>> disablePostNotificationInForeground(
      {required bool disable}) {
    return Future<TimPushResult<void>>.value(TimPushResult<void>(code: 0));
  }

  @override
  Future<TimPushResult<void>> forceUseFCMPushChannel({required bool enable}) {
    return Future<TimPushResult<void>>.value(TimPushResult<void>(code: 0));
  }

  @override
  Future<TimPushResult<void>> clearAllNotifications() {
    return Future<TimPushResult<void>>.value(TimPushResult<void>(code: 0));
  }
}

void main() {
  final TimPushPlatform initialPlatform = TimPushPlatform.instance;

  test('$MethodChannelTimPush is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTimPush>());
  });

  test('registerPush', () async {
    final TimPush timPushPlugin = TimPush();
    final MockTimPushPlatform fakePlatform = MockTimPushPlatform();
    TimPushPlatform.instance = fakePlatform;

    final TimPushResult<void> result = await timPushPlugin.registerPush();
    expect(result.code, 0);
  });

  test('getRegistrationID', () async {
    final TimPush timPushPlugin = TimPush();
    final MockTimPushPlatform fakePlatform = MockTimPushPlatform();
    TimPushPlatform.instance = fakePlatform;

    final TimPushResult<String> result =
        await timPushPlugin.getRegistrationID();
    expect(result.code, 0);
    expect(result.data, 'mock_registration_id');
  });

  test('clearAllNotifications', () async {
    final TimPush timPushPlugin = TimPush();
    final MockTimPushPlatform fakePlatform = MockTimPushPlatform();
    TimPushPlatform.instance = fakePlatform;

    final TimPushResult<void> result =
        await timPushPlugin.clearAllNotifications();
    expect(result.code, 0);
  });
}
