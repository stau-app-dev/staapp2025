import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import 'package:staapp2025/common/pwa.dart' as pwa;
import 'package:staapp2025/common/styles.dart';
import 'package:staapp2025/core/firebase_functions.dart' as fns;
import 'package:staapp2025/features/auth/auth_service.dart';
import 'package:staapp2025/features/auth/guard.dart';
import 'package:staapp2025/features/song_requests/ui/song_card.dart';
import 'package:staapp2025/features/song_requests/ui/song_request_dialogs.dart';

class SongRequestsPage extends StatefulWidget {
  const SongRequestsPage({super.key});

  @override
  State<SongRequestsPage> createState() => _SongRequestsPageState();
}

class _SongRequestsPageState extends State<SongRequestsPage> {
  late Future<List<Map<String, dynamic>>> _songsFuture;
  final _dialogOverlay = ProgressOverlayController();
  OverlayEntry? _progressOverlay;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.userId;
    _songsFuture = (uid == null || uid.isEmpty)
        ? Future.value(<Map<String, dynamic>>[])
        : fns.fetchSongs(userUuid: uid);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      auth.refreshRemoteUser(caller: 'songs.init');
    });
  }

  // (legacy overlay method removed in favor of _showProgressOverlayFrom)

  void _hideProgressOverlay() {
    try {
      _progressOverlay?.remove();
    } catch (_) {}
    _progressOverlay = null;
  }

  void _showProgressOverlayFrom(OverlayState? overlay) {
    if (_progressOverlay != null) return;
    if (overlay == null) return;
    _progressOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.black54)),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
    try {
      overlay.insert(_progressOverlay!);
    } catch (_) {}
  }

  Future<void> _refreshPage() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await auth.refreshRemoteUser(caller: 'songs.pullToRefresh');
    } catch (_) {}
    final uid = auth.userId;
    final future = (uid == null || uid.isEmpty)
        ? Future.value(<Map<String, dynamic>>[])
        : fns.fetchSongs(userUuid: uid);
    setState(() => _songsFuture = future);
    try {
      await future;
    } catch (_) {}
  }

  // (helper removed; inline usage now for clarity and to avoid context-after-await lints)

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final songRequestCount = auth.songRequestCount;
    final songUpvoteCount = auth.songUpvoteCount;
    final canAddNow =
        !(auth.isSignedIn &&
            (songRequestCount != null && songRequestCount <= 0));

    return Padding(
      padding: const EdgeInsets.fromLTRB(kPage, kPage, kPage, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: kWelcomeBannerDecoration,
            padding: const EdgeInsets.symmetric(
              vertical: mainVerticalPadding,
              horizontal: mainHorizontalPadding,
            ),
            child: Text(
              'Song Requests',
              style: kWelcomeTitle.copyWith(color: kWhite),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: canAddNow
                  ? () async {
                      // Capture context-dependent singletons before async gap
                      final ctx = context;
                      final messenger = ScaffoldMessenger.of(ctx);
                      final authLocal = Provider.of<AuthService>(
                        ctx,
                        listen: false,
                      );
                      // Perform auth guard (may push login). We deliberately do not
                      // use ctx afterwards except inside a post-frame callback.
                      final ok = await ensureSignedIn(ctx);
                      if (!mounted || !ok) return;
                      try {
                        await authLocal.refreshRemoteUser(
                          caller: 'songs.addButtonPrefetch',
                        );
                      } catch (_) {}
                      final remaining = authLocal.songRequestCount ?? 0;
                      if (remaining <= 0) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'No song requests left',
                              style: kBodyText,
                            ),
                          ),
                        );
                        return;
                      }
                      if (!mounted) return;
                      // Defer showing dialog to next frame to satisfy lints about context reuse after await.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        showAddSongDialog(
                          context: ctx,
                          overlay: _dialogOverlay,
                          onDataChanged: () {
                            final uid = authLocal.userId;
                            if (uid != null && uid.isNotEmpty) {
                              setState(() {
                                _songsFuture = fns.fetchSongs(userUuid: uid);
                              });
                            }
                          },
                        );
                      });
                    }
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Add Song'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (auth.isSignedIn &&
                        (songRequestCount != null && songRequestCount <= 0))
                    ? Colors.grey
                    : kGold,
                foregroundColor: kWhite,
                padding: kButtonPadding,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (auth.remoteUser != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Requests left: ${songRequestCount ?? '—'}',
                  style: kPlaceholderText.copyWith(color: kMaroon),
                ),
                const SizedBox(width: 16),
                Text(
                  'Upvotes left: ${songUpvoteCount ?? '—'}',
                  style: kPlaceholderText.copyWith(color: kMaroon),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else if (auth.isSignedIn) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Fetching profile...',
                  style: kPlaceholderText.copyWith(color: kMaroon),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await auth.refreshRemoteUser(caller: 'songs.upvote');
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Profile refreshed', style: kBodyText),
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed: $e', style: kBodyText)),
                      );
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _songsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load songs',
                      style: kPlaceholderText,
                    ),
                  );
                }
                final songs = snap.data ?? [];
                if (songs.isEmpty) {
                  return Center(
                    child: Text('No song requests', style: kPlaceholderText),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refreshPage,
                  child: ListView.separated(
                    padding: EdgeInsets.only(
                      bottom: kPage + pwa.extraNavBarBottomPadding(),
                    ),
                    itemCount: songs.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final s = songs[idx];
                      final artist = (s['artist'] ?? '').toString().trim();
                      final name = (s['name'] ?? '').toString().trim();
                      final upvotes = s['upvotes'] is int
                          ? s['upvotes'] as int
                          : int.tryParse(s['upvotes']?.toString() ?? '0') ?? 0;
                      final id = (s['id'] ?? '').toString();
                      final canDelete = auth.isAdmin;
                      final canUpvoteNow =
                          !(auth.isSignedIn &&
                              (songUpvoteCount != null &&
                                  songUpvoteCount <= 0));

                      final messenger = ScaffoldMessenger.of(
                        context,
                      ); // capture before awaits
                      final authRead = Provider.of<AuthService>(
                        context,
                        listen: false,
                      );
                      final card = SongCard(
                        title: name,
                        subtitle: 'By: $artist',
                        upvotes: upvotes,
                        onUpvote: canUpvoteNow
                            ? () async {
                                // Capture all context-derived objects BEFORE awaits
                                final ctxUpvote = context; // alias for clarity
                                final overlayState = Overlay.maybeOf(
                                  ctxUpvote,
                                  rootOverlay: true,
                                );
                                final localId = id;
                                final initialUserUuid = authRead.userId ?? '';
                                final signedIn = await ensureSignedIn(
                                  ctxUpvote,
                                );
                                if (!mounted || !signedIn) return;
                                try {
                                  await authRead.refreshRemoteUser(
                                    caller: 'songs.upvoteOptimistic',
                                  );
                                } catch (_) {}
                                if (localId.isEmpty) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Missing song id',
                                        style: kBodyText,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (initialUserUuid.isEmpty) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Missing user id',
                                        style: kBodyText,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _showProgressOverlayFrom(overlayState);
                                try {
                                  final remainingUpvotes =
                                      authRead.songUpvoteCount ?? 0;
                                  if (remainingUpvotes <= 0) {
                                    _hideProgressOverlay();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'No upvotes left',
                                          style: kBodyText,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await fns.upvoteSong(
                                    songId: localId,
                                    userUuid: initialUserUuid,
                                  );
                                  if (!mounted) return;
                                  final uid2 = authRead.userId;
                                  if (uid2 != null && uid2.isNotEmpty) {
                                    setState(() {
                                      _songsFuture = fns.fetchSongs(
                                        userUuid: uid2,
                                      );
                                    });
                                  }
                                  try {
                                    await authRead.refreshRemoteUser(
                                      caller: 'songs.deleteOptimistic',
                                    );
                                  } catch (_) {}
                                  _hideProgressOverlay();
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Upvoted!',
                                        style: kBodyText,
                                      ),
                                    ),
                                  );
                                } catch (e, st) {
                                  debugPrint(
                                    '[SongRequests] upvoteSong error: $e',
                                  );
                                  try {
                                    if (!kIsWeb) {
                                      debugPrintStack(stackTrace: st);
                                    } else {
                                      debugPrint('[stack] $st');
                                    }
                                  } catch (_) {}
                                  final msg = e.toString();
                                  final isBrowserFetchError =
                                      msg.contains('Failed to fetch') ||
                                      msg.contains('TimeoutException') ||
                                      msg.contains('NetworkError') ||
                                      msg.contains('XMLHttpRequest error') ||
                                      msg.contains('TypeError');
                                  if (kIsWeb && isBrowserFetchError) {
                                    _hideProgressOverlay();
                                    if (mounted) {
                                      final uid3 = authRead.userId;
                                      if (uid3 != null && uid3.isNotEmpty) {
                                        setState(() {
                                          _songsFuture = fns.fetchSongs(
                                            userUuid: uid3,
                                          );
                                        });
                                      }
                                    }
                                    try {
                                      await authRead.refreshRemoteUser();
                                    } catch (_) {}
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Upvoted. Refreshing list…',
                                          style: kBodyText,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  _hideProgressOverlay();
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to upvote: $e',
                                        style: kBodyText,
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                      );

                      if (!canDelete) return card;
                      return GestureDetector(
                        onLongPress: () => showDeleteSongDialog(
                          context: context,
                          song: s,
                          overlay: _dialogOverlay,
                          onDataChanged: () {
                            final uidReload = auth.userId;
                            if (uidReload != null && uidReload.isNotEmpty) {
                              setState(() {
                                _songsFuture = fns.fetchSongs(
                                  userUuid: uidReload,
                                );
                              });
                            }
                          },
                        ),
                        child: card,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Page cleaned & dialogs/cards extracted.
