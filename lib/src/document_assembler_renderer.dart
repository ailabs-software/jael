import "package:jclosure/structs/symbols/symbol_table/SymbolTable.dart" show SymbolTable;
import "package:jael/src/member_resolver.dart";
import "package:jael/src/ast/ast.dart";
import "package:jael/src/renderer.dart";
import "package:jclosure/dom/TagDefinition.dart";
import "package:jclosure/dom/TagName.dart";
import "package:jclosure/dom/isomorphic/IDocumentAssembler.dart";

/** @fileoverview A Jael renderer for IDocumentAssembler output */

class DocumentAssemblerRenderer<T extends IDocumentAssembler> extends Renderer<T>
{
  const DocumentAssemblerRenderer();

  /** Abstract method. Renders a real element */
  @override
  void renderPrimaryElement(Element element, T output, IMemberResolver memberResolver, SymbolTable scope, SymbolTable childScope, bool html5)
  {
    output.open( new TagDefinition(TagName.XMLNS, element.tagName.name) );

    // Render attributes.
    for (Attribute attribute in element.attributes)
    {
      String attributeValue = attribute.value.compute(memberResolver, scope).toString();

      if (attribute.name == "class") {
        // If is class, needs to go through classList so inliner will be applied.
        output.getClassList().setCssName(attributeValue);
      }
      else {
        output.attribute(attribute.name, attributeValue);
      }
    }

    renderElementChildren(element, output, memberResolver, childScope, html5);

    renderElementClose(output, element);
  }

  /** Abstract method. Write a text literal from the template source */
  @override
  void writeTextLiteral(T output, String text)
  {
    output.writeTextRawUnsafe(text);
  }

  /** Abstract method. Write an interpolated value, properly escaping */
  @override
  void writeInterpolatedValue(T output, Interpolation interpolation, dynamic value)
  {
    // We do not need to specially escape to avoid XSS as IDocumentAssembler will do this.
    output.write(value);
  }

  /** Render element close */
  @override
  void renderElementClose(T output, Element element)
  {
    output.close();
  }

  /** Abstract method. Called before render of child element */
  @override
  void beforeRenderChildElement(T output)
  {

  }
}
