import 'package:jclosure/structs/symbols/symbol_table/SymbolTable.dart';
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'expression.dart';
import 'token.dart';

class Conditional extends Expression
{
  final Expression? condition;
  final Expression ifTrue;
  final Expression ifFalse;
  final Token? question;
  final Token? colon;

  Conditional(this.condition, this.question, this.ifTrue, this.colon, this.ifFalse);

  @override
  CachingFileSpan get span
  {
    return condition!.span
        .expand(question!.span)
        .expand(ifTrue.span)
        .expand(colon!.span)
        .expand(ifFalse.span);
  }

  @override
  dynamic compute(IMemberResolver? memberResolver, SymbolTable? scope)
  {
    bool? v = condition!.compute(memberResolver, scope) as bool?;

    if (scope!.resolve('!strict!')?.value == false) {
      v = v == true;
    }

    return v! ? ifTrue.compute(memberResolver, scope) : ifFalse.compute(memberResolver, scope);
  }

  @override
  void assertIsValidDartExpression()
  {
    condition!.assertIsValidDartExpression();
    ifTrue.assertIsValidDartExpression();
    ifFalse.assertIsValidDartExpression();
  }
}
