import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:staapp2025/services/home_service.dart';

void main() {
  test('fetchSpiritMeters returns map with grade keys', () async {
    final mockResponse = json.encode({
      'data': {'nine': 42, 'ten': 55, 'eleven': 63, 'twelve': 21},
    });
    final client = MockClient((request) async {
      return http.Response(mockResponse, 200);
    });

    final map = await fetchSpiritMeters(client: client);
    expect(map['nine'], 42);
    expect(map['ten'], 55);
    expect(map['eleven'], 63);
    expect(map['twelve'], 21);
  });

  test('fetchDayNumber returns integer when present', () async {
    final mockResponse = json.encode({
      'data': {'dayNumber': 2},
    });
    final client = MockClient((request) async {
      return http.Response(mockResponse, 200);
    });

    final dn = await fetchDayNumber(client: client);
    expect(dn, 2);
  });
}
