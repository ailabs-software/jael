import 'package:jclosure/structs/symbols/symbol_table/SymbolTable.dart' show SymbolTable;
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'expression.dart';
import 'identifier.dart';
import 'token.dart';

class MemberExpression extends Expression
{
  final Expression expression;
  final Token op;
  final Identifier name;

  MemberExpression(this.expression, this.op, this.name);

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope)
  {
    Object target = expression.compute(memberResolver, scope);
    if (op.span.text == '?.' && target == null) return null;
    return memberResolver.getMember(target, name.name);
  }

  @override
  CachingFileSpan get span
  {
    return expression.span.expand(op.span).expand(name.span);
  }

  @override
  void assertIsValidDartExpression()
  {
    expression.assertIsValidDartExpression();
    name.assertIsValidDartExpression();
  }
}
