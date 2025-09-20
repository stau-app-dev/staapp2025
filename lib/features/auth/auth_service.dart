import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart' as fcore;
import 'package:firebase_auth/firebase_auth.dart' as fb;
// Replace legacy services import with the new auth data service
import 'package:staapp2025/features/auth/data/user_service.dart';

class AuthService extends ChangeNotifier {
  // Ensure Firebase is initialized before using any Firebase services.
  Future<void> _ensureFirebaseInitialized() async {
    // On web, initialization must be done with options in main().
    if (kIsWeb) return;
    if (fcore.Firebase.apps.isNotEmpty) return;
    try {
      await fcore.Firebase.initializeApp();
      return;
    } catch (_) {
      // Ignore and retry briefly below.
    }
    // Retry for up to ~3 seconds in case of early-startup plugin registration races.
    for (int i = 0; i < 30; i++) {
      if (fcore.Firebase.apps.isNotEmpty) return;
      try {
        await fcore.Firebase.initializeApp();
        if (fcore.Firebase.apps.isNotEmpty) return;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Firebase user is the source of truth on all platforms.
  fb.User? get _fbUser {
    if (fcore.Firebase.apps.isEmpty) return null;
    return fb.FirebaseAuth.instance.currentUser;
  }

  String? get _currentEmail => _fbUser?.email;

  // Legacy GoogleSignInAccount state removed; FirebaseAuth is canonical.

  // Public getters for UI code
  String? get email => _currentEmail;
  String? get displayName {
    final u = _fbUser;
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

  String? get photoUrl {
    final u = _fbUser;
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

  String? get userId => _fbUser?.uid;

  /// The ID to use when calling our backend. On web prefer the Google provider
  /// UID (matches legacy google_sign_in id) and fall back to Firebase UID.
  /// On mobile, use GoogleSignInAccount.id.
  String? get backendUserId {
    return _webGoogleProviderUid ?? _fbUser?.uid;
  }

  // Helper: Google provider UID for web (matches legacy GoogleSignIn id)
  String? get _webGoogleProviderUid {
    final u = _fbUser;
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

  // Typed accessors for counters used in the UI
  int? get songRequestCount {
    final v = _remoteUser?['songRequestCount'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  int? get songUpvoteCount {
    final v = _remoteUser?['songUpvoteCount'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

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

  bool get isSignedIn => _fbUser != null;

  bool _isAllowedEmail(String? email) {
    if (email == null) return false;
    final lower = email.toLowerCase().trim();
    return lower.endsWith('ycdsb.ca') || lower.endsWith('ycdsbk12.ca');
  }

  Future<void> init() async {
    // Wait until a default Firebase app exists before touching FirebaseAuth.
    if (fcore.Firebase.apps.isEmpty) {
      // First, try to initialize quickly (mobile/desktop). On web, main()
      // does initialization with options, so we just wait.
      await _ensureFirebaseInitialized();
    }
    for (int i = 0; i < 40 && fcore.Firebase.apps.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (fcore.Firebase.apps.isEmpty) {
      debugPrint(
        '[Auth] Firebase not initialized yet; deferring auth listener',
      );
      // Try again shortly without throwing.
      Future.delayed(const Duration(milliseconds: 200), init);
      return;
    }
    final auth = fb.FirebaseAuth.instance;
    auth.authStateChanges().listen((fb.User? u) async {
      if (u != null) {
        // Enforce domain restriction
        final email = u.email;
        if (!_isAllowedEmail(email)) {
          debugPrint('[Auth] Auth blocked for $email');
          await auth.signOut();
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
          try {
            final rc = _remoteUser?['songRequestCount'];
            final uc = _remoteUser?['songUpvoteCount'];
            debugPrint('[Auth] remoteUser fetched: requests=$rc, upvotes=$uc');
          } catch (_) {}
        } catch (e) {
          debugPrint('[Auth] getUser (all) failed: $e');
          _remoteUser = null;
        }
      } else {
        _remoteUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = fb.GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      bool useRedirect = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        useRedirect = prefs.getBool('useWebRedirect') ?? false;
      } catch (_) {}
      if (useRedirect) {
        debugPrint('[WebAuth] Using redirect flow');
        await fb.FirebaseAuth.instance.signInWithRedirect(provider);
        return;
      }
      fb.UserCredential cred;
      try {
        debugPrint('[WebAuth] Attempting popup sign-in');
        cred = await fb.FirebaseAuth.instance.signInWithPopup(provider);
      } catch (e) {
        // Popup blocked or not allowed – remember and fall back to redirect next time
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('useWebRedirect', true);
        } catch (_) {}
        debugPrint(
          '[WebAuth] Popup failed (${e.toString()}), falling back to redirect',
        );
        await fb.FirebaseAuth.instance.signInWithRedirect(provider);
        return;
      }
      final u = cred.user;
      if (u == null) throw Exception('Sign in failed');
      if (!_isAllowedEmail(u.email)) {
        await fb.FirebaseAuth.instance.signOut();
        throw Exception('Use your ycdsb.ca or ycdsbk12.ca email.');
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('wasSignedIn', true);
      } catch (_) {}
      debugPrint('[WebAuth] Popup sign-in success for ${u.email}');
      notifyListeners();
      return;
    }

    // Mobile/desktop: use FirebaseAuth with Google provider directly.
    await _ensureFirebaseInitialized();
    final provider = fb.GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    fb.FirebaseAuth auth;
    try {
      auth = fb.FirebaseAuth.instance;
    } catch (_) {
      await _ensureFirebaseInitialized();
      auth = fb.FirebaseAuth.instance;
    }
    final credential = await auth.signInWithProvider(provider);
    final u = credential.user;
    if (u == null) {
      throw Exception('Sign in failed');
    }
    if (!_isAllowedEmail(u.email)) {
      await auth.signOut();
      throw Exception('Use your ycdsb.ca or ycdsbk12.ca email.');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wasSignedIn', true);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> signOut() async {
    // Sign out of Firebase on all platforms; also disconnect GoogleSignIn on mobile
    await fb.FirebaseAuth.instance.signOut();
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
    final u = _fbUser;
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
      try {
        final rc = _remoteUser?['songRequestCount'];
        final uc = _remoteUser?['songUpvoteCount'];
        debugPrint('[Auth] remoteUser refreshed: requests=$rc, upvotes=$uc');
      } catch (_) {}
      notifyListeners();
    } catch (e) {
      debugPrint('[Auth] refreshRemoteUser failed: $e');
    }
  }
}
