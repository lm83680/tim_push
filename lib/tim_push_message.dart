class TimPushMessage {
  TimPushMessage({
    required this.rawData,
    this.messageId,
    this.ext,
  });

  final Map<String, dynamic> rawData;
  final String? messageId;
  final String? ext;

  factory TimPushMessage.fromDynamic(Object? source) {
    if (source is Map) {
      final Map<String, dynamic> normalized = source.map(
        (Object? key, Object? value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
      return TimPushMessage(
        rawData: normalized,
        messageId: normalized['messageID']?.toString() ??
            normalized['messageId']?.toString(),
        ext: normalized['ext']?.toString(),
      );
    }
    return TimPushMessage(
      rawData: <String, dynamic>{'raw': source},
      ext: source?.toString(),
    );
  }
}
