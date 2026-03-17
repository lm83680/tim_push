import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tim_push_listener.dart';
import 'tim_push_message.dart';
import 'tim_push_platform_interface.dart';
import 'tim_push_result.dart';
import 'tim_push_utils.dart';

/// An implementation of [TimPushPlatform] that uses method channels.
class MethodChannelTimPush extends TimPushPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('tim_push');

  final Map<int, TimPushListener> _listenerMap = <int, TimPushListener>{};
  bool _eventHandlerInitialized = false;

  @override
  Future<TimPushResult<void>> registerPush({
    int? sdkAppId,
    String? appKey,
    int? ohosBusinessId,
  }) async {
    await _ensureMethodHandler();
    return _invokeVoid(
      'registerPush',
      <String, dynamic>{
        'sdk_app_id': sdkAppId,
        'app_key': appKey,
        'ohos_business_id': ohosBusinessId,
      },
    );
  }

  @override
  Future<TimPushResult<void>> unRegisterPush() {
    return _invokeVoid('unRegisterPush');
  }

  @override
  Future<TimPushResult<void>> disablePostNotificationInForeground({
    required bool disable,
  }) {
    return _invokeVoid(
      'disablePostNotificationInForeground',
      <String, dynamic>{'disable': disable},
    );
  }

  @override
  Future<TimPushResult<void>> addPushListener({
    required TimPushListener listener,
  }) async {
    await _ensureMethodHandler();
    final int listenerId = identityHashCode(listener);
    _listenerMap[listenerId] = listener;
    return _invokeVoid(
      'addPushListener',
      <String, dynamic>{'listener_id': listenerId},
    );
  }

  @override
  Future<TimPushResult<void>> removePushListener({
    required TimPushListener listener,
  }) async {
    final int listenerId = identityHashCode(listener);
    _listenerMap.remove(listenerId);
    return _invokeVoid(
      'removePushListener',
      <String, dynamic>{'listener_id': listenerId},
    );
  }

  @override
  Future<TimPushResult<void>> setRegistrationID({
    required String registrationID,
  }) {
    return _invokeVoid(
      'setRegistrationID',
      <String, dynamic>{'registration_id': registrationID},
    );
  }

  @override
  Future<TimPushResult<String>> getRegistrationID() {
    return _invoke<String>(
      'getRegistrationID',
      parser: (Object? source) => source?.toString(),
    );
  }

  @override
  Future<TimPushResult<void>> forceUseFCMPushChannel({
    required bool enable,
  }) {
    return _invokeVoid(
      'forceUseFCMPushChannel',
      <String, dynamic>{'enable': enable},
    );
  }

  @override
  Future<TimPushResult<void>> clearAllNotifications() {
    return _invokeVoid('clearAllNotifications');
  }

  Future<void> _ensureMethodHandler() async {
    if (_eventHandlerInitialized) {
      return;
    }
    methodChannel.setMethodCallHandler(_handleMethodCall);
    _eventHandlerInitialized = true;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationClicked':
      case 'on_notification_clicked':
        _dispatchNotificationClicked(call.arguments);
        break;
      case 'onRecvPushMessage':
      case 'onMessageReceived':
      case 'on_message_received':
        _dispatchMessageReceived(call.arguments);
        break;
      case 'onRevokePushMessage':
      case 'on_revoke_push_message':
        _dispatchMessageRevoked(call.arguments?.toString() ?? '');
        break;
      case 'onAppWakeUp':
      case 'on_app_wake_up':
        // 仅消费事件，避免未监听时抛出异常。
        break;
      default:
        throw UnsupportedError('Unrecognized Event: ${call.method}');
    }
  }

  void _dispatchNotificationClicked(Object? rawExt) {
    final String ext = rawExt?.toString() ?? '';
    final TimPushExtInfo extInfo = TimPushUtils.parseExtInfo(ext);
    for (final TimPushListener listener in _listenerMap.values) {
      listener.onNotificationClicked?.call(
        ext: ext,
        userID: extInfo.userID,
        groupID: extInfo.groupID,
      );
    }
  }

  void _dispatchMessageReceived(Object? data) {
    final TimPushMessage message = TimPushMessage.fromDynamic(data);
    for (final TimPushListener listener in _listenerMap.values) {
      listener.onMessageReceived?.call(message);
    }
  }

  void _dispatchMessageRevoked(String messageId) {
    for (final TimPushListener listener in _listenerMap.values) {
      listener.onRevokePushMessage?.call(messageId);
    }
  }

  Future<TimPushResult<void>> _invokeVoid(
    String method, [
    Map<String, dynamic>? arguments,
  ]) {
    return _invoke<Object?>(
      method,
      arguments: arguments,
    ).then(
      (TimPushResult<Object?> result) => TimPushResult<void>(
        code: result.code,
        message: result.message,
      ),
    );
  }

  Future<TimPushResult<T>> _invoke<T>(
    String method, {
    Map<String, dynamic>? arguments,
    T? Function(Object?)? parser,
  }) async {
    try {
      final Object? response =
          await methodChannel.invokeMethod<Object?>(method, arguments);
      if (response is Map) {
        return TimPushResult<T>.fromMap(
          response.cast<Object?, Object?>(),
          parser: parser,
        );
      }
      return TimPushResult<T>(
        code: 0,
        data: parser != null ? parser(response) : response as T?,
      );
    } on PlatformException catch (error) {
      return TimPushResult<T>(
        code: int.tryParse(error.code) ?? -1,
        message: error.message,
      );
    } catch (error) {
      return TimPushResult<T>(
        code: -1,
        message: error.toString(),
      );
    }
  }
}
