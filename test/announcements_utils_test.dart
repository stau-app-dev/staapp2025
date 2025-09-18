import 'package:flutter_test/flutter_test.dart';
import 'package:staapp2025/widgets/homeblocks/homeblocks.dart';

void main() {
  test('decodeHtmlEntities handles common entities', () {
    final input = 'Fish &amp; Chips &lt;3 &quot;quote&quot; &#39;apos&#39;';
    final out = decodeHtmlEntities(input);
    expect(out, contains('&'));
    expect(out, contains('<'));
    expect(out, contains('"'));
    expect(out, contains("'"));
  });

  test('parseAnnouncementsFromJson extracts items', () {
    final json = {
      'data': [
        {'title': 'One', 'content': 'First'},
        {'title': '', 'content': 'Second'},
      ],
    };
    final parsed = parseAnnouncementsFromJson(json);
    expect(parsed.length, 2);
    expect(parsed[0]['title'], 'One');
    expect(parsed[1]['body'], 'Second');
  });
}
