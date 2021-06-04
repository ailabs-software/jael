import 'caching_filespan.dart';
import 'ast_node.dart';
import 'expression.dart';
import 'identifier.dart';
import 'string.dart';
import 'token.dart';
import 'error.dart';

class Attribute extends AstNode
{
  final Identifier? id;
  final StringLiteral? string;
  final Token? equals;
  final Token? nequ;
  final Expression? value;

  Attribute(this.id, this.string, this.equals, this.nequ, this.value);

  bool get isRaw
  {
    return nequ != null;
  }

  Expression? get nameNode
  {
    return id ?? string;
  }

  String get name
  {
    return string?.value ?? id!.name;
  }

  @override
  CachingFileSpan get span
  {
    if (equals == null) {
      return nameNode!.span;
    }
    return nameNode!.span.expand(equals?.span ?? nequ!.span).expand(value!.span);
  }

  Expression getRequiredValue()
  {
    Expression? valueAlias = value;
    if (valueAlias == null) {
      throw new JaelError("The attribute \"${name}\" does not have a value, but a value is required.", span);
    }
    return valueAlias;
  }
}
