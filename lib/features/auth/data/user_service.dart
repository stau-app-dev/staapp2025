import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches or creates the user record from the backend. Expects query
/// parameters: id, email, name. Returns the remote user map.
Future<Map<String, dynamic>> getUser({
  required String id,
  required String email,
  required String name,
  http.Client? client,
}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getUser?id=$id&email=$email&name=$name',
  );

  final resp = await client.get(url).timeout(const Duration(seconds: 6));
  if (resp.statusCode != 200) {
    try {
      final parsed = json.decode(resp.body);
      final msg = parsed is Map && parsed['error'] != null
          ? parsed['error'].toString()
          : resp.body.toString();
      throw Exception(msg);
    } catch (_) {
      throw Exception(resp.body.toString());
    }
  }

  try {
    final parsed = json.decode(resp.body);
    if (parsed is Map &&
        parsed['data'] is Map &&
        parsed['data']['user'] is Map) {
      return Map<String, dynamic>.from(parsed['data']['user'] as Map);
    }
    throw Exception('Unexpected response from getUser: ${resp.body}');
  } catch (e) {
    throw Exception('Failed to parse getUser response: ${e.toString()}');
  }
}

/// Updates a field on the remote user document via updateUserField cloud
/// function. Returns the updated user map on success.
Future<Map<String, dynamic>> updateUserField({
  required String id,
  required String field,
  required dynamic value,
  http.Client? client,
}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/updateUserField',
  );

  final body = json.encode({'id': id, 'field': field, 'value': value});

  final resp = await client
      .post(url, headers: {'Content-Type': 'text/plain'}, body: body)
      .timeout(const Duration(seconds: 8));

  if (resp.statusCode != 200) {
    try {
      final parsed = json.decode(resp.body);
      final msg = parsed is Map && parsed['error'] != null
          ? parsed['error'].toString()
          : resp.body.toString();
      throw Exception(msg);
    } catch (_) {
      throw Exception(resp.body.toString());
    }
  }

  try {
    final parsed = json.decode(resp.body);
    if (parsed is Map &&
        parsed['data'] is Map &&
        parsed['data']['user'] is Map) {
      return Map<String, dynamic>.from(parsed['data']['user'] as Map);
    }
    throw Exception('Unexpected response from updateUserField: ${resp.body}');
  } catch (e) {
    throw Exception(
      'Failed to parse updateUserField response: ${e.toString()}',
    );
  }
}
