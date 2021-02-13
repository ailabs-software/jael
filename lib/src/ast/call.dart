import 'package:jclosure/structs/symbols/symbol_table/SymbolTable.dart' show SymbolTable;
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'ast_node.dart';
import 'expression.dart';
import 'identifier.dart';
import 'token.dart';

class Call extends Expression
{
  final Expression target;
  final Token lParen, rParen;
  final List<Expression> arguments;
  final List<NamedArgument> namedArguments;

  Call(this.target, this.lParen, this.rParen, this.arguments, this.namedArguments);

  @override
  CachingFileSpan get span
  {
    return arguments
        .fold<CachingFileSpan>(target.span, (out, a) => out.expand(a.span))
        .expand(namedArguments.fold<CachingFileSpan>(
            lParen.span, (out, a) => out.expand(a.span)))
        .expand(rParen.span);
  }

  List computePositional(IMemberResolver memberResolver, SymbolTable scope) =>
      arguments.map<dynamic>((dynamic e) => e.compute(memberResolver, scope)).toList();

  Map<Symbol, dynamic> computeNamed(IMemberResolver memberResolver, SymbolTable scope) {
    return namedArguments.fold<Map<Symbol, dynamic> >(<Symbol, dynamic>{}, (out, a) {
      return out..[Symbol(a.name.name)] = a.value.compute(memberResolver, scope);
    });
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope)
  {
    dynamic callee = target.compute(memberResolver, scope);
    List<dynamic> args = computePositional(memberResolver, scope);
    var named = computeNamed(memberResolver, scope);

    return Function.apply(callee as Function, args, named);
  }

  @override
  void assertIsValidDartExpression()
  {
    target.assertIsValidDartExpression();

    for (Expression argument in arguments)
    {
      argument.assertIsValidDartExpression();
    }

    for (NamedArgument namedArgument in namedArguments)
    {
      namedArgument.name.assertIsValidDartExpression();
      namedArgument.value.assertIsValidDartExpression();
    }
  }
}

class NamedArgument extends AstNode
{
  final Identifier name;
  final Token colon;
  final Expression value;

  NamedArgument(this.name, this.colon, this.value);

  @override
  CachingFileSpan get span
  {
    return name.span.expand(colon.span).expand(value.span);
  }
}
