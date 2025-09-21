import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:staapp2025/common/styles.dart';
import 'package:staapp2025/core/firebase_functions.dart' as fns;
import 'package:provider/provider.dart';
import 'package:staapp2025/features/auth/auth_service.dart';
import 'package:staapp2025/features/song_requests/data/profanity.dart';
import 'package:staapp2025/features/auth/guard.dart';

class SongRequestsPage extends StatefulWidget {
  const SongRequestsPage({super.key});

  @override
  State<SongRequestsPage> createState() => _SongRequestsPageState();
}

class _SongRequestsPageState extends State<SongRequestsPage> {
  late Future<List<Map<String, dynamic>>> _songsFuture;

  // Simple, robust progress overlay that doesn't rely on Navigator.
  OverlayEntry? _progressOverlay;
  void _showProgressOverlay(BuildContext context) {
    if (_progressOverlay != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _progressOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.black54)),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
    overlay.insert(_progressOverlay!);
  }

  void _hideProgressOverlay() {
    void removeOnce() {
      try {
        _progressOverlay?.remove();
      } catch (_) {}
      _progressOverlay = null;
    }

    // Remove now, on next frame, and after a short delay to be extra safe.
    removeOnce();
    WidgetsBinding.instance.addPostFrameCallback((_) => removeOnce());
    Future.delayed(const Duration(milliseconds: 60), removeOnce);
  }

  @override
  void initState() {
    super.initState();
    _songsFuture = fns.fetchSongs();
    // When this page is first created, ensure we refresh the remote user
    // profile so counters (songRequestCount/songUpvoteCount) are available
    // as soon as possible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      // Fire-and-forget; refreshRemoteUser is safe when not signed in.
      auth.refreshRemoteUser(caller: 'songs.init');
    });
  }

  /// Refreshes the songs list and the authenticated user's remote profile.
  /// Used by the pull-to-refresh indicator.
  Future<void> _refreshPage() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      // Refresh remote user first so UI counters update quickly
      await auth.refreshRemoteUser(caller: 'songs.pullToRefresh');
    } catch (_) {}

    // Reload songs from the server and wait for the result so the
    // RefreshIndicator's spinner correlates with network activity.
    final future = fns.fetchSongs();
    setState(() {
      _songsFuture = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AuthService so UI updates when remoteUser changes
    final auth = Provider.of<AuthService>(context);

    final songRequestCount = auth.songRequestCount;
    final songUpvoteCount = auth.songUpvoteCount;

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

          // Add Song button opens a modal dialog
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Capture messenger before any awaits to avoid using context after async gaps.
                final messenger = ScaffoldMessenger.of(context);
                // Ensure the user is signed in; if not, show login.
                final ok = await ensureSignedIn(context);
                if (!context.mounted) return;
                if (!ok) return;
                final auth = Provider.of<AuthService>(context, listen: false);
                // Refresh remote user to ensure we have up-to-date counters.
                try {
                  await auth.refreshRemoteUser(
                    caller: 'songs.addButtonPrefetch',
                  );
                } catch (_) {}
                final remaining = auth.songRequestCount ?? 0;
                if (remaining <= 0) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('No song requests left', style: kBodyText),
                    ),
                  );
                  return;
                }
                if (!context.mounted) return;
                _showAddSongDialog(context);
              },
              icon: const Icon(Icons.add),
              label: Text('Add Song'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    // If signed in but no quota -> grey; otherwise gold to encourage action
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

          // Show remaining counters when remoteUser is available. If the
          // user is signed in but the remote profile is not yet fetched,
          // show a small retry hint so they can trigger a refresh.
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
                    // Capture messenger early to avoid using BuildContext after
                    // awaiting (fixes use_build_context_synchronously).
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
                        SnackBar(
                          content: Text(
                            'Failed to refresh profile: ${e.toString()}',
                            style: kBodyText,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Retry',
                    style: kWelcomeTitle.copyWith(color: kGold),
                  ),
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
                    itemCount: songs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final s = songs[idx];
                      final artist = (s['artist'] ?? '').toString().trim();
                      final name = (s['name'] ?? '').toString().trim();
                      final upvotes = s['upvotes'] is int
                          ? s['upvotes'] as int
                          : int.tryParse(s['upvotes']?.toString() ?? '0') ?? 0;
                      final canDelete = auth.isAdmin;
                      final id = (s['id'] ?? '').toString();

                      // Disable upvote if signed in and no upvotes left; keep enabled when not signed in
                      final canUpvoteNow =
                          !(auth.isSignedIn &&
                              (songUpvoteCount != null &&
                                  songUpvoteCount <= 0));

                      final card = _SongCard(
                        title: name,
                        subtitle: 'By: $artist',
                        upvotes: upvotes,
                        onUpvote: canUpvoteNow
                            ? () async {
                                // Capture messenger as early as possible
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = await ensureSignedIn(context);
                                if (!context.mounted) return;
                                if (!ok) return;
                                final auth = Provider.of<AuthService>(
                                  context,
                                  listen: false,
                                );
                                try {
                                  await auth.refreshRemoteUser(
                                    caller: 'songs.upvoteOptimistic',
                                  );
                                } catch (_) {}
                                if (id.isEmpty) {
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
                                final userEmail = auth.email ?? '';
                                if (userEmail.isEmpty) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Missing user email',
                                        style: kBodyText,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (!context.mounted) return;
                                _showProgressOverlay(context);
                                try {
                                  final remainingUpvotes =
                                      auth.songUpvoteCount ?? 0;
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
                                    songId: id,
                                    userEmail: userEmail,
                                  );
                                  if (!context.mounted) return;
                                  setState(() {
                                    _songsFuture = fns.fetchSongs();
                                  });
                                  try {
                                    await auth.refreshRemoteUser(
                                      caller: 'songs.deleteOptimistic',
                                    );
                                  } catch (_) {}
                                  _hideProgressOverlay();
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Upvoted!',
                                          style: kBodyText,
                                        ),
                                      ),
                                    );
                                  });
                                } catch (e, st) {
                                  debugPrint(
                                    '[SongRequests] upvoteSong error: ${e.toString()}',
                                  );
                                  try {
                                    if (!kIsWeb) {
                                      debugPrintStack(stackTrace: st);
                                    } else {
                                      debugPrint('[stack] $st');
                                    }
                                  } catch (_) {
                                    debugPrint('[stack print failed]');
                                  }
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
                                      setState(() {
                                        _songsFuture = fns.fetchSongs();
                                      });
                                    }
                                    try {
                                      await auth.refreshRemoteUser();
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
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to upvote: ${e.toString()}',
                                          style: kBodyText,
                                        ),
                                      ),
                                    );
                                  });
                                }
                              }
                            : null,
                      );

                      if (!canDelete) return card;

                      return GestureDetector(
                        onLongPress: () => _showDeleteDialog(context, s),
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

  Future<void> _showDeleteDialog(
    BuildContext context,
    Map<String, dynamic> song,
  ) async {
    // Guard against multiple rapid dismiss actions to avoid navigator races
    var isClosing = false;
    final auth = Provider.of<AuthService>(context, listen: false);
    final isAdmin = auth.isAdmin;
    final name = (song['name'] ?? '').toString().trim();
    final artist = (song['artist'] ?? '').toString().trim();
    final creatorEmail = (song['creatorEmail'] ?? '').toString().trim();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: kWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: mainBorderRadius,
            side: BorderSide(color: kMaroon, width: 1.4),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
              // Allow height to be comfortable but scroll when content exceeds.
              maxHeight: 640,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(mainInsidePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () {
                          if (isClosing) return;
                          isClosing = true;
                          // Pop the dialog immediately using the builder context
                          Navigator.of(ctx).pop();
                        },
                        child: Icon(Icons.close, color: kGold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Delete Song',
                      style: kWelcomeTitle.copyWith(color: kMaroon),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Song Name',
                              style: kSectionTitleSmall.copyWith(
                                color: kMaroon,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              style: kBodyText.copyWith(color: kMaroon),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Artist Name',
                              style: kSectionTitleSmall.copyWith(
                                color: kMaroon,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              artist,
                              style: kBodyText.copyWith(color: kMaroon),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Creator Email',
                              style: kSectionTitleSmall.copyWith(
                                color: kMaroon,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              creatorEmail,
                              style: kBodyText.copyWith(color: kMaroon),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Note:\nIf a student continues to suggest inappropriate songs, admins can request for app privileges to be stripped.',
                              textAlign: TextAlign.center,
                              style: kPlaceholderText.copyWith(color: kMaroon),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (!isAdmin) {
                          if (!isClosing) {
                            isClosing = true;
                            Navigator.of(ctx).pop();
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Only admins can delete songs',
                                style: kBodyText,
                              ),
                            ),
                          );
                          return;
                        }
                        final id = (song['id'] ?? '').toString();
                        if (id.isEmpty) {
                          if (!isClosing) {
                            isClosing = true;
                            Navigator.of(ctx).pop();
                          }
                          final messenger = ScaffoldMessenger.of(context);
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

                        // Show global progress overlay (dismissed via _hideProgressOverlay)
                        _showProgressOverlay(context);
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await fns.deleteSong(id: id);
                          if (!mounted) return;
                          setState(() {
                            _songsFuture = fns.fetchSongs();
                          });
                          try {
                            await auth.refreshRemoteUser(
                              caller: 'songs.delete',
                            );
                          } catch (_) {}
                          _hideProgressOverlay();
                          if (!isClosing) {
                            if (!ctx.mounted) return;
                            isClosing = true;
                            Navigator.of(ctx).pop();
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Song deleted', style: kBodyText),
                              ),
                            );
                          });
                        } catch (e, st) {
                          debugPrint(
                            '[SongRequests] deleteSong error: ${e.toString()}',
                          );
                          try {
                            if (!kIsWeb) {
                              debugPrintStack(stackTrace: st);
                            } else {
                              debugPrint('[stack] $st');
                            }
                          } catch (_) {
                            debugPrint('[stack print failed]');
                          }
                          // Similar to add-song, on web the browser may report
                          // "Failed to fetch" even if the function succeeded.
                          // Handle optimistically to keep UI responsive.
                          final msg = e.toString();
                          final isBrowserFetchError =
                              msg.contains('Failed to fetch') ||
                              msg.contains('TimeoutException') ||
                              msg.contains('NetworkError') ||
                              msg.contains('XMLHttpRequest error') ||
                              msg.contains('TypeError');
                          if (kIsWeb && isBrowserFetchError) {
                            _hideProgressOverlay();
                            if (!isClosing) {
                              if (!ctx.mounted) return;
                              isClosing = true;
                              Navigator.of(ctx).pop();
                            }
                            if (mounted) {
                              setState(() {
                                _songsFuture = fns.fetchSongs();
                              });
                            }
                            try {
                              await auth.refreshRemoteUser(
                                caller: 'songs.deleteBrowserFetchError',
                              );
                            } catch (_) {}
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Song deleted. Refreshing list…',
                                  style: kBodyText,
                                ),
                              ),
                            );
                            return;
                          }
                          _hideProgressOverlay();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to delete song: ${e.toString()}',
                                  style: kBodyText,
                                ),
                              ),
                            );
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdmin ? kGold : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: mainBorderRadius,
                        ),
                        padding: kButtonPadding,
                      ),
                      child: Text(
                        'Delete',
                        style: kWelcomeTitle.copyWith(color: kMaroon),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddSongDialog(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userEmail = auth.email ?? 'Anonymous';

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    // Guard to prevent multiple close pops
    var isClosing = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: kWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: mainBorderRadius,
            side: BorderSide(color: kMaroon, width: 1.4),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(mainInsidePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () {
                          if (isClosing) return;
                          isClosing = true;
                          Navigator.of(ctx).pop();
                        },
                        child: Icon(Icons.close, color: kGold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add Song',
                      style: kWelcomeTitle.copyWith(color: kMaroon),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          key: formKey,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Song Name',
                                  style: kSectionTitleSmall.copyWith(
                                    color: kMaroon,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: nameCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Never Gonna Give You Up',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      kBlockRadius,
                                    ),
                                    borderSide: BorderSide(color: kMaroon),
                                  ),
                                ),
                                validator: (v) {
                                  final text = v?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Please enter a song name';
                                  }
                                  if (containsProfanity(text)) {
                                    return 'Please remove inappropriate language.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Artist Name',
                                  style: kSectionTitleSmall.copyWith(
                                    color: kMaroon,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: artistCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Rick Astley',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(28),
                                    borderSide: BorderSide(color: kMaroon),
                                  ),
                                ),
                                validator: (v) {
                                  final text = v?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Please enter an artist name';
                                  }
                                  if (containsProfanity(text)) {
                                    return 'Please remove inappropriate language.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Submitted by: $userEmail',
                                  style: kPlaceholderText.copyWith(
                                    color: kMaroon,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                onPressed: () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  final artist = artistCtrl.text.trim();
                                  final name = nameCtrl.text.trim();
                                  final creatorEmail = auth.email ?? '';

                                  // Show global progress overlay (dismissed via _hideProgressOverlay)
                                  _showProgressOverlay(context);
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );

                                  try {
                                    final currentRemote = auth.remoteUser;
                                    final dynamic rc =
                                        currentRemote?['songRequestCount'];
                                    int? remainingRequests;
                                    if (rc is int) {
                                      remainingRequests = rc;
                                    }
                                    if (rc is String) {
                                      remainingRequests = int.tryParse(rc);
                                    }
                                    if (remainingRequests != null &&
                                        remainingRequests <= 0) {
                                      debugPrint(
                                        '[SongRequests] Add song blocked: no song requests left for user',
                                      );
                                      _hideProgressOverlay();
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

                                    await fns.submitSong(
                                      artist: artist,
                                      name: name,
                                      creatorEmail: creatorEmail,
                                    );
                                    debugPrint(
                                      '[SongRequests] submitSong success: name="$name", artist="$artist", creator="$creatorEmail"',
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      _songsFuture = fns.fetchSongs();
                                    });
                                    try {
                                      await auth.refreshRemoteUser(
                                        caller: 'songs.submit',
                                      );
                                    } catch (_) {}
                                    _hideProgressOverlay();
                                    if (!isClosing) {
                                      if (!ctx.mounted) return;
                                      isClosing = true;
                                      Navigator.of(ctx).pop();
                                    }
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Song submitted — thank you!',
                                                style: kBodyText,
                                              ),
                                            ),
                                          );
                                        });
                                  } catch (e, st) {
                                    debugPrint(
                                      '[SongRequests] submitSong error: ${e.toString()}',
                                    );
                                    try {
                                      if (!kIsWeb) {
                                        debugPrintStack(stackTrace: st);
                                      } else {
                                        debugPrint('[stack] $st');
                                      }
                                    } catch (_) {
                                      debugPrint('[stack print failed]');
                                    }
                                    // On web, a CORS/preflight issue can cause the browser
                                    // client to report "Failed to fetch" even if the Cloud Function
                                    // completed. Since we've seen the song actually get added,
                                    // treat this specific case optimistically: close the dialog,
                                    // refresh the list, and inform the user.
                                    final msg = e.toString();
                                    final isBrowserFetchError =
                                        msg.contains('Failed to fetch') ||
                                        msg.contains('TimeoutException') ||
                                        msg.contains('NetworkError') ||
                                        msg.contains('XMLHttpRequest error') ||
                                        msg.contains('TypeError');
                                    if (kIsWeb && isBrowserFetchError) {
                                      _hideProgressOverlay();
                                      if (!isClosing) {
                                        if (!ctx.mounted) return;
                                        isClosing = true;
                                        Navigator.of(ctx).pop();
                                      }
                                      if (mounted) {
                                        setState(() {
                                          _songsFuture = fns.fetchSongs();
                                        });
                                      }
                                      try {
                                        await auth.refreshRemoteUser(
                                          caller:
                                              'songs.submitBrowserFetchError',
                                        );
                                      } catch (_) {}
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Song submitted. Refreshing list…',
                                            style: kBodyText,
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    _hideProgressOverlay();
                                    WidgetsBinding.instance.addPostFrameCallback((
                                      _,
                                    ) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to submit song: ${e.toString()}',
                                            style: kBodyText,
                                          ),
                                        ),
                                      );
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kGold,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: mainBorderRadius,
                                  ),
                                  padding: kButtonPadding,
                                ),
                                child: Text(
                                  'Submit',
                                  style: kWelcomeTitle.copyWith(color: kMaroon),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Note:\nAll song recommendations MUST be school appropriate, this means no explicit language or subjects.',
                                textAlign: TextAlign.center,
                                style: kPlaceholderText.copyWith(
                                  color: kMaroon,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SongCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int upvotes;
  final VoidCallback? onUpvote;

  const _SongCard({
    required this.title,
    required this.subtitle,
    required this.upvotes,
    this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // left upvote area
        GestureDetector(
          onTap: onUpvote,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              // Active upvote = gold, inactive = grey
              color: onUpvote != null ? kGold : Colors.grey,
              borderRadius: BorderRadius.circular(kInnerRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_upward, color: kWhite, size: 12),
                const SizedBox(height: 1),
                Text(
                  '$upvotes',
                  style: kGradeLabel.copyWith(color: kWhite, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // main card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: kMediumPadding,
              horizontal: kMediumPadding,
            ),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(kInnerRadius),
              border: Border.all(color: kMaroon, width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kAnnouncementTitle.copyWith(color: kMaroon)),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: kAnnouncementBody.copyWith(color: kMaroon),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
