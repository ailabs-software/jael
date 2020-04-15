import 'caching_filespan.dart';

class JaelError extends Error {
  final JaelErrorSeverity severity;
  final String message;
  final CachingFileSpan span;

  JaelError(this.severity, this.message, this.span);

  @override
  String toString() {
    var label = severity == JaelErrorSeverity.warning ? 'warning' : 'error';
    return '$label: ${span.start.toolString}: $message\n' +
        span.highlight(color: true);
  }
}

enum JaelErrorSeverity {
  warning,
  error,
}
