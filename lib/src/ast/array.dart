import 'package:jclosure/structs/symbols/symbol_table/SymbolTable.dart' show SymbolTable;
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'expression.dart';
import 'token.dart';

class Array extends Expression
{
  final Token lBracket, rBracket;
  final List<Expression> items;

  Array(this.lBracket, this.rBracket, this.items);

  @override
  CachingFileSpan get span
  {
    return items
        .fold<CachingFileSpan>(lBracket.span, (out, i) => out.expand(i.span))
        .expand(rBracket.span);
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope)
  {
    return items.map<dynamic>( (dynamic e) => e.compute(memberResolver, scope)).toList();
  }

  @override
  void assertIsValidDartExpression()
  {
    for (Expression item in items)
    {
      item.assertIsValidDartExpression();
    }
  }
}

class IndexerExpression extends Expression
{
  final Expression target;
  final Expression indexer;
  final Token lBracket;
  final Token rBracket;

  IndexerExpression(this.target, this.lBracket, this.indexer, this.rBracket);

  @override
  CachingFileSpan get span
  {
    return target.span
        .expand(lBracket.span)
        .expand(indexer.span)
        .expand(rBracket.span);
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope)
  {
    dynamic a = target.compute(memberResolver, scope), b = indexer.compute(memberResolver, scope);
    return a[b];
  }

  @override
  void assertIsValidDartExpression()
  {
    target.assertIsValidDartExpression();
    indexer.assertIsValidDartExpression();
  }
}
