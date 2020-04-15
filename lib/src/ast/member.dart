import 'package:symbol_table/symbol_table.dart';
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'expression.dart';
import 'identifier.dart';
import 'token.dart';

class MemberExpression extends Expression {
  final Expression expression;
  final Token op;
  final Identifier name;

  MemberExpression(this.expression, this.op, this.name);

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope) {
    Object target = expression.compute(memberResolver, scope);
    if (op.span.text == '?.' && target == null) return null;
    return memberResolver.getMember(target, name.name);
  }

  @override
  CachingFileSpan get span => expression.span.expand(op.span).expand(name.span);
}
