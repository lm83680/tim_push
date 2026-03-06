class TimPushResult<T> {
  TimPushResult({
    required this.code,
    this.message,
    this.data,
  });

  final int code;
  final String? message;
  final T? data;

  bool get isSuccess => code == 0;

  factory TimPushResult.fromMap(
    Map<Object?, Object?> source, {
    T? Function(Object?)? parser,
  }) {
    final Object? codeValue = source['code'];
    final int code;
    if (codeValue is int) {
      code = codeValue;
    } else {
      code = int.tryParse(codeValue?.toString() ?? '') ?? -1;
    }
    return TimPushResult<T>(
      code: code,
      message: source['message']?.toString(),
      data: parser != null ? parser(source['data']) : source['data'] as T?,
    );
  }
}
