import 'tim_push_message.dart';

typedef TimPushNotificationClicked = void Function({
  required String ext,
  String? userID,
  String? groupID,
});

typedef TimPushAppWakeUp = void Function();
typedef TimPushMessageReceived = void Function(TimPushMessage message);
typedef TimPushMessageRevoked = void Function(String messageId);

class TimPushListener {
  const TimPushListener({
    this.onMessageReceived,
    this.onRevokePushMessage,
    this.onNotificationClicked,
  });

  final TimPushMessageReceived? onMessageReceived;
  final TimPushMessageRevoked? onRevokePushMessage;
  final TimPushNotificationClicked? onNotificationClicked;
}
