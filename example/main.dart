import 'dart:io';
import 'package:charcode/charcode.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:symbol_table/symbol_table.dart';
import 'package:jael/jael.dart' as jael;
import 'package:jael/src/codebuffer_renderer.dart';

void main() {
  while (true) {
    var buf = StringBuffer();
    int ch;
    print('Enter lines of Jael text, terminated by CTRL^D.');
    print('All environment variables are injected into the template scope.');

    while ((ch = stdin.readByteSync()) != $eot && ch != -1) {
      buf.writeCharCode(ch);
    }

    var document = jael.parseDocument(
      buf.toString(),
      sourceUrl: 'stdin',
      onError: stderr.writeln,
    );

    if (document == null) {
      stderr.writeln('Could not parse the given text.');
    } else {
      var output = CodeBuffer();
      const CodeBufferRenderer().render(
        document,
        output,
        new SymbolTable<dynamic>(values: Platform.environment),
        strictResolution: false,
      );
      print('GENERATED HTML:\n$output');
    }
  }
}
