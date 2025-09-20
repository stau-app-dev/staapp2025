import 'package:flutter/material.dart';
import 'package:staapp2025/common/styles.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/features/auth/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:staapp2025/widgets/error_card.dart';
import 'package:staapp2025/features/home/data.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAnnouncements();
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
      final parsed = await fetchAnnouncements();
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
    final auth = Provider.of<AuthService>(context);
    final userEmail = auth.email ?? '';
    final canAdd =
        auth.isSignedIn && userEmail.toLowerCase().endsWith('ycdsb.ca');

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
                onPressed: () async {
                  final ok = await ensureSignedIn(context);
                  if (!ok) return;
                  final authNow = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  final emailNow = (authNow.email ?? '').toLowerCase();
                  if (!emailNow.endsWith('ycdsb.ca')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Only staff (ycdsb.ca) can add announcements.',
                        ),
                      ),
                    );
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final url = await fetchAnnouncementFormUrl();
                    if (url == null || url.trim().isEmpty) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Form URL unavailable')),
                      );
                      return;
                    }
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
                      }
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Could not open form URL')),
                      );
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to open form: ${e.toString()}'),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.add),
                label: Text('Add Announcement'),
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
