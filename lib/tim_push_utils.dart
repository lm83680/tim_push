import 'dart:convert';

class TimPushExtInfo {
  TimPushExtInfo({this.userID, this.groupID});

  final String? userID;
  final String? groupID;
}

class TimPushUtils {
  static TimPushExtInfo parseExtInfo(String ext) {
    String? userID;
    String? groupID;
    try {
      final Object? decoded = json.decode(ext);
      if (decoded is! Map) {
        return TimPushExtInfo();
      }
      final Map<String, dynamic> payload = decoded.map(
        (Object? key, Object? value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
      final String? conversationID = payload['conversationID']?.toString();
      if (conversationID != null) {
        final RegExpMatch? c2cMatch =
            RegExp(r'^c2c_(.*)').firstMatch(conversationID);
        final RegExpMatch? groupMatch =
            RegExp(r'^group_(.*)').firstMatch(conversationID);
        if (c2cMatch != null) {
          userID = c2cMatch.group(1);
        } else if (groupMatch != null) {
          groupID = groupMatch.group(1);
        }
      } else {
        final Object? entityObject = payload['entity'];
        if (entityObject is Map) {
          final Map<String, dynamic> entity = entityObject.map(
            (Object? key, Object? value) =>
                MapEntry<String, dynamic>(key.toString(), value),
          );
          final int? chatType = entity['chatType'] as int?;
          final String? sender = entity['sender']?.toString();
          if (chatType == 1) {
            userID = sender;
          } else if (chatType == 2) {
            groupID = sender;
          }
        }
      }
    } catch (_) {
      // ext 不是合法 JSON 时返回空解析结果。
    }
    return TimPushExtInfo(userID: userID, groupID: groupID);
  }
}
