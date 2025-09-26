import 'package:flutter/material.dart';
import 'package:staapp2025/common/styles.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/features/auth/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:staapp2025/common/widgets/error_card.dart';
import 'package:staapp2025/core/firebase_functions.dart' as fns;
import 'dart:async';
import 'package:staapp2025/features/auth/guard.dart';

class AnnouncementsBlock extends StatefulWidget {
  const AnnouncementsBlock({super.key});

  @override
  State<AnnouncementsBlock> createState() => AnnouncementsBlockState();
}

class AnnouncementsBlockState extends State<AnnouncementsBlock>
    with WidgetsBindingObserver {
  List<Map<String, String>> announcements = const [
    {'title': 'Titans', 'body': 'No announcements today'},
  ];

  bool _loading = true;
  bool _error = false;
  String? _errorMessage;

  bool _pendingExternalReturn = false;
  Timer? _resumeRefreshTimer;
  Timer? _fallbackRefreshTimer;

  // New: form URL caching & launch/loading states
  String? _formUrl;
  bool _formUrlLoading = false;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAnnouncements();
    _preloadFormUrl(); // Prefetch to reduce button latency
  }

  void _preloadFormUrl() async {
    try {
      // Only fetch for signed-in staff
      AuthService? auth;
      try {
        auth = Provider.of<AuthService>(context, listen: false);
      } catch (_) {}
      final email = (auth?.email ?? '').toLowerCase();
      if (!(auth?.isSignedIn ?? false) || !email.endsWith('ycdsb.ca')) return;
      // Avoid duplicate fetch
      if (_formUrl != null) return;
      final url = await fns.fetchAnnouncementFormUrl();
      if (!mounted) return;
      setState(() {
        _formUrl = url;
      });
    } catch (_) {
      // Silent: fallback handled on button press
    }
  }

  Future<void> refreshAnnouncements() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMessage = null;
    });
    await _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final parsed = await fns.fetchAnnouncements();
      if (parsed.isNotEmpty) {
        setState(() {
          announcements = parsed;
          _loading = false;
          _error = false;
          _errorMessage = null;
        });
        return;
      }
      setState(() {
        announcements = const [
          {'title': 'Titans', 'body': 'No announcements today'},
        ];
        _loading = false;
        _error = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      _resumeRefreshTimer?.cancel();
    } catch (_) {}
    try {
      _fallbackRefreshTimer?.cancel();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingExternalReturn) {
      try {
        _fallbackRefreshTimer?.cancel();
      } catch (_) {}
      try {
        _resumeRefreshTimer?.cancel();
      } catch (_) {}
      _resumeRefreshTimer = Timer(const Duration(seconds: 8), () async {
        if (!mounted) return;
        await refreshAnnouncements();
        _pendingExternalReturn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Be resilient if no AuthService provider is present (e.g., in tests)
    AuthService? auth;
    try {
      auth = Provider.of<AuthService>(context, listen: false);
    } catch (_) {
      auth = null;
    }
    final userEmail = auth?.email ?? '';
    final canAdd =
        (auth?.isSignedIn ?? false) &&
        userEmail.toLowerCase().endsWith('ycdsb.ca');

    return Container(
      decoration: kCardDecoration,
      padding: EdgeInsets.all(kBlockPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Announcements Board', style: kSectionTitle),
          if (canAdd) ...[
            SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: (_formUrlLoading || _launching)
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);

                        // Form URL cached? Fetch if not.
                        String? url = _formUrl;
                        if (url == null || url.trim().isEmpty) {
                          setState(() {
                            _formUrlLoading = true;
                          });
                          try {
                            url = await fns.fetchAnnouncementFormUrl();
                            if (!mounted) return;
                            _formUrl = url;
                          } catch (_) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Form URL unavailable'),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _formUrlLoading = false;
                              });
                            }
                          }
                        }

                        if (url == null || url.trim().isEmpty) return;

                        setState(() {
                          _launching = true;
                        });
                        try {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            final launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (launched) {
                              _pendingExternalReturn = true;
                              try {
                                _fallbackRefreshTimer?.cancel();
                              } catch (_) {}
                              _fallbackRefreshTimer = Timer(
                                const Duration(seconds: 15),
                                () async {
                                  if (!mounted) return;
                                  await refreshAnnouncements();
                                  _pendingExternalReturn = false;
                                },
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Could not open form URL'),
                                ),
                              );
                            }
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Could not open form URL'),
                              ),
                            );
                          }
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to open form: ${e.toString()}',
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _launching = false;
                            });
                          }
                        }
                      },
                icon: (_formUrlLoading || _launching)
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kMaroonAccent,
                        ),
                      )
                    : Icon(Icons.add),
                label: Text(_formUrlLoading
                    ? 'Loading...'
                    : _launching
                        ? 'Opening...'
                        : 'Add Announcement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: kWhite,
                ),
              ),
            ),
          ],
          SizedBox(height: 12),
          if (_loading)
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kMaroonAccent,
                ),
              ),
            ),
          if (!_loading && _error) ...[
            ErrorCard(
              message: _errorMessage ?? 'Failed to load announcements',
              onRetry: refreshAnnouncements,
            ),
            SizedBox(height: 12),
            ...announcements.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.small),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: kInnerCardDecoration,
                        padding: EdgeInsets.all(kInnerPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['title'] ?? '', style: kAnnouncementTitle),
                            SizedBox(height: Spacing.tiny),
                            Text(a['body'] ?? '', style: kAnnouncementBody),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...announcements.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.small),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: kInnerCardDecoration,
                        padding: EdgeInsets.all(kInnerPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['title'] ?? '', style: kAnnouncementTitle),
                            SizedBox(height: Spacing.tiny),
                            Text(a['body'] ?? '', style: kAnnouncementBody),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
