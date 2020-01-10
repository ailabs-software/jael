import 'package:symbol_table/symbol_table.dart';
import 'member_resolver.dart';
import 'ast/ast.dart';

/** @fileoverview Abstract class which renders the document.
 *    Can be subclassed to render non-HTML, such as to DOM differ */

/** Type parameter T is type of output object */
abstract class Renderer<T extends StringSink>
{
  const Renderer();

  /** Abstract method. Renders a real element */
  void renderPrimaryElement(Element element, T output, IMemberResolver memberResolver, SymbolTable scope, SymbolTable childScope, bool html5);

  /** Abstract method. Write an interpolated value, properly escaping */
  void writeInterpolatedValue(T output, Interpolation interpolation, dynamic value);
  
  /** Abstract method. Render element close */
  void renderElementClose(T output, Element element);

  /** Abstract method. Called before render of child element */
  void beforeRenderChildElement(T output);

  /// Renders a [document] into the [output].
  ///
  /// If [strictResolution] is `false` (default: `true`), then undefined identifiers will return `null`
  /// instead of throwing.
  void render(Document document, T output, SymbolTable scope, {bool strictResolution = true, IMemberResolver memberResolver})
  {
    scope.create('!strict!', value: strictResolution != false);

    if (memberResolver == null) {
      memberResolver = new DefaultMemberResolver();
    }

    if (document.doctype != null) {
      output.writeln(document.doctype.span.text);
    }

    renderElement(document.root, output, memberResolver, scope, document.doctype?.public == null);
  }

  void renderElement(Element element, T output,  IMemberResolver memberResolver, SymbolTable scope, bool html5)
  {
    SymbolTable childScope = scope.createChild();

    if (element.attributes.any((a) => a.name == 'for-each')) {
      renderForeach(element, output, memberResolver, childScope, html5);
      return;
    }
    else if (element.attributes.any((a) => a.name == 'if')) {
      renderIf(element, output, memberResolver, childScope, html5);
      return;
    }
    else if (element.tagName.name == 'declare') {
      renderDeclare(element, output, memberResolver, childScope, html5);
      return;
    }
    else if (element.tagName.name == 'switch') {
      renderSwitch(element, output, memberResolver, childScope, html5);
      return;
    }
    else if (element.tagName.name == 'element') {
      registerCustomElement(element, output, memberResolver, childScope, html5);
      return;
    }
    else {
      dynamic customElementValue = scope.resolve(customElementName(memberResolver, element.tagName.name))?.value;

      if (customElementValue is Element) {
        renderCustomElement(element, output, memberResolver, childScope, html5);
        return;
      }
    }

    renderPrimaryElement(element, output, memberResolver, scope, childScope, html5);
  }

  void renderElementChildren(Element element, T output, IMemberResolver memberResolver, SymbolTable childScope, bool html5)
  {
    for (int i = 0; i < element.children.length; i++)
    {
      ElementChild child = element.children.elementAt(i);
      renderElementChild(element, child, output, memberResolver, childScope, html5, i, element.children.length);
    }
  }

  void renderForeach(Element element, T output, IMemberResolver memberResolver, SymbolTable scope, bool html5)
  {
    var attribute = element.attributes.singleWhere((a) => a.name == 'for-each');
    if (attribute.value == null) return;

    var asAttribute = element.attributes
        .firstWhere((a) => a.name == 'as', orElse: () => null);
    var indexAsAttribute = element.attributes
        .firstWhere((a) => a.name == 'index-as', orElse: () => null);
    var alias = asAttribute?.value?.compute(memberResolver, scope)?.toString() ?? 'item';
    var indexAs = indexAsAttribute?.value?.compute(memberResolver, scope)?.toString() ?? 'i';
    var otherAttributes = element.attributes.where(
        (a) => a.name != 'for-each' && a.name != 'as' && a.name != 'index-as');
    Element strippedElement;

    if (element is SelfClosingElement) {
      strippedElement = SelfClosingElement(element.lt, element.tagName,
          otherAttributes, element.slash, element.gt);
    } else if (element is RegularElement) {
      strippedElement = RegularElement(
          element.lt,
          element.tagName,
          otherAttributes,
          element.gt,
          element.children,
          element.lt2,
          element.slash,
          element.tagName2,
          element.gt2);
    }

    int i = 0;
    for (dynamic item in attribute.value.compute(memberResolver, scope)) {
      SymbolTable<dynamic> childScope = scope.createChild(values: <String, dynamic>{alias: item, indexAs: i++});
      renderElement(strippedElement, output, memberResolver, childScope, html5);
    }
  }

  void renderIf(Element element, T output, IMemberResolver memberResolver, SymbolTable scope, bool html5)
  {
    var attribute = element.attributes.singleWhere((a) => a.name == 'if');

    dynamic vv = attribute.value.compute(memberResolver, scope);

    if (scope.resolve('!strict!')?.value == false) {
      vv = vv == true;
    }

    bool v = vv as bool;

    if (!v) return;

    var otherAttributes = element.attributes.where((a) => a.name != 'if');
    Element strippedElement;

    if (element is SelfClosingElement) {
      strippedElement = SelfClosingElement(element.lt, element.tagName,
          otherAttributes, element.slash, element.gt);
    } else if (element is RegularElement) {
      strippedElement = RegularElement(
          element.lt,
          element.tagName,
          otherAttributes,
          element.gt,
          element.children,
          element.lt2,
          element.slash,
          element.tagName2,
          element.gt2);
    }

    renderElement(strippedElement, output, memberResolver, scope, html5);
  }

