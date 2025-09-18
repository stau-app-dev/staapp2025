import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
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

  GoogleSignInAccount? _user; // mobile (google_sign_in)
  GoogleSignInAccount? get user => _user;
  // Web uses FirebaseAuth; provide convenience getters so UI can stay the same.
  String? get _currentEmail {
    if (kIsWeb) return fb.FirebaseAuth.instance.currentUser?.email;
    return _user?.email;
  }

  // Public getters for UI code
  String? get email => _currentEmail;
  String? get displayName {
    if (kIsWeb) {
      final u = fb.FirebaseAuth.instance.currentUser;
      if (u == null) return null;
      final dn = u.displayName;
      if (dn != null && dn.trim().isNotEmpty) return dn;
      for (final p in u.providerData) {
        if (p.providerId == 'google.com' &&
            p.displayName != null &&
            p.displayName!.trim().isNotEmpty) {
          return p.displayName;
        }
      }
      return null;
    }
    return _user?.displayName;
  }

  String? get photoUrl {
    if (kIsWeb) {
      final u = fb.FirebaseAuth.instance.currentUser;
      if (u == null) return null;
      final ph = u.photoURL;
      if (ph != null && ph.isNotEmpty) return ph;
      for (final p in u.providerData) {
        if (p.providerId == 'google.com' &&
            p.photoURL != null &&
            p.photoURL!.isNotEmpty) {
          return p.photoURL;
        }
      }
      return null;
    }
    return _user?.photoUrl;
  }

  String? get userId =>
      kIsWeb ? (fb.FirebaseAuth.instance.currentUser?.uid) : _user?.id;

  /// The ID to use when calling our backend. On web prefer the Google provider
  /// UID (matches legacy google_sign_in id) and fall back to Firebase UID.
  /// On mobile, use GoogleSignInAccount.id.
  String? get backendUserId {
    if (kIsWeb) {
      return _webGoogleProviderUid ?? fb.FirebaseAuth.instance.currentUser?.uid;
    }
    return _user?.id;
  }

  // Helper: Google provider UID for web (matches legacy GoogleSignIn id)
  String? get _webGoogleProviderUid {
    final u = fb.FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    for (final p in u.providerData) {
      final puid = p.uid;
      if (p.providerId == 'google.com' && puid != null && puid.isNotEmpty) {
        return puid;
      }
    }
    return null;
  }

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
    email ??= _currentEmail;
    if (email != null) {
      final lower = email.toLowerCase().trim();
      if (lower.endsWith('ycdsb.ca')) return true;
      // explicitly ensure student domain is not treated as admin
      if (lower.endsWith('ycdsbk12.ca')) return false;
    }

    return false;
  }

  bool get isSignedIn =>
      kIsWeb ? (fb.FirebaseAuth.instance.currentUser != null) : (_user != null);

  bool _isAllowedEmail(String? email) {
    if (email == null) return false;
    final lower = email.toLowerCase().trim();
    return lower.endsWith('ycdsb.ca') || lower.endsWith('ycdsbk12.ca');
  }

  Future<void> init() async {
    if (kIsWeb) {
      // Web: rely on Firebase Auth session. Restore immediately if present.
      fb.FirebaseAuth.instance.authStateChanges().listen((fb.User? u) async {
        if (u != null) {
          // Enforce domain restriction
          final email = u.email;
          if (!_isAllowedEmail(email)) {
            debugPrint('[Auth] Web auth blocked for $email');
            await fb.FirebaseAuth.instance.signOut();
            _remoteUser = null;
            notifyListeners();
            return;
          }
          try {
            final providerUid = _webGoogleProviderUid;
            final backendId = providerUid ?? u.uid;
            String name = u.displayName ?? '';
            if (name.trim().isEmpty) {
              for (final p in u.providerData) {
                if (p.providerId == 'google.com' &&
                    p.displayName != null &&
                    p.displayName!.trim().isNotEmpty) {
                  name = p.displayName!;
                  break;
                }
              }
            }
            final remote = await getUser(
              id: backendId,
              email: email ?? '',
              name: name,
            );
            _remoteUser = remote;
          } catch (e) {
            debugPrint('[Auth] getUser (web) failed: $e');
            _remoteUser = null;
          }
        } else {
          _remoteUser = null;
        }
        notifyListeners();
      });
      // No-op: state will arrive via authStateChanges; if a session exists,
      // currentUser is non-null immediately.
      return;
    }

    // Mobile: keep google_sign_in behavior (silent + listener)
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      _user = account;
      if (account != null) {
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

    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
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
      if (kIsWeb) {
        final provider = fb.GoogleAuthProvider();
        bool useRedirect = false;
        try {
          final prefs = await SharedPreferences.getInstance();
          useRedirect = prefs.getBool('useWebRedirect') ?? false;
        } catch (_) {}
        if (useRedirect) {
          await fb.FirebaseAuth.instance.signInWithRedirect(provider);
          return;
        }
        fb.UserCredential cred;
        try {
          cred = await fb.FirebaseAuth.instance.signInWithPopup(provider);
        } catch (e) {
          // Popup blocked or not allowed – remember and fall back to redirect next time
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('useWebRedirect', true);
          } catch (_) {}
          await fb.FirebaseAuth.instance.signInWithRedirect(provider);
          // Return here; the flow will resume on redirect landing.
          return;
        }
        final u = cred.user;
        if (u == null) throw Exception('Sign in failed');
        if (!_isAllowedEmail(u.email)) {
          await fb.FirebaseAuth.instance.signOut();
          throw Exception('Use your ycdsb.ca or ycdsbk12.ca email.');
        }
        // Web state will propagate via authStateChanges listener.
        if (kIsWeb) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('wasSignedIn', true);
          } catch (_) {}
        }
        notifyListeners();
        return;
      }

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
      // Mark that this origin had a successful sign-in so future web boots can
      // attempt silent sign-in without user interaction.
      // Mobile path already persisted via shared_prefs earlier (kept here if needed)
      if (!kIsWeb) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('wasSignedIn', true);
        } catch (_) {}
      }
      notifyListeners();
    } catch (e, st) {
      debugPrint('[Auth] signInWithGoogle error: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (kIsWeb) {
      await fb.FirebaseAuth.instance.signOut();
    } else {
      await _googleSignIn.signOut();
      _user = null;
    }
    _remoteUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wasSignedIn', false);
    } catch (_) {}
    notifyListeners();
  }

  /// Re-fetches the remote user record for the currently signed-in Google
  /// account and updates the cached `_remoteUser`. Safe to call when not
  /// signed-in (it will do nothing).
  Future<void> refreshRemoteUser() async {
    if (kIsWeb) {
      final u = fb.FirebaseAuth.instance.currentUser;
      if (u == null) return;
      try {
        final providerUid = _webGoogleProviderUid;
        final backendId = providerUid ?? u.uid;
        String name = u.displayName ?? '';
        if (name.trim().isEmpty) {
          for (final p in u.providerData) {
            if (p.providerId == 'google.com' &&
                p.displayName != null &&
                p.displayName!.trim().isNotEmpty) {
              name = p.displayName!;
              break;
            }
          }
        }
        final remote = await getUser(
          id: backendId,
          email: u.email ?? '',
          name: name,
        );
        _remoteUser = remote;
        notifyListeners();
      } catch (e) {
        debugPrint('[Auth] refreshRemoteUser (web) failed: $e');
      }
      return;
    }
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
