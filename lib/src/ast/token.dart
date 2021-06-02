import 'caching_filespan.dart';

class Token {
  final TokenType type;
  final CachingFileSpan span;
  final Match? match;

  Token(TokenType this.type, CachingFileSpan this.span, Match? this.match);

  @override
  String toString()
  {
    return '${span.start.toolString}: "${span.text}" => $type';
  }
}

enum TokenType {
  /*
   * HTML
   */
  doctype,
  htmlComment,
  lt,
  gt,
  slash,
  equals,
  id,
  text,

  // Keywords
  $new,

  /*
   * Expression
   */
  lBracket,
  rBracket,
  lDoubleCurly,
  rDoubleCurly,
  lCurly,
  rCurly,
  lParen,
  rParen,
  asterisk,
  colon,
  comma,
  dot,
  exclamation,
  percent,
  plus,
  minus,
  elvis,
  elvis_dot,
  lte,
  gte,
  equ,
  nequ,
  number,
  hex,
  string,
  question,
}
