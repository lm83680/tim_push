import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim_push/tim_push.dart';
import 'package:tim_push/tim_push_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelTimPush platform = MethodChannelTimPush();
  const MethodChannel channel = MethodChannel('tim_push');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'registerPush':
            return '';
          case 'getRegistrationID':
            return 'registration_mock';
          case 'forceUseFCMPushChannel':
            return '';
          case 'clearAllNotifications':
            return '';
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> simulateNativeMethodCall(MethodCall call) async {
    final ByteData message = const StandardMethodCodec().encodeMethodCall(call);
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      message,
      (_) {},
    );
  }

  test('registerPush', () async {
    final TimPushResult<void> result = await platform.registerPush();
    expect(result.code, 0);
  });

  test('getRegistrationID', () async {
    final TimPushResult<String> result = await platform.getRegistrationID();
    expect(result.code, 0);
    expect(result.data, 'registration_mock');
  });

  test('forceUseFCMPushChannel', () async {
    final TimPushResult<void> result =
        await platform.forceUseFCMPushChannel(enable: true);
    expect(result.code, 0);
  });

  test('clearAllNotifications', () async {
    final TimPushResult<void> result = await platform.clearAllNotifications();
    expect(result.code, 0);
  });

  test('onRecvPushMessage should dispatch to listener', () async {
    TimPushMessage? receivedMessage;
    final TimPushListener listener = TimPushListener(
      onMessageReceived: (TimPushMessage message) {
        receivedMessage = message;
      },
    );

    final TimPushResult<void> addResult =
        await platform.addPushListener(listener: listener);
    expect(addResult.code, 0);

    await simulateNativeMethodCall(
      const MethodCall(
        'onRecvPushMessage',
        <String, dynamic>{
          'messageID': 'mid_1001',
          'title': 'title',
          'desc': 'desc',
          'ext': 'ext',
        },
      ),
    );

    expect(receivedMessage, isNotNull);
    expect(receivedMessage?.messageId, 'mid_1001');
    expect(receivedMessage?.ext, 'ext');
  });
}
