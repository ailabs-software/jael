import 'package:jclosure/structs/symbols/symbol_table/SymbolTable.dart';
import "member_resolver.dart";
import "ast/ast.dart";
import "parse_document.dart";
import "renderer.dart";

/** @fileoverview Manages static renderer state */

class RendererManager<T extends StringSink> {
  // Renderer
  final Renderer<T> _renderer;

  IMemberResolver? _memberResolver;

  // Cache
  Map<String, Document?> _documentCache = <String, Document?>{};

  RendererManager(Renderer<T> this._renderer);

  /** Set member resolver */
  void setMemberResolver(IMemberResolver memberResolver)
  {
    _memberResolver = memberResolver;
  }

  /** Clear cache */
  void clearCache()
  {
    _documentCache.clear();
  }

  /** Renders template */
  void render(T output, String templateText, SymbolTable<dynamic> symbolTable)
  {
    Document document = _getDocumentCached(templateText)!;

    _renderer.render(
      document,
      output,
      symbolTable,
      memberResolver: _memberResolver);
  }

  /** First tries to obtain document from cache, then parses and caches if not.
   *  CAUTION: This can cause a memory leak if the template text changes dynamically. */
  Document? _getDocumentCached(String templateText)
  {
    if ( !_documentCache.containsKey(templateText) ) {
      print("Jael renderer manager: adding template to cache.");
      _documentCache[templateText] = parseDocument(templateText);
    }
    return _documentCache[templateText];
  }
}
