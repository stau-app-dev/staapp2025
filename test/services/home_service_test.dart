import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:staapp2025/core/firebase_functions.dart' as fns;

void main() {
  test('fetchAnnouncements returns parsed list on success', () async {
    final mockResponse = json.encode({
      'data': [
        {'title': 'A', 'content': 'body A'},
        {'title': 'B', 'content': 'body B'},
      ],
    });
    final client = MockClient((request) async {
      return http.Response(mockResponse, 200);
    });

    final list = await fns.fetchAnnouncements(client: client);
    expect(list, isA<List<Map<String, String>>>());
    expect(list.length, 2);
    expect(list[0]['title'], 'A');
  });

  test('fetchVerseOfDay returns verse string when found', () async {
    final mockResponse = json.encode({
      'data': {'verseOfDay': 'A short verse'},
    });
    final client = MockClient((request) async {
      return http.Response(mockResponse, 200);
    });

    final v = await fns.fetchVerseOfDay(client: client);
    expect(v, 'A short verse');
  });

  test('fetchVerseOfDay returns null when no data', () async {
    final mockResponse = json.encode({'data': {}});
    final client = MockClient((request) async {
      return http.Response(mockResponse, 200);
    });

    final v = await fns.fetchVerseOfDay(client: client);
    expect(v, isNull);
  });
}
