import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/features/auth/auth_service.dart';
import 'package:staapp2025/features/auth/ui/login_page.dart';

/// Ensures a user is signed in. If not, shows the login page and returns
/// whether the user ended up signed in.
Future<bool> ensureSignedIn(BuildContext context) async {
  // Capture auth before any async gap; we only navigate if not signed in.
  final auth = Provider.of<AuthService>(context, listen: false);
  if (auth.isSignedIn) return true;
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  // After returning, rely on the same auth instance; if widget unmounted, fail.
  if (!context.mounted) return false;
  return auth.isSignedIn;
}

/// Pushes a route only if the user is signed in, otherwise routes to login
/// and then pushes the route if sign-in completes.
Future<bool> pushIfSignedIn(BuildContext context, Widget page) async {
  final ok = await ensureSignedIn(context);
  if (!ok) return false;
  if (!context.mounted) return false;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  return true;
}
