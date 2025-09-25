import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/common/styles.dart';
import 'package:staapp2025/core/firebase_functions.dart' as fns;
import 'package:staapp2025/features/auth/auth_service.dart';
import 'package:staapp2025/features/song_requests/data/profanity.dart';

/// Shared overlay progress controller so dialogs can show/hide a global spinner.
class ProgressOverlayController {
  OverlayEntry? _entry;
  void show(BuildContext context) {
    if (_entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.black54)),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
    overlay.insert(_entry!);
  }

  void hide() {
    void removeOnce() {
      try {
        _entry?.remove();
      } catch (_) {}
      _entry = null;
    }

    removeOnce();
    WidgetsBinding.instance.addPostFrameCallback((_) => removeOnce());
    Future.delayed(const Duration(milliseconds: 60), removeOnce);
  }
}

Future<void> showDeleteSongDialog({
  required BuildContext context,
  required Map<String, dynamic> song,
  required VoidCallback onDataChanged,
  required ProgressOverlayController overlay,
}) async {
  var isClosing = false;
  final auth = Provider.of<AuthService>(context, listen: false);
  final isAdmin = auth.isAdmin;
  final name = (song['name'] ?? '').toString().trim();
  final artist = (song['artist'] ?? '').toString().trim();
  final creatorEmail = (song['creatorEmail'] ?? '').toString().trim();
  final messenger = ScaffoldMessenger.of(context); // capture before awaits
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: kWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: mainBorderRadius,
        side: BorderSide(color: kMaroon, width: 1.4),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
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
                Text('Delete Song', style: kSectionTitleSmall),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _labelValue('Song Name', name),
                        const SizedBox(height: 12),
                        _labelValue('Artist Name', artist),
                        const SizedBox(height: 12),
                        _labelValue('Creator Email', creatorEmail),
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
                      _snack(context, 'Only admins can delete songs');
                      return;
                    }
                    final id = (song['id'] ?? '').toString();
                    if (id.isEmpty) {
                      if (!isClosing) {
                        isClosing = true;
                        Navigator.of(ctx).pop();
                      }
                      _snack(context, 'Missing song id');
                      return;
                    }
                    overlay.show(context);
                    try {
                      final uid = auth.userId ?? '';
                      if (uid.isEmpty) {
                        overlay.hide();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Missing user id', style: kBodyText),
                          ),
                        );
                        return;
                      }
                      await fns.deleteSongNew(songId: id, userUuid: uid);
                      onDataChanged();
                      try {
                        await auth.refreshRemoteUser(caller: 'songs.delete');
                      } catch (_) {}
                      overlay.hide();
                      if (!isClosing && ctx.mounted) {
                        isClosing = true;
                        Navigator.of(ctx).pop();
                      }
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Song deleted', style: kBodyText),
                        ),
                      );
                    } catch (e, st) {
                      debugPrint('[SongRequests] deleteSong error: $e');
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
                        overlay.hide();
                        if (!isClosing && ctx.mounted) {
                          isClosing = true;
                          Navigator.of(ctx).pop();
                        }
                        onDataChanged();
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
                      overlay.hide();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete song: $e',
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
                  child: Text('Delete', style: kSectionTitleSmall),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> showAddSongDialog({
  required BuildContext context,
  required ProgressOverlayController overlay,
  required VoidCallback onDataChanged,
}) async {
  final auth = Provider.of<AuthService>(context, listen: false);
  final messenger = ScaffoldMessenger.of(context); // capture early
  final userEmail = auth.email ?? 'Anonymous';
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final artistCtrl = TextEditingController();
  var isClosing = false;
  var acknowledged = false;
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: kWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: mainBorderRadius,
        side: BorderSide(color: kMaroon, width: 1.4),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(mainInsidePadding),
            child: StatefulBuilder(
              builder: (ctx2, setStateDialog) => Column(
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
                  Text('Add Song', style: kSectionTitleSmall),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        key: formKey,
                        child: Column(
                          children: [
                            _textLabel('Song Name'),
                            const SizedBox(height: 8),
                            _songField(
                              controller: nameCtrl,
                              hint: 'Never Gonna Give You Up',
                              validator: _songValidator,
                            ),
                            const SizedBox(height: 14),
                            _textLabel('Artist Name'),
                            const SizedBox(height: 8),
                            _songField(
                              controller: artistCtrl,
                              hint: 'Rick Astley',
                              validator: _artistValidator,
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: acknowledged,
                                  onChanged: (v) => setStateDialog(() {
                                    acknowledged = v ?? false;
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'I acknowledge that my school email will be recorded with this request and that submitting inappropriate content may result in disciplinary action.',
                                    style: kAnnouncementBody.copyWith(
                                      color: kMaroon,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: acknowledged
                                  ? () async {
                                      if (!(formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }
                                      final artist = artistCtrl.text.trim();
                                      final name = nameCtrl.text.trim();
                                      final creatorUuid = auth.userId ?? '';
                                      if (creatorUuid.isEmpty) {
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
                                      overlay.show(context);
                                      try {
                                        final dynamic rc = auth
                                            .remoteUser?['songRequestCount'];
                                        int? remaining;
                                        if (rc is int) {
                                          remaining = rc;
                                        } else if (rc is String) {
                                          remaining = int.tryParse(rc);
                                        }
                                        if (remaining != null &&
                                            remaining <= 0) {
                                          overlay.hide();
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
                                          creatorUuid: creatorUuid,
                                        );
                                        onDataChanged();
                                        try {
                                          await auth.refreshRemoteUser(
                                            caller: 'songs.submit',
                                          );
                                        } catch (_) {}
                                        overlay.hide();
                                        if (!isClosing && ctx.mounted) {
                                          isClosing = true;
                                          Navigator.of(ctx).pop();
                                        }
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Song submitted — thank you!',
                                              style: kBodyText,
                                            ),
                                          ),
                                        );
                                      } catch (e, st) {
                                        debugPrint(
                                          '[SongRequests] submitSong error: $e',
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
                                            msg.contains(
                                              'XMLHttpRequest error',
                                            ) ||
                                            msg.contains('TypeError');
                                        if (kIsWeb && isBrowserFetchError) {
                                          overlay.hide();
                                          if (!isClosing && ctx.mounted) {
                                            isClosing = true;
                                            Navigator.of(ctx).pop();
                                          }
                                          onDataChanged();
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
                                        overlay.hide();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to submit song: $e',
                                              style: kBodyText,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kGold,
                                shape: RoundedRectangleBorder(
                                  borderRadius: mainBorderRadius,
                                ),
                                padding: kButtonPadding,
                              ),
                              child: Text('Submit', style: kSectionTitleSmall),
                            ),
                            const SizedBox(height: 8),
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
      ),
    ),
  );
}

// ---------------- Internal Helpers ----------------
Widget _labelValue(String label, String value) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label, style: kSectionTitleSmall.copyWith(color: kMaroon)),
    const SizedBox(height: 6),
    Text(value, style: kBodyText.copyWith(color: kMaroon)),
  ],
);

Widget _textLabel(String text) => Align(
  alignment: Alignment.centerLeft,
  child: Text(text, style: kSectionTitleSmall.copyWith(color: kMaroon)),
);

Widget _songField({
  required TextEditingController controller,
  required String hint,
  required String? Function(String?) validator,
}) => TextFormField(
  controller: controller,
  decoration: InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kInnerRadius),
      borderSide: BorderSide(color: kMaroon),
    ),
  ),
  validator: validator,
);

String? _songValidator(String? v) {
  final text = v?.trim() ?? '';
  if (text.isEmpty) return 'Please enter a song name';
  if (containsProfanity(text)) return 'Please remove inappropriate language.';
  return null;
}

String? _artistValidator(String? v) {
  final text = v?.trim() ?? '';
  if (text.isEmpty) return 'Please enter an artist name';
  if (containsProfanity(text)) return 'Please remove inappropriate language.';
  return null;
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message, style: kBodyText)));
}
