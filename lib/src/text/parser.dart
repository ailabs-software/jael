import '../../jael.dart';
import '../ast/ast.dart';
import 'parselet/parselet.dart';
import 'scanner.dart';

class Parser {
  final List<JaelError> errors = [];
  final Scanner scanner;
  final bool asDSX;

  Token? _current;
  int _index = -1;

  Parser(this.scanner, {this.asDSX = false});

  Token? get current => _current;

  int _nextPrecedence() {
    Token? tok = peek();
    if (tok == null) return 0;

    InfixParselet? parser = infixParselets[tok.type];
    return parser?.precedence ?? 0;
  }

  bool next(TokenType type) {
    if (_index >= scanner.tokens.length - 1) return false;
    Token peek = scanner.tokens[_index + 1];

    if (peek.type != type) return false;

    _current = peek;
    _index++;
    return true;
  }

  Token? peek() {
    if (_index >= scanner.tokens.length - 1) return null;
    return scanner.tokens[_index + 1];
  }

  Token? maybe(TokenType type) => next(type) ? _current : null;

  void skipExtraneous(TokenType type) {
    while (next(type)) {
      // Skip...
    }
  }

  Document? parseDocument() {
    Doctype? doctype = parseDoctype();

    if (doctype == null) {
      Element? root = parseElement();
      if (root == null) return null;
      return Document(null, root);
    }

    Element? root = parseElement();

    if (root == null) {
      errors.add(new JaelError('Missing root element after !DOCTYPE declaration.', doctype.span));
      return null;
    }

    return Document(doctype, root);
  }

  StringLiteral? implicitString() {
    if (next(TokenType.string)) {
      return prefixParselets[TokenType.string]!.parse(this, _current)
          as StringLiteral?;
    }
    /*else if (next(TokenType.text)) {

    }*/

    return null;
  }

  Doctype? parseDoctype() {
    if (!next(TokenType.lt)) return null;
    Token? lt = _current;

    if (!next(TokenType.doctype)) {
      _index--;
      return null;
    }
    Token? doctype = _current;
    Identifier? html = parseIdentifier();
    if (html?.span.text?.toLowerCase() != 'html') {
      errors.add(new JaelError('Expected "html" in doctype declaration.', html?.span ?? doctype!.span));
      return null;
    }

    Identifier? public = parseIdentifier();
    if (public == null) {
      if (!next(TokenType.gt)) {
        errors.add(new JaelError('Expected ">" in doctype declaration.', html!.span));
        return null;
      }

      return new Doctype(lt, doctype, html, null, null, null, _current);
    }

    if (public.span.text?.toLowerCase() != 'public') {
      errors.add(new JaelError('Expected "public" in doctype declaration.', public.span));
      return null;
    }

    PrefixParselet? stringParser = prefixParselets[TokenType.string];

    if (!next(TokenType.string)) {
      errors.add(new JaelError('Expected string in doctype declaration.', public.span));
      return null;
    }

    StringLiteral? name = stringParser!.parse(this, _current) as StringLiteral?;

    if (!next(TokenType.string)) {
      errors.add(new JaelError('Expected string in doctype declaration.', name!.span));
      return null;
    }

    StringLiteral? url = stringParser.parse(this, _current) as StringLiteral?;

    if (!next(TokenType.gt)) {
      errors.add(new JaelError('Expected ">" in doctype declaration.', url!.span));
      return null;
    }

    return Doctype(lt, doctype, html, public, name, url, _current);
  }

  ElementChild? parseElementChild() =>
      parseHtmlComment() ??
      parseInterpolation() ??
      parseText() ??
      parseElement();

  HtmlComment? parseHtmlComment() =>
      next(TokenType.htmlComment) ? HtmlComment(_current) : null;

  Text? parseText() => next(TokenType.text) ? Text(_current) : null;

  Interpolation? parseInterpolation() {
    if (!next(asDSX ? TokenType.lCurly : TokenType.lDoubleCurly)) return null;
    Token? doubleCurlyL = _current;

    Expression? expression = parseExpression(0);

    if (expression == null) {
      errors.add(new JaelError('Missing expression in interpolation.', doubleCurlyL!.span));
      return null;
    }

    if (!next(asDSX ? TokenType.rCurly : TokenType.rDoubleCurly)) {
      String expected = asDSX ? '}' : '}}';
      errors.add(new JaelError('Missing closing "$expected" in interpolation.', expression.span));
      return null;
    }

    return Interpolation(doubleCurlyL, expression, _current);
  }

