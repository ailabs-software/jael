import 'dart:math' as math;
import 'package:jclosure/structs/symbols/symbol_table/SymbolTable.dart';
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import 'expression.dart';
import 'token.dart';

class NumberLiteral extends Literal
{
  final Token number;
  num _value;

  NumberLiteral(this.number);

  @override
  CachingFileSpan get span
  {
    return number.span;
  }

  static num parse(String value)
  {
    var e = value.indexOf('E');
    e != -1 ? e : e = value.indexOf('e');

    if (e == -1) return num.parse(value);

    var plainNumber = num.parse(value.substring(0, e));
    var exp = value.substring(e + 1);
    return plainNumber * math.pow(10, num.parse(exp));
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope)
  {
    return _value ??= parse(number.span.text);
  }

  @override
  void assertIsValidDartExpression()
  {
    // No-op implementation. Assuming to be valid Dart if parsed to Jael successfully.
  }
}

class HexLiteral extends Literal
{
  final Token hex;
  num _value;

  HexLiteral(this.hex);

  @override
  CachingFileSpan get span
  {
    return hex.span;
  }

  static num parse(String value)
  {
    return int.parse(value.substring(2), radix: 16);
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope)
  {
    return _value ??= parse(hex.span.text);
  }

  @override
  void assertIsValidDartExpression()
  {
    // No-op implementation. Assuming to be valid Dart if parsed to Jael successfully.
  }
}
