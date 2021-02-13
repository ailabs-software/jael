import 'package:charcode/charcode.dart';
import 'package:jclosure/structs/symbols/symbol_table/SymbolTable.dart' show SymbolTable;
import 'package:jael/src/member_resolver.dart';
import 'caching_filespan.dart';
import '../ast/ast.dart';
import 'expression.dart';
import 'token.dart';

/** Used by StringLiteral.assertIsValidDartExpression(). Only used when transpiling to Dart. */
final RegExp _matchUnescapedDollarSign = new RegExp(r"(?<!\\)\$");

class StringLiteral extends Literal
{
  final Token string;
  final String value;

  StringLiteral(Token this.string, String this.value);

  static String parseValue(Token string)
  {
    String text = string.span.text.substring(1, string.span.text.length - 1);
    List<int> codeUnits = text.codeUnits;
    StringBuffer buf = new StringBuffer();

    for (int i = 0; i < codeUnits.length; i++)
    {
      int ch = codeUnits[i];

      if (ch == $backslash) {
        if (i < codeUnits.length - 5 && codeUnits[i + 1] == $u) {
          int c1 = codeUnits[i += 2],
              c2 = codeUnits[++i],
              c3 = codeUnits[++i],
              c4 = codeUnits[++i];
          String hexString = String.fromCharCodes([c1, c2, c3, c4]);
          int hexNumber = int.parse(hexString, radix: 16);
          buf.write(String.fromCharCode(hexNumber));
          continue;
        }

        if (i < codeUnits.length - 1) {
          var next = codeUnits[++i];

          switch (next) {
            case $b:
              buf.write('\b');
              break;
            case $f:
              buf.write('\f');
              break;
            case $n:
              buf.writeCharCode($lf);
              break;
            case $r:
              buf.writeCharCode($cr);
              break;
            case $t:
              buf.writeCharCode($tab);
              break;
            default:
              buf.writeCharCode(next);
          }
        }
        else {
          throw new JaelError('Unexpected "\\" in string literal.', string.span);
        }
      }
      else {
        buf.writeCharCode(ch);
      }
    }

    return buf.toString();
  }

  @override
  CachingFileSpan get span
  {
    return string.span;
  }

  @override
  dynamic compute(IMemberResolver memberResolver, SymbolTable scope)
  {
    return value;
  }

  @override
  void assertIsValidDartExpression()
  {
    // This feature is used only when transpiling to Dart (not by normal Jael renderer):

    // A string containing an unescaped $ cannot be trivially verified to be syntactically valid Dart code,
    // so for the sake of simplicity, we will force all strings to have dollar sign escaped when transpiling to Dart.
    // Note: We remove double-slashes before checking, otherwise regexp won't see "\\$" as unescaped.
    if ( _matchUnescapedDollarSign.hasMatch( string.span.text.replaceAll(r"\\", "") ) ) {
      throw new JaelError("To ensure your string literal is valid Dart, dollar sign (\$) must be escaped with a preceding back slash.", span);
    }

    // Check for non-escaped newline characters in input, which are not supported as Dart expressions (currently).
    if ( string.span.text.contains("\n") ) {
      throw new JaelError(r"To ensure your string literal is valid Dart, it cannot be multiline (you can use \n to insert a new line character).", span);
    }
  }
}
