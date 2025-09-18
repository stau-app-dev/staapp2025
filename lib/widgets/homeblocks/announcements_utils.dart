// Utilities for announcements parsing and helpers.

String decodeHtmlEntities(String input) {
  return input
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}

List<Map<String, String>> parseAnnouncementsFromJson(dynamic body) {
  final parsed = <Map<String, String>>[];
  if (body is Map && body['data'] is List) {
    final List data = body['data'];
    for (final item in data) {
      if (item is Map) {
        final title = (item['title'] ?? '').toString();
        final content = (item['content'] ?? '').toString();
        if (title.isNotEmpty || content.isNotEmpty) {
          parsed.add({
            'title': decodeHtmlEntities(title),
            'body': decodeHtmlEntities(content),
          });
        }
      }
    }
  }
  return parsed;
}
