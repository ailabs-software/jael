import 'package:symbol_table/symbol_table.dart';
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'expression.dart';
import 'token.dart';

class Conditional extends Expression {
  final Expression condition, ifTrue, ifFalse;
  final Token question, colon;

  Conditional(
      this.condition, this.question, this.ifTrue, this.colon, this.ifFalse);

  @override
  CachingFileSpan get span {
    return condition.span
        .expand(question.span)
        .expand(ifTrue.span)
        .expand(colon.span)
        .expand(ifFalse.span);
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope) {
    var v = condition.compute(memberResolver, scope) as bool;

    if (scope.resolve('!strict!')?.value == false) {
      v = v == true;
    }

    return v ? ifTrue.compute(memberResolver, scope) : ifFalse.compute(memberResolver, scope);
  }
}
