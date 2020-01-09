import 'package:source_span/source_span.dart';
import 'package:symbol_table/symbol_table.dart';
import 'package:jael/src/member_resolver.dart';
import 'call.dart';
import 'expression.dart';
import 'token.dart';

class NewExpression extends Expression {
  final Token $new;
  final Call call;

  NewExpression(this.$new, this.call);

  @override
  FileSpan get span => $new.span.expand(call.span);

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope) {
    return new UnsupportedError('NewExpression is unsupported.');
  }
}
