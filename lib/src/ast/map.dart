import 'package:symbol_table/symbol_table.dart';
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'ast_node.dart';
import 'expression.dart';
import 'identifier.dart';
import 'token.dart';

class MapLiteral extends Literal {
  final Token lCurly, rCurly;
  final List<KeyValuePair> pairs;

  MapLiteral(this.lCurly, this.pairs, this.rCurly);

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope)
  {
    return pairs.fold< Map<String, dynamic> >(<String, dynamic>{}, (out, p) {
      String key;
      dynamic value;

      if (p.colon == null) {
        if (p.key is! Identifier) {
          key = value = p.key.compute(memberResolver, scope) as String;
        } else {
          key = (p.key as Identifier).name;
          value = p.key.compute(memberResolver, scope);
        }
      } else {
        key = p.key.compute(memberResolver, scope) as String;
        value = p.value.compute(memberResolver, scope);
      }

      return out..[key] = value;
    });
  }

  @override
  CachingFileSpan get span {
    return pairs
        .fold<CachingFileSpan>(lCurly.span, (out, p) => out.expand(p.span))
        .expand(rCurly.span);
  }
}

class KeyValuePair extends AstNode {
  final Expression key, value;
  final Token colon;

  KeyValuePair(this.key, this.colon, this.value);

  @override
  CachingFileSpan get span {
    if (colon == null) return key.span;
    return colon.span.expand(colon.span).expand(value.span);
  }
}
