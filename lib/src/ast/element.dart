import 'caching_filespan.dart';
import 'ast_node.dart';
import 'attribute.dart';
import 'identifier.dart';
import 'token.dart';

abstract class ElementChild extends AstNode
{

}

class TextNode extends ElementChild
{
  final Token text;

  TextNode(this.text);

  @override
  CachingFileSpan get span => text.span;
}

abstract class Element extends ElementChild
{
  static const Set<String> selfClosing = {
    'include',
    'base',
    'basefont',
    'frame',
    'link',
    'meta',
    'area',
    'br',
    'col',
    'hr',
    'img',
    'input',
    'param'
  };

  Identifier get tagName;

  Iterable<Attribute> get attributes;

  Iterable<ElementChild> get children;

  Iterable<Element> get childElements
  {
    return children.whereType<Element>();
  }

  Iterable<String> get attributeNames
  {
    return attributes.map( (Attribute attribute) => attribute.name );
  }

  Attribute getAttribute(String name)
  {
    for (Attribute attribute in attributes)
    {
      if (attribute.name == name) {
        return attribute;
      }
    }

    return null;
  }

  Attribute getRequiredAttribute(String name)
  {
    Attribute attribute = getAttribute(name);
    if (attribute == null) {
      throw new Exception("The attribute \"${name}\" of <${tagName.name}> is required, but is missing.");
    }
    return attribute;
  }

  bool hasAttribute(String name)
  {
    for (Attribute attribute in attributes)
    {
      if (attribute.name == name) {
        return true;
      }
    }
    return false;
  }

  /** Not used by Jael's HTML renderer, but is used by Ellaments */
  Element getChildByTagName(String name)
  {
    for (Element child in childElements)
    {
      if (child.tagName.name == name) {
        return child;
      }
    }
    throw new Exception("No immediate child of <${tagName.name}> by named <${name}>");
  }

  /** Not used by Jael's renderer. Gets children by tag name. */
  Iterable<Element> getChildrenByTagName(String name)
  {
    return childElements.where( (Element element) => element.tagName.name == name );
  }
}

class SelfClosingElement extends Element
{
  final Token lt;

  final Token slash;

  final Token gt;

  @override
  final Identifier tagName;

  @override
  final Iterable<Attribute> attributes;

  @override
  Iterable<ElementChild> get children => [];

  SelfClosingElement(
      this.lt, this.tagName, this.attributes, this.slash, this.gt);

  @override
  CachingFileSpan get span
  {
    CachingFileSpan start = attributes.fold<CachingFileSpan>(
        lt.span.expand(tagName.span), (out, a) => out.expand(a.span));
    return slash != null
        ? start.expand(slash.span).expand(gt.span)
        : start.expand(gt.span);
  }
}

class RegularElement extends Element
{
  final Token lt;

  final Token gt;

  final Token lt2;

  final Token slash;

  final Token gt2;

  @override
  final Identifier tagName;

  final Identifier tagName2;

  @override
  final Iterable<Attribute> attributes;

  @override
  final Iterable<ElementChild> children;

  RegularElement(this.lt, this.tagName, this.attributes, this.gt, this.children,
      this.lt2, this.slash, this.tagName2, this.gt2);

  @override
  CachingFileSpan get span
  {
    CachingFileSpan openingTag = attributes
        .fold<CachingFileSpan>(
            lt.span.expand(tagName.span), (out, a) => out.expand(a.span))
        .expand(gt.span);

    if (gt2 == null) return openingTag;

    return children
        .fold<CachingFileSpan>(openingTag, (out, c) => out.expand(c.span))
        .expand(lt2.span)
        .expand(slash.span)
        .expand(tagName2.span)
        .expand(gt2.span);
  }
}
