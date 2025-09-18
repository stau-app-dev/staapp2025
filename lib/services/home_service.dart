import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:staapp2025/widgets/homeblocks/homeblocks.dart';

/// Fetches announcements from the cloud function and returns a parsed list.
/// Accepts an optional [client] for testability.
Future<List<Map<String, String>>> fetchAnnouncements({
  http.Client? client,
}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getGeneralAnnouncements',
  );
  final resp = await client.get(url).timeout(Duration(seconds: 6));
  if (resp.statusCode != 200) throw Exception('Failed to load announcements');
  final body = json.decode(resp.body);
  return parseAnnouncementsFromJson(body);
}

/// Fetches verse of the day. Returns the verse text or null when not found.
Future<String?> fetchVerseOfDay({http.Client? client}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getVerseOfDay',
  );
  final resp = await client.get(url).timeout(Duration(seconds: 6));
  if (resp.statusCode != 200) throw Exception('Failed to load verse');
  final body = json.decode(resp.body);
  if (body is Map && body['data'] is Map) {
    final data = body['data'] as Map;
    final v = data['verseOfDay'];
    return v?.toString();
  }
  return null;
}

/// Fetches spirit meter numbers for each grade and returns the inner `data` map
/// which should contain keys like 'nine', 'ten', 'eleven', 'twelve'.
Future<Map<String, dynamic>> fetchSpiritMeters({http.Client? client}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getSpiritMeters',
  );
  final resp = await client.get(url).timeout(Duration(seconds: 6));
  if (resp.statusCode != 200) throw Exception('Failed to load spirit meters');
  final body = json.decode(resp.body);
  if (body is Map && body['data'] is Map) {
    return Map<String, dynamic>.from(body['data'] as Map);
  }
  return <String, dynamic>{};
}

/// Fetches the day number and returns it as an int if present, otherwise null.
Future<int?> fetchDayNumber({http.Client? client}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getDayNumber',
  );
  final resp = await client.get(url).timeout(Duration(seconds: 6));
  if (resp.statusCode != 200) throw Exception('Failed to load day number');
  final body = json.decode(resp.body);
  if (body is Map && body['data'] is Map) {
    final data = body['data'] as Map;
    final dn = data['dayNumber'];
    if (dn is int) return dn;
    if (dn is String) return int.tryParse(dn);
  }
  return null;
}

/// Fetches the announcement submission form URL from the cloud function.
/// Returns the formUrl string or null if not present.
Future<String?> fetchAnnouncementFormUrl({http.Client? client}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getAnnouncementFormUrl',
  );
  final resp = await client.get(url).timeout(Duration(seconds: 6));
  if (resp.statusCode != 200) throw Exception('Failed to load form url');
  final body = json.decode(resp.body);
  if (body is Map && body['data'] is Map) {
    final data = body['data'] as Map;
    final fu = data['formUrl'];
    return fu?.toString();
  }
  return null;
}

/// Fetches the song requests list from the cloud function and returns a list
/// of parsed song maps. Each map will contain keys: 'artist', 'name',
/// 'creatorEmail', 'createdAt' (as Map), 'upvotes' (int), and 'id'.
Future<List<Map<String, dynamic>>> fetchSongs({http.Client? client}) async {
  client ??= http.Client();
  // Add a cache-busting query param to avoid any intermediary caching on web
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getSongs?t=${DateTime.now().millisecondsSinceEpoch}',
  );
  final resp = await client
      .get(
        url,
        headers: {
          'Cache-Control': 'no-cache, no-store, max-age=0',
          'Pragma': 'no-cache',
        },
      )
      .timeout(Duration(seconds: 12));
  if (resp.statusCode != 200) throw Exception('Failed to load songs');
  final body = json.decode(resp.body);
  if (body is Map && body['data'] is List) {
    final list = body['data'] as List;
    return list
        .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
        .toList();
  }
  return <Map<String, dynamic>>[];
}

/// Submits a new song to the addSong cloud function. Returns the created
/// song map on success. Throws an exception on failure.
Future<Map<String, dynamic>> submitSong({
  required String artist,
  required String name,
  required String creatorEmail,
  http.Client? client,
}) async {
  client ??= http.Client();
  // Use the new cloud function which enforces per-user request limits
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/addSongNew',
  );

  final body = json.encode({
    'artist': artist,
    'name': name,
    'creatorEmail': creatorEmail,
  });

  // The server-side cloud function expects req.body to be a raw JSON string
  // (it calls JSON.parse(req.body)). To avoid the function receiving a
  // pre-parsed object (which would make JSON.parse fail with "Unexpected
  // token o..."), send the payload as plain text so the function receives
  // the raw string.
  final resp = await client
      .post(url, headers: {'Content-Type': 'text/plain'}, body: body)
      // Increase timeout to better tolerate cold starts on the backend
      .timeout(Duration(seconds: 20));

  if (resp.statusCode != 200) {
    // Try to decode JSON error body if possible, otherwise return raw body
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
    if (parsed is Map && parsed['data'] is Map) {
      // New function returns { data: { message, song } }
      final data = parsed['data'] as Map;
      if (data['song'] is Map) {
        return Map<String, dynamic>.from(data['song'] as Map);
      }
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Unexpected response from addSongNew: ${resp.body}');
  } catch (e) {
    throw Exception('Failed to parse addSongNew response: ${e.toString()}');
  }
}

/// Upvotes a song using the new cloud function. Requires the song id and the
/// user's email. Throws on failure.
Future<Map<String, dynamic>> upvoteSong({
  required String songId,
  required String userEmail,
  http.Client? client,
}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/upvoteSongNew',
  );

  final body = json.encode({'songId': songId, 'userEmail': userEmail});

  final resp = await client
      .post(url, headers: {'Content-Type': 'text/plain'}, body: body)
      // Increase timeout to better tolerate cold starts on the backend
      .timeout(Duration(seconds: 20));

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
    if (parsed is Map && parsed['data'] is Map) {
      return Map<String, dynamic>.from(parsed['data'] as Map);
    }
    return <String, dynamic>{};
  } catch (e) {
    throw Exception('Failed to parse upvoteSongNew response: ${e.toString()}');
  }
}

/// Deletes a song by id by calling the deleteSong cloud function.
/// Returns the parsed response data on success.
Future<Map<String, dynamic>> deleteSong({
  required String id,
  http.Client? client,
}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/deleteSong',
  );

  final body = json.encode({'id': id});

  final resp = await client
      .post(url, headers: {'Content-Type': 'text/plain'}, body: body)
      // Increase timeout to better tolerate cold starts on the backend
      .timeout(Duration(seconds: 20));

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
    if (parsed is Map && parsed['data'] is Map) {
      return Map<String, dynamic>.from(parsed['data'] as Map);
    }
    return <String, dynamic>{};
  } catch (e) {
    throw Exception('Failed to parse deleteSong response: ${e.toString()}');
  }
}

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

  final resp = await client.get(url).timeout(Duration(seconds: 6));
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
      .timeout(Duration(seconds: 8));

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
