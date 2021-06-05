import 'package:source_span/source_span.dart';

/** @fileoverview Caches expensive operation of splitting text from source file text to get token text, which is commonly done by Jael runtime (renderer).
 *
 *    Without this optimisation, rendering a content card template takes an average of 12.13ms.
 *
 *    With this optimisation in place, rendering a content template takes an average of 6.06ms.
 *
 *    In a brochure with 5 content cards, this saves 30ms to render that brochure.
 *
 * */

class CachingFileSpan
{
  final FileSpan? _fileSpan;

  String? _textCache;

  CachingFileSpan(FileSpan? this._fileSpan);

  String get text
  {
    if (_textCache == null) {
      _textCache = _fileSpan!.text;
    }
    return _textCache!;
  }

  FileLocation get start
  {
    return _fileSpan!.start;
  }

  FileLocation get end
  {
    return _fileSpan!.end;
  }

  int get length
  {
    return _fileSpan!.length;
  }

  CachingFileSpan expand(CachingFileSpan other)
  {
    return new CachingFileSpan( _fileSpan!.expand(other._fileSpan!) );
  }

  String highlight({dynamic color})
  {
    return _fileSpan!.highlight(color: color);
  }
}