import 'package:source_span/source_span.dart';

/** @fileoverview Caches expensive operation of splitting text from source file to get token text, which is commonly done by Jael runtime */

class CachingFileSpan
{
  final FileSpan _fileSpan;

  String _textCache;

  CachingFileSpan(FileSpan this._fileSpan);

  String get text
  {
    if (_textCache == null) {
      _textCache = _fileSpan.text;
    }
    return _textCache;
  }

  FileLocation get start
  {
    return _fileSpan.start;
  }

  FileLocation get end
  {
    return _fileSpan.end;
  }

  int get length
  {
    return _fileSpan.length;
  }

  CachingFileSpan expand(CachingFileSpan other)
  {
    return new CachingFileSpan( _fileSpan.expand(other._fileSpan) );
  }

  String highlight({dynamic color})
  {
    return _fileSpan.highlight(color: color);
  }
}