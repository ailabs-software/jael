import 'dart:io';
import 'package:charcode/charcode.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:jael/jael.dart' as jael;
import 'package:symbol_table/symbol_table.dart';
import 'package:jael/src/codebuffer_renderer.dart';

main() {

  String s =
    '<div><img class=\"mrfreeze\"></div>';

  print("BEGIN parsing");

    var document = jael.parseDocument(
      s,
      sourceUrl: 'stdin',
      onError: stderr.writeln,
    );

  print("END parsing");

var output = CodeBuffer();
      const CodeBufferRenderer().render(
        document,
        output,
        new SymbolTable<dynamic>(values: Platform.environment),
        strictResolution: false,
      );
      print('GENERATED HTML:\n$output');


}

