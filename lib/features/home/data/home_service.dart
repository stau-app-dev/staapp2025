import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:staapp2025/features/home/ui/homeblocks.dart';
import 'package:staapp2025/features/song_requests/data/song_requests_service.dart'
    as song_data;
import 'package:staapp2025/features/auth/data/user_service.dart' as user_data;

/// Fetches announcements from the cloud function and returns a parsed list.
/// Accepts an optional [client] for testability.
Future<List<Map<String, String>>> fetchAnnouncements({
  http.Client? client,
}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getGeneralAnnouncements?t=${DateTime.now().millisecondsSinceEpoch}',
  );
  final resp = await client.get(url).timeout(Duration(seconds: 10));
  if (resp.statusCode != 200) throw Exception('Failed to load announcements');
  final body = json.decode(resp.body);
  return parseAnnouncementsFromJson(body);
}

/// Fetches verse of the day. Returns the verse text or null when not found.
Future<String?> fetchVerseOfDay({http.Client? client}) async {
  client ??= http.Client();
  final url = Uri.parse(
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getVerseOfDay?t=${DateTime.now().millisecondsSinceEpoch}',
  );
  final resp = await client.get(url).timeout(Duration(seconds: 10));
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
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getSpiritMeters?t=${DateTime.now().millisecondsSinceEpoch}',
  );
  final resp = await client.get(url).timeout(Duration(seconds: 10));
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
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getDayNumber?t=${DateTime.now().millisecondsSinceEpoch}',
  );
  final resp = await client.get(url).timeout(Duration(seconds: 10));
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
    'https://us-central1-staugustinechsapp.cloudfunctions.net/getAnnouncementFormUrl?t=${DateTime.now().millisecondsSinceEpoch}',
  );
  final resp = await client.get(url).timeout(Duration(seconds: 10));
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
Future<List<Map<String, dynamic>>> fetchSongs({http.Client? client}) =>
    song_data.fetchSongs(client: client);

/// Submits a new song to the addSong cloud function. Returns the created
/// song map on success. Throws an exception on failure.
Future<Map<String, dynamic>> submitSong({
  required String artist,
  required String name,
  required String creatorEmail,
  http.Client? client,
}) => song_data.submitSong(
  artist: artist,
  name: name,
  creatorEmail: creatorEmail,
  client: client,
);

/// Upvotes a song using the new cloud function. Requires the song id and the
/// user's email. Throws on failure.
Future<Map<String, dynamic>> upvoteSong({
  required String songId,
  required String userEmail,
  http.Client? client,
}) =>
    song_data.upvoteSong(songId: songId, userEmail: userEmail, client: client);

/// Deletes a song by id by calling the deleteSong cloud function.
/// Returns the parsed response data on success.
Future<Map<String, dynamic>> deleteSong({
  required String id,
  http.Client? client,
}) => song_data.deleteSong(id: id, client: client);

/// Fetches or creates the user record from the backend. Expects query
/// parameters: id, email, name. Returns the remote user map.
Future<Map<String, dynamic>> getUser({
  required String id,
  required String email,
  required String name,
  http.Client? client,
}) => user_data.getUser(id: id, email: email, name: name, client: client);

/// Updates a field on the remote user document via updateUserField cloud
/// function. Returns the updated user map on success.
Future<Map<String, dynamic>> updateUserField({
  required String id,
  required String field,
  required dynamic value,
  http.Client? client,
}) => user_data.updateUserField(
  id: id,
  field: field,
  value: value,
  client: client,
);