  void renderDeclare(Element element, T output, IMemberResolver memberResolver, SymbolTable scope, bool html5)
  {
    for (var attribute in element.attributes) {
      scope.create(attribute.name,
          value: attribute.value?.compute(memberResolver, scope), constant: true);
    }

    for (int i = 0; i < element.children.length; i++) {
      var child = element.children.elementAt(i);
      renderElementChild(element, child, output, memberResolver, scope, html5, i, element.children.length);
    }
  }

  void renderSwitch(Element element, T output, IMemberResolver memberResolver, SymbolTable scope, bool html5)
  {
    dynamic value = element.attributes
        .firstWhere((a) => a.name == 'value', orElse: () => null)
        ?.value
        ?.compute(memberResolver, scope);

    Iterable<Element> cases = element.children
        .whereType<Element>()
        .where((c) => c.tagName.name == 'case');

    for (Element child in cases) {
      dynamic comparison = child.attributes
              .firstWhere((a) => a.name == 'value', orElse: () => null)
              ?.value
              ?.compute(memberResolver, scope);

      if (comparison == value) {
        for (int i = 0; i < child.children.length; i++) {
          var c = child.children.elementAt(i);
          renderElementChild(element, c, output, memberResolver, scope, html5, i, child.children.length);
        }

        return;
      }
    }

    var defaultCase = element.children.firstWhere(
        (c) => c is Element && c.tagName.name == 'default',
        orElse: () => null) as Element;
    if (defaultCase != null) {
      for (int i = 0; i < defaultCase.children.length; i++) {
        var child = defaultCase.children.elementAt(i);
        renderElementChild(element, child, output, memberResolver, scope, html5, i, defaultCase.children.length);
      }
    }
  }

  void renderElementChild(Element parent, ElementChild child, T output, IMemberResolver memberResolver, SymbolTable scope, bool html5, int index, int total)
  {
    if (child is Text && parent?.tagName?.name != 'textarea') {
      if (index == 0) {
        output.write(child.span.text.trimLeft());
      }
      else if (index == total - 1) {
        output.write(child.span.text.trimRight());
      }
      else {
        output.write(child.span.text);
      }
    }
    else if (child is Interpolation) {
      dynamic value = child.expression.compute(memberResolver, scope);

      if (value != null) {
        writeInterpolatedValue(output, child, value);
      }
    }
    else if (child is Element) {
      beforeRenderChildElement(output);
      renderElement(child, output, memberResolver, scope, html5);
    }
  }

  static String customElementName(IMemberResolver memberResolver, String name)
  {
    return 'elements@$name';
  }

  void registerCustomElement(Element element, T output, IMemberResolver memberResolver, SymbolTable scope, bool html5)
  {
    if (element is! RegularElement) {
      throw JaelError(JaelErrorSeverity.error,
          "Custom elements cannot be self-closing.", element.span);
    }

    var name = element.getAttribute('name')?.value?.compute(memberResolver, scope)?.toString();

    if (name == null) {
      throw JaelError(
          JaelErrorSeverity.error,
          "Attribute 'name' is required when registering a custom element.",
          element.tagName.span);
    }

    try {
      var p = scope.isRoot ? scope : scope.parent;
      p.create(customElementName(memberResolver, name), value: element, constant: true);
    } on StateError {
      throw JaelError(
          JaelErrorSeverity.error,
          "Cannot re-define element '$name' in this scope.",
          element.getAttribute('name').span);
    }
  }

  void renderCustomElement(Element element, T output, IMemberResolver memberResolver, SymbolTable scope, bool html5)
  {
    RegularElement template = scope.resolve(customElementName(memberResolver, element.tagName.name)).value as RegularElement;
    dynamic renderAs = element.getAttribute('as')?.value?.compute(memberResolver, scope);
    Iterable<Attribute> attrs = element.attributes.where((a) => a.name != 'as');

    for (Attribute attribute in attrs) {
      if (attribute.name.startsWith('@')) {
        scope.create(attribute.name.substring(1),
            value: attribute.value?.compute(memberResolver, scope), constant: true);
      }
    }

    if (renderAs == false) {
      for (int i = 0; i < template.children.length; i++) {
        var child = template.children.elementAt(i);
        renderElementChild(element, child, output, memberResolver, scope, html5, i, element.children.length);
      }
    } else {
      var tagName = renderAs?.toString() ?? 'div';

      var syntheticElement = RegularElement(
          template.lt,
          SyntheticIdentifier(tagName),
          element.attributes
              .where((a) => a.name != 'as' && !a.name.startsWith('@')),
          template.gt,
          template.children,
          template.lt2,
          template.slash,
          SyntheticIdentifier(tagName),
          template.gt2);

      renderElement(syntheticElement, output, memberResolver, scope, html5);
    }
  }
}
