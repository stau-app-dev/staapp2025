import 'package:flutter/material.dart';
import 'package:staapp2025/styles.dart';
import 'package:staapp2025/services/home_service.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/auth.dart';
import 'package:staapp2025/consts.dart';

class SongRequestsPage extends StatefulWidget {
  const SongRequestsPage({super.key});

  @override
  State<SongRequestsPage> createState() => _SongRequestsPageState();
}

class _SongRequestsPageState extends State<SongRequestsPage> {
  late Future<List<Map<String, dynamic>>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = fetchSongs();
    // When this page is first created, ensure we refresh the remote user
    // profile so counters (songRequestCount/songUpvoteCount) are available
    // as soon as possible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      // Fire-and-forget; refreshRemoteUser is safe when not signed in.
      auth.refreshRemoteUser();
    });
  }

  /// Refreshes the songs list and the authenticated user's remote profile.
  /// Used by the pull-to-refresh indicator.
  Future<void> _refreshPage() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      // Refresh remote user first so UI counters update quickly
      await auth.refreshRemoteUser();
    } catch (_) {}

    // Reload songs from the server and wait for the result so the
    // RefreshIndicator's spinner correlates with network activity.
    final future = fetchSongs();
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

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    final songRequestCount = parseInt(auth.remoteUser?['songRequestCount']);
    final songUpvoteCount = parseInt(auth.remoteUser?['songUpvoteCount']);

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
              // Only enable Add Song when we have a signed-in user AND a known
              // positive songRequestCount. If remoteUser is not yet fetched we
              // keep the button disabled to avoid accidental submits.
              onPressed:
                  (auth.user != null &&
                      auth.remoteUser != null &&
                      (songRequestCount != null && songRequestCount > 0))
                  ? () => _showAddSongDialog(context)
                  : null,
              icon: const Icon(Icons.add),
              label: Text('Add Song'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (auth.user != null &&
                        auth.remoteUser != null &&
                        (songRequestCount != null && songRequestCount > 0))
                    ? kGold
                    : Colors.grey,
                foregroundColor: kWhite,
                // Match AnnouncementsBlock button shape/size
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
          ] else if (auth.user != null) ...[
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
                      await auth.refreshRemoteUser();
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
                      // User can upvote only when signed in and they have upvotes remaining.
                      // User can upvote only when signed in, remoteUser has been
                      // fetched, and they have upvotes remaining (>0).
                      final canUpvote =
                          auth.user != null &&
                          auth.remoteUser != null &&
                          (songUpvoteCount != null && songUpvoteCount > 0);
                      final id = (s['id'] ?? '').toString();
                      final userEmail = canUpvote ? auth.user!.email : '';

                      final card = _SongCard(
                        title: name,
                        subtitle: 'By: $artist',
                        upvotes: upvotes,
                        onUpvote: canUpvote
                            ? () async {
                                if (id.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Missing song id',
                                        style: kBodyText,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (userEmail.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Missing user email',
                                        style: kBodyText,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final progressNavigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);

                                showDialog<void>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                try {
                                  // Defensive re-check: ensure the remote user still has
                                  // upvotes remaining before calling the backend.
                                  final currentRemote = auth.remoteUser;
                                  final dynamic uc =
                                      currentRemote?['songUpvoteCount'];
                                  int? remainingUpvotes;
                                  if (uc is int) {
                                    remainingUpvotes = uc;
                                  }
                                  if (uc is String) {
                                    remainingUpvotes = int.tryParse(uc);
                                  }
                                  if (remainingUpvotes != null &&
                                      remainingUpvotes <= 0) {
                                    try {
                                      progressNavigator.pop();
                                    } catch (_) {}
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

                                  await upvoteSong(
                                    songId: id,
                                    userEmail: userEmail,
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                  setState(() {
                                    _songsFuture = fetchSongs();
                                  });
                                  // Refresh remote user counters so UI updates immediately
                                  try {
                                    await auth.refreshRemoteUser();
                                  } catch (_) {}
                                  progressNavigator.pop();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Upvoted!',
                                        style: kBodyText,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  try {
                                    progressNavigator.pop();
                                  } catch (_) {}
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to upvote: ${e.toString()}',
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
    final auth = Provider.of<AuthService>(context, listen: false);
    final isAdmin = auth.isAdmin;
    final name = (song['name'] ?? '').toString().trim();
    final artist = (song['artist'] ?? '').toString().trim();
    final creatorEmail = (song['creatorEmail'] ?? '').toString().trim();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: kWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: mainBorderRadius,
            side: BorderSide(color: kMaroon, width: 1.4),
          ),
          child: SizedBox.expand(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(mainInsidePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
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
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
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
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Missing song id',
                                style: kBodyText,
                              ),
                            ),
                          );
                          return;
                        }

                        final progressNavigator = Navigator.of(context);
                        final deleteNavigator = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);

                        showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          await deleteSong(id: id);
                          if (!mounted) return;
                          setState(() {
                            _songsFuture = fetchSongs();
                          });
                          try {
                            await auth.refreshRemoteUser();
                          } catch (_) {}
                          progressNavigator.pop();
                          deleteNavigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Song deleted', style: kBodyText),
                            ),
                          );
                        } catch (e) {
                          try {
                            progressNavigator.pop();
                          } catch (_) {}
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to delete song: ${e.toString()}',
                                style: kBodyText,
                              ),
                            ),
                          );
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
    final userEmail = auth.user?.email ?? 'Anonymous';

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final artistCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: kWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: mainBorderRadius,
            side: BorderSide(color: kMaroon, width: 1.4),
          ),
          child: SizedBox.expand(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(mainInsidePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
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
                                  final creatorEmail = auth.user?.email ?? '';

                                  final progressNavigator = Navigator.of(
                                    context,
                                  );
                                  final addSongNavigator = Navigator.of(ctx);
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );

                                  showDialog<void>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
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
                                      try {
                                        progressNavigator.pop();
                                      } catch (_) {}
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

                                    await submitSong(
                                      artist: artist,
                                      name: name,
                                      creatorEmail: creatorEmail,
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() {
                                      _songsFuture = fetchSongs();
                                    });
                                    try {
                                      await auth.refreshRemoteUser();
                                    } catch (_) {}
                                    progressNavigator.pop();
                                    addSongNavigator.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Song submitted — thank you!',
                                          style: kBodyText,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    try {
                                      progressNavigator.pop();
                                    } catch (_) {}
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to submit song: ${e.toString()}',
                                          style: kBodyText,
                                        ),
                                      ),
                                    );
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
