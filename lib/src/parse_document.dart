import 'ast/ast.dart';
import 'text/parser.dart';
import 'text/scanner.dart';

/// Parses a Jael document.
Document parseDocument(String text, {String sourceUrl, bool asDSX = false, void onError(JaelError error)})
{
  var scanner = scan(text, sourceUrl: sourceUrl, asDSX: asDSX);

  if (scanner.errors.isNotEmpty && onError != null) {
    scanner.errors.forEach(onError);
  }
  else if (scanner.errors.isNotEmpty) {
    throw scanner.errors.first;
  }

  var parser = Parser(scanner, asDSX: asDSX);

  var doc = parser.parseDocument();

  if (parser.errors.isNotEmpty && onError != null) {
    parser.errors.forEach(onError);
  }
  else if (parser.errors.isNotEmpty) {
    throw parser.errors.first;
  }

  return doc;
}
