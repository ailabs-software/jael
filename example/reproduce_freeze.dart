import 'dart:io';
import 'package:charcode/charcode.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:jael/jael.dart' as jael;
import 'package:symbol_table/symbol_table.dart';
import 'package:jael/src/codebuffer_renderer.dart';

main() {
  while (true) {
    int ch;
    print('Enter lines of Jael text, terminated by CTRL^D.');
    print('All environment variables are injected into the template scope.');

var buf =
'''
<div>
    <a class=\\"cta_btn\\">{{item.layoutModel.button}}</a>
    <ul>
        <li>{{item.itemId}}</li>
        <li>{{item.dataCardModel[\\"title\\"]}}</li>
        <li>
            <component name=\\"image\\" src=\\"https://media-dev.safetyhandler.com/media/video/mp4/bucket/7763bed03c6fcb7a723cb304fc81ff9a-0.mp4#500,500\\"></component>
        </li>
    </ul>
</div>
''';

    var document = jael.parseDocument(
      buf,
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
