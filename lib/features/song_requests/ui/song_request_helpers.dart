import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/core/firebase_functions.dart' as fns;
import 'package:staapp2025/features/auth/auth_service.dart';

void snack(BuildContext context, String message, TextStyle style) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message, style: style)));
}

Future<void> reloadSongsInto(
  BuildContext context, {
  required void Function(Future<List<Map<String, dynamic>>> future) assign,
}) async {
  final auth = Provider.of<AuthService>(context, listen: false);
  final uid = auth.userId;
  final future = (uid == null || uid.isEmpty)
      ? Future.value(<Map<String, dynamic>>[])
      : fns.fetchSongs(userUuid: uid);
  assign(future);
  try {
    await future;
  } catch (_) {}
}
