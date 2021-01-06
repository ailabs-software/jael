import 'dart:math';
import 'package:code_buffer/code_buffer.dart';
import 'package:jclosure/structs/symbols/symbol_table/SymbolTable.dart' show SymbolTable;
import 'package:jael/jael.dart' as jael;
import 'package:jael/src/codebuffer_renderer.dart';
import 'package:test/test.dart';

void main() {
  test('render into div', () {
    var template = '''
    <div>
      <element name="square-root">
        The square root of {{ n }} is {{ sqrt(n).toInt() }}.
      </element>
      <square-root @n=16 />
    </div>
    ''';

    String html = render(template, <String, dynamic>{'sqrt': sqrt});
    print(html);

    expect(
        html,
        '''
<div>
  <div>
    The square root of 16 is 4.
  </div>
</div>
    '''
            .trim());
  });

  test('render into explicit tag name', () {
    var template = '''
    <div>
      <element name="square-root">
        The square root of {{ n }} is {{ sqrt(n).toInt() }}.
      </element>
      <square-root as="span" @n=16 />
    </div>
    ''';

    var html = render(template, <String, dynamic>{'sqrt': sqrt});
    print(html);

    expect(
        html,
        '''
<div>
  <span>
    The square root of 16 is 4.
  </span>
</div>
    '''
            .trim());
  });

  test('pass attributes', () {
    var template = '''
    <div>
      <element name="square-root">
        The square root of {{ n }} is {{ sqrt(n).toInt() }}.
      </element>
      <square-root foo="bar" baz="quux" @n=16 />
    </div>
    ''';

    var html = render(template, <String, dynamic>{'sqrt': sqrt});
    print(html);

    expect(
        html,
        '''
<div>
  <div foo="bar" baz="quux">
    The square root of 16 is 4.
  </div>
</div>
    '''
            .trim());
  });

  test('render without tag name', () {
    var template = '''
    <div>
      <element name="square-root">
        The square root of {{ n }} is {{ sqrt(n).toInt() }}.
      </element>
      <square-root as=false @n=16 />
    </div>
    ''';

    var html = render(template, <String, dynamic>{'sqrt': sqrt});
    print(html);

    expect(
        html,
        '''
<div>
  The square root of 16 is 4.
      
</div>
    '''
            .trim());
  });
}

String render(String template, [Map<String, dynamic> values]) {
  var doc = jael.parseDocument(template, onError: (e) => throw e);
  var buffer = CodeBuffer();
  const CodeBufferRenderer().render(doc, buffer, new SymbolTable<dynamic>(values: values));
  return buffer.toString();
}
