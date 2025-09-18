import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:provider/provider.dart';
import 'services/home_service.dart';

class AuthService extends ChangeNotifier {
  // Pass the Web client ID only for web builds; mobile uses platform configs.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '448336593725-hf3ebb7vnfsn8gttr26tnefk051i2fis.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );

  GoogleSignInAccount? _user;
  GoogleSignInAccount? get user => _user;

  Map<String, dynamic>? _remoteUser;
  Map<String, dynamic>? get remoteUser => _remoteUser;

  bool get isAdmin {
    // Admin rules:
    // - If remote user `status` is a number > 0, they are admin.
    // - Otherwise, any email that ends with 'ycdsb.ca' is considered an admin (teachers).
    // - Emails ending with 'ycdsbk12.ca' are NOT admins by default unless status > 0.

    // 1) Check remote status first
    final s = _remoteUser?['status'];
    if (s is int) return s > 0;
    if (s is String) {
      final parsed = int.tryParse(s);
      if (parsed != null) return parsed > 0;
    }

    // 2) Fallback to email domain check
    String? email = _remoteUser?['email'] as String?;
    email ??= _user?.email;
    if (email != null) {
      final lower = email.toLowerCase().trim();
      if (lower.endsWith('ycdsb.ca')) return true;
      // explicitly ensure student domain is not treated as admin
      if (lower.endsWith('ycdsbk12.ca')) return false;
    }

    return false;
  }

  bool get isSignedIn => _user != null;

  bool _isAllowedEmail(String? email) {
    if (email == null) return false;
    final lower = email.toLowerCase().trim();
    return lower.endsWith('ycdsb.ca') || lower.endsWith('ycdsbk12.ca');
  }

  Future<void> init() async {
    // When the Google account changes (sign in/out), update local state and
    // refresh the remote user profile.
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      _user = account;
      if (account != null) {
        // Enforce domain restriction
        if (!_isAllowedEmail(account.email)) {
          debugPrint('[Auth] Disallowed domain attempted: ${account.email}');
          try {
            await _googleSignIn.disconnect();
          } catch (_) {}
          _user = null;
          _remoteUser = null;
          notifyListeners();
          return;
        }
        try {
          final u = await getUser(
            id: account.id,
            email: account.email,
            name: account.displayName ?? '',
          );
          _remoteUser = u;
        } catch (e) {
          debugPrint('[Auth] getUser onCurrentUserChanged failed: $e');
          _remoteUser = null;
        }
      } else {
        _remoteUser = null;
      }
      notifyListeners();
    });

    // Try silent sign-in and, if successful, fetch remote user immediately.
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        // Enforce domain restriction on silent sign-in as well
        if (!_isAllowedEmail(account.email)) {
          debugPrint('[Auth] Silent sign-in blocked for ${account.email}');
          try {
            await _googleSignIn.disconnect();
          } catch (_) {}
          _user = null;
          _remoteUser = null;
          notifyListeners();
          return;
        }
        _user = account;
        try {
          final u = await getUser(
            id: account.id,
            email: account.email,
            name: account.displayName ?? '',
          );
          _remoteUser = u;
        } catch (e) {
          debugPrint('[Auth] getUser signInSilently failed: $e');
          _remoteUser = null;
        }
      } else {
        _user = null;
      }
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('[Auth] Starting Google sign-in');
      final account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint(
          '[Auth] GoogleSignIn returned null account (user cancelled or no account)',
        );
        throw Exception('Sign in aborted by user or no accounts available');
      }
      debugPrint(
        '[Auth] Signed in account: ${account.displayName} (${account.email})',
      );

      // Enforce domain restriction before proceeding
      if (!_isAllowedEmail(account.email)) {
        debugPrint(
          '[Auth] Blocking sign-in for disallowed domain: ${account.email}',
        );
        try {
          await _googleSignIn.disconnect();
        } catch (_) {}
        throw Exception('Use your ycdsb.ca or ycdsbk12.ca email.');
      }

      // Try to obtain authentication tokens (idToken/accessToken) which
      // can reveal issues with OAuth client configuration (missing SHA etc.)
      try {
        final auth = await account.authentication;
        debugPrint(
          '[Auth] Retrieved tokens: idToken=${auth.idToken != null}, accessToken=${auth.accessToken != null}',
        );
        // Avoid printing raw tokens in logs for security, but report length
        if (auth.idToken != null) {
          debugPrint('[Auth] idToken length=${auth.idToken!.length}');
        }
        if (auth.accessToken != null) {
          debugPrint('[Auth] accessToken length=${auth.accessToken!.length}');
        }
      } catch (tokenErr, stack) {
        debugPrint('[Auth] Failed to retrieve tokens: $tokenErr');
        debugPrint(stack.toString());
      }

      _user = account;
      // fetch remote user profile and cache it
      try {
        final u = await getUser(
          id: account.id,
          email: account.email,
          name: account.displayName ?? '',
        );
        _remoteUser = u;
      } catch (e) {
        // ignore remote fetch errors but log
        debugPrint('[Auth] getUser failed: $e');
      }
      notifyListeners();
    } catch (e, st) {
      debugPrint('[Auth] signInWithGoogle error: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _user = null;
    _remoteUser = null;
    notifyListeners();
  }

  /// Re-fetches the remote user record for the currently signed-in Google
  /// account and updates the cached `_remoteUser`. Safe to call when not
  /// signed-in (it will do nothing).
  Future<void> refreshRemoteUser() async {
    final acct = _user;
    if (acct == null) return;
    try {
      final u = await getUser(
        id: acct.id,
        email: acct.email,
        name: acct.displayName ?? '',
      );
      _remoteUser = u;
      notifyListeners();
    } catch (e) {
      debugPrint('[Auth] refreshRemoteUser failed: $e');
    }
  }
}
