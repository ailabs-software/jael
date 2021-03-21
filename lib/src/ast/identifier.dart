import 'package:jclosure/structs/symbols/symbol_table/SymbolTable.dart';
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'expression.dart';
import 'token.dart';

class Identifier extends Expression
{
  final Token id;

  /** Extension to identifier name, used with : syntax in tag names, e.g. <h4:TextLabel></h4> */
  final Token extension;

  Identifier(Token this.id, [Token this.extension]);

  @override
  CachingFileSpan get span
  {
    return id.span;
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope)
  {
    switch (name)
    {
      case 'null':
        return null;
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        var symbol = scope.resolve(name);
        if (symbol == null) {
          if (scope.resolve('!strict!')?.value == false) return null;
          throw ArgumentError('The name "$name" does not exist in this scope.');
        }
        return scope.resolve(name).value;
    }
  }

  String get name
  {
    StringBuffer sb = new StringBuffer();
    sb.write(id.span.text);
    if (extension != null) {
      sb.write(":");
      sb.write(extension.span.text);
    }
    return sb.toString();
  }

  @override
  void assertIsValidDartExpression()
  {
    // No-op implementation. Assuming to be valid Dart if parsed to Jael successfully.
  }
}

class SyntheticIdentifier extends Identifier
{
  @override
  final String name;

  SyntheticIdentifier(String this.name, [Token token]) : super(token);

  @override
  CachingFileSpan get span
  {
    if (id != null) {
      return id.span;
    }
    throw new UnsupportedError('Cannot get the span of a SyntheticIdentifier.');
  }

  @override
  void assertIsValidDartExpression()
  {
    // No-op implementation. Assuming to be valid Dart if parsed to Jael successfully.
  }
}
