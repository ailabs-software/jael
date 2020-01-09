import 'package:source_span/source_span.dart';
import 'package:symbol_table/symbol_table.dart';
import 'package:jael/src/member_resolver.dart';
import 'expression.dart';
import 'token.dart';

class Array extends Expression {
  final Token lBracket, rBracket;
  final List<Expression> items;

  Array(this.lBracket, this.rBracket, this.items);

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope) => items.map((e) => e.compute(memberResolver, scope)).toList();

  @override
  FileSpan get span {
    return items
        .fold<FileSpan>(lBracket.span, (out, i) => out.expand(i.span))
        .expand(rBracket.span);
  }
}

class IndexerExpression extends Expression {
  final Expression target, indexer;
  final Token lBracket, rBracket;

  IndexerExpression(this.target, this.lBracket, this.indexer, this.rBracket);

  @override
  FileSpan get span {
    return target.span
        .expand(lBracket.span)
        .expand(indexer.span)
        .expand(rBracket.span);
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope) {
    dynamic a = target.compute(memberResolver, scope), b = indexer.compute(memberResolver, scope);
    return a[b];
  }
}
