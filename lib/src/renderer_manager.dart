import 'package:symbol_table/symbol_table.dart';
import "member_resolver.dart";
import "ast/ast.dart";
import "parse_document.dart";
import "renderer.dart";

/** @fileoverview Manages static renderer state */

typedef String _FileReadCallbackStrategy(String fileName);

class RendererManager<T extends StringSink> {
  // Renderer
  final Renderer<T> _renderer;

  // State
  String _basePath; // Null so that must be configured.

  _FileReadCallbackStrategy _fileReadStrategy;

  IMemberResolver _memberResolver;

  RendererManager(Renderer<T> this._renderer);

  /** Do not use user input to determine base path */
  void setBasePath(String basePath)
  {
    if ( !_basePath.endsWith("/") ) {
      throw new Exception("Base path must end with trialing /");
    }
    _basePath = basePath;
  }

  /** Sets file read strategy */
  void setFileReadStrategy(_FileReadCallbackStrategy fileReadStrategy)
  {
    _fileReadStrategy = fileReadStrategy;
  }

  /** Set member resolver */
  void setMemberResolver(IMemberResolver memberResolver)
  {
    _memberResolver = memberResolver;
  }

  /** Render to output */
  void renderFile(T output, String fileName, SymbolTable<dynamic> symbolTable)
  {
    Document document = _getDocument(fileName);

    _renderer.render(
      document,
      output,
      symbolTable,
      memberResolver: _memberResolver);
  }

  /** Reads document. TODO: Cache this! */
  Document _getDocument(String fileName)
  {
    String templateText = _fileReadStrategy( _getFullPath(fileName) );

    return parseDocument(templateText);
  }

  /** Get full path */
  String _getFullPath(String fileName)
  {
    if ( fileName.contains("..") ) {
      throw new Exception();
    }

    return _basePath + fileName;
  }
}
