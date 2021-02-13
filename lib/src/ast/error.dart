import 'caching_filespan.dart';

class JaelError extends Error {

  final String message;
  final CachingFileSpan span;

  JaelError(String this.message, CachingFileSpan this.span);

  @override
  String toString() {
    return
      "error: ${span.start.toolString}: $message\n" +
      span.highlight(color: false);
  }
}
