import 'package:symbol_table/symbol_table.dart';
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'ast_node.dart';
import 'token.dart';

abstract class Expression extends AstNode {
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope);
}

abstract class Literal extends Expression {

}

class Negation extends Expression {
  final Token exclamation;
  final Expression expression;

  Negation(this.exclamation, this.expression);

  @override
  CachingFileSpan get span {
    return exclamation.span.expand(expression.span);
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope) {
    var v = expression.compute(memberResolver, scope) as bool;

    if (scope.resolve('!strict!')?.value == false) {
      v = v == true;
    }

    return !v;
  }
}
