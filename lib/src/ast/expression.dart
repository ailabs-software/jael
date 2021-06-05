import 'package:jael/jael.dart';
import 'package:jclosure/structs/symbols/symbol_table/SymbolTable.dart';
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'ast_node.dart';
import 'token.dart';

abstract class Expression extends AstNode
{
  dynamic compute(IMemberResolver? memberResolver, SymbolTable? scope);

  String computeAsStringLiteral()
  {
    Object? value = compute(null, null);
    if (value == null) {
      throw new JaelError("A string literal is expected, but the expression evaluated to null.", span);
    }
    if (value is String) {
      return value;
    }
    throw new JaelError("A string literal is expected, but the expression evaluated to a non-string type.", span);
  }

  void assertIsValidDartExpression();
}

abstract class Literal extends Expression
{

}

class Negation extends Expression
{
  final Token? exclamation;
  final Expression? expression;

  Negation(this.exclamation, this.expression);

  @override
  CachingFileSpan get span
  {
    return exclamation!.span.expand(expression!.span);
  }

  @override
  dynamic compute(IMemberResolver? memberResolver, SymbolTable? scope)
  {
    bool? v = expression!.compute(memberResolver, scope) as bool?;

    if (scope!.resolve('!strict!')?.value == false) {
      v = v == true;
    }

    return !v!;
  }

  @override
  void assertIsValidDartExpression()
  {
    expression!.assertIsValidDartExpression();
  }
}
