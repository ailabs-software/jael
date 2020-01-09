import 'package:source_span/source_span.dart';
import 'package:symbol_table/symbol_table.dart';
import 'package:jael/src/member_resolver.dart';
import 'ast_node.dart';
import 'expression.dart';
import 'identifier.dart';
import 'token.dart';

class Call extends Expression {
  final Expression target;
  final Token lParen, rParen;
  final List<Expression> arguments;
  final List<NamedArgument> namedArguments;

  Call(this.target, this.lParen, this.rParen, this.arguments,
      this.namedArguments);

  @override
  FileSpan get span {
    return arguments
        .fold<FileSpan>(target.span, (out, a) => out.expand(a.span))
        .expand(namedArguments.fold<FileSpan>(
            lParen.span, (out, a) => out.expand(a.span)))
        .expand(rParen.span);
  }

  List computePositional(IMemberResolver memberResolver, SymbolTable scope) =>
      arguments.map((e) => e.compute(memberResolver, scope)).toList();

  Map<Symbol, dynamic> computeNamed(IMemberResolver memberResolver, SymbolTable scope) {
    return namedArguments.fold<Map<Symbol, dynamic>>({}, (out, a) {
      return out..[Symbol(a.name.name)] = a.value.compute(memberResolver, scope);
    });
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope) {
    var callee = target.compute(memberResolver, scope);
    var args = computePositional(memberResolver, scope);
    var named = computeNamed(memberResolver, scope);

    return Function.apply(callee as Function, args, named);
  }
}

class NamedArgument extends AstNode {
  final Identifier name;
  final Token colon;
  final Expression value;

  NamedArgument(this.name, this.colon, this.value);

  @override
  FileSpan get span {
    return name.span.expand(colon.span).expand(value.span);
  }
}
