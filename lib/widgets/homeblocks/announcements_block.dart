import 'package:flutter/material.dart';
import 'package:staapp2025/styles.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:staapp2025/widgets/error_card.dart';
import 'package:staapp2025/services/home_service.dart';
import 'dart:async';

class AnnouncementsBlock extends StatefulWidget {
  const AnnouncementsBlock({super.key});

  @override
  State<AnnouncementsBlock> createState() => AnnouncementsBlockState();
}

class AnnouncementsBlockState extends State<AnnouncementsBlock> {
  List<Map<String, String>> announcements = const [
    {'title': 'Titans', 'body': 'No announcements today'},
  ];

  bool _loading = true;
  bool _error = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  // Public method used by parent to refresh announcements (pull-to-refresh)
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
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final userEmail = auth.user?.email ?? '';
    final canAdd = userEmail.toLowerCase().endsWith('ycdsb.ca');

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
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
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