  Element? parseElement() {
    if (!next(TokenType.lt)) return null;
    Token? lt = _current;

    if (next(TokenType.slash)) {
      // We entered a closing tag, don't keep reading...
      _index -= 2;
      return null;
    }

    Identifier? tagName = parseTagName();

    if (tagName == null) {
      errors.add( new JaelError('Missing tag name.', lt!.span));
      return null;
    }

    List<Attribute> attributes = [];
    Attribute? attribute = parseAttribute();

    while (attribute != null) {
      attributes.add(attribute);
      attribute = parseAttribute();
    }

    if (next(TokenType.slash)) {
      // Try for self-closing...
      Token? slash = _current;

      if (!next(TokenType.gt)) {
        errors.add(new JaelError('Missing ">" in self-closing "${tagName.name}" tag.', slash!.span));
        return null;
      }

      return SelfClosingElement(lt, tagName, attributes, slash, _current);
    }

    if (!next(TokenType.gt)) {
      errors.add(new JaelError(
          'Missing ">" in "${tagName.name}" tag.',
          attributes.isEmpty ? tagName.span : attributes.last.span));
      return null;
    }

    Token? gt = _current;

    // Implicit self-closing
    if (Element.selfClosing.contains(tagName.name)) {
      return SelfClosingElement(lt, tagName, attributes, null, gt);
    }

    List<ElementChild> children = [];
    ElementChild? child = parseElementChild();

    while (child != null) {
      // if (child is! HtmlComment) children.add(child);
      children.add(child);
      child = parseElementChild();
    }

    // Parse closing tag
    if (!next(TokenType.lt)) {
      errors.add(new JaelError('Missing closing tag for "${tagName.name}" tag.', children.isEmpty ? tagName.span : children.last.span));
      return null;
    }

    Token? lt2 = _current;

    if (!next(TokenType.slash)) {
      errors.add(new JaelError('Missing "/" in "${tagName.name}" closing tag.', lt2!.span));
      return null;
    }

    Token? slash = _current;
    Identifier? tagName2 = parseTagName();

    if (tagName2 == null) {
      errors.add(new JaelError('Missing "${tagName.name}" in "${tagName.name}" closing tag.', slash!.span));
      return null;
    }

    if (tagName2.name != tagName.name) {
      errors.add( new JaelError('Mismatched closing tags. Expected "${tagName.name}"; got "${tagName2.name}" instead.', lt2!.span) );
      return null;
    }

    if (!next(TokenType.gt)) {
      errors.add(JaelError('Missing ">" in "${tagName.name}" closing tag.', tagName2.span));
      return null;
    }

    return RegularElement(
        lt, tagName, attributes, gt, children, lt2, slash, tagName2, _current);
  }

  Attribute? parseAttribute() {
    Identifier? id;
    StringLiteral? string;

    if ((id = parseIdentifier()) != null) {
      // Nothing
    } else if (next(TokenType.string)) {
      string = StringLiteral(_current, StringLiteral.parseValue(_current!));
    } else {
      return null;
    }

    Token? equals;
    Token? nequ;

    if (next(TokenType.equals)) {
      equals = _current;
    }
    else if (!asDSX && next(TokenType.nequ)) {
      nequ = _current;
    }
    else {
      return Attribute(id, string, null, null, null);
    }

    if (!asDSX) {
      Expression? value = parseExpression(0);

      if (value == null) {
        errors.add(new JaelError('Missing expression in attribute.', equals?.span ?? nequ!.span));
        return null;
      }

      return Attribute(id, string, equals, nequ, value);
    }
    else {
      // Find either a string, or an interpolation.
      StringLiteral? value = implicitString();

      if (value != null) {
        return Attribute(id, string, equals, nequ, value);
      }

      Interpolation? interpolation = parseInterpolation();

      if (interpolation != null) {
        return Attribute(id, string, equals, nequ, interpolation.expression);
      }

      errors.add(new JaelError('Missing expression in attribute.', equals?.span ?? nequ!.span));
      return null;
    }
  }

  Expression? parseExpression(int precedence) {
    // Only consume a token if it could potentially be a prefix parselet

    for (TokenType type in prefixParselets.keys)
    {

      if (next(type)) {
        Expression? left = prefixParselets[type]!.parse(this, _current);

        while (precedence < _nextPrecedence()) {
          _current = scanner.tokens[++_index];

          if (_current!.type == TokenType.slash &&
              peek()?.type == TokenType.gt) {
            // Handle `/>`
            //
            // Don't register this as an infix expression.
            // Instead, backtrack, and return the current expression.
            _index--;
            return left;
          }

          InfixParselet infix = infixParselets[_current!.type]!;
          Expression? newLeft = infix.parse(this, left, _current);

          if (newLeft == null) {
            if (_current!.type == TokenType.gt) _index--;
            return left;
          }
          left = newLeft;
        }

        return left;
      }
    }

    // Nothing was parsed; return null.
    return null;
  }

  Identifier? parseIdentifier()
  {
    return next(TokenType.id) ? new Identifier(_current) : null;
  }

  Identifier? parseTagName()
  {
    if ( next(TokenType.id) ) {
      Token? tagNameToken = _current;
      Token? tagNameExtensionToken = null;
      if ( next(TokenType.colon) ) {
        if ( next(TokenType.id) ) {
          tagNameExtensionToken = _current;
        }
        else {
          errors.add(new JaelError("Missing tag name extension following tag name because of colon.", tagNameToken!.span));
        }
      }
      return new Identifier(tagNameToken, tagNameExtensionToken);
    }
    else {
      return null;
    }
  }

  KeyValuePair? parseKeyValuePair() {
    Expression? key = parseExpression(0);
    if (key == null) return null;

    if (!next(TokenType.colon)) return KeyValuePair(key, null, null);

    Token? colon = _current;

    Expression? value = parseExpression(0);

    if (value == null) {
      errors.add(JaelError('Missing expression in key-value pair.', colon!.span));
      return null;
    }

    return KeyValuePair(key, colon, value);
  }

  NamedArgument? parseNamedArgument() {
    Identifier? name = parseIdentifier();
    if (name == null) return null;

    if (!next(TokenType.colon)) {
      errors.add(new JaelError('Missing ":" in named argument.', name.span));
      return null;
    }

    Token? colon = _current;
    Expression? value = parseExpression(0);

    if (value == null) {
      errors.add(new JaelError('Missing expression in named argument.', colon!.span));
      return null;
    }

    return NamedArgument(name, colon, value);
  }
}
