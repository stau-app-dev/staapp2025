import 'package:flutter/material.dart';
import 'package:staapp2025/common/styles.dart';
import 'package:staapp2025/features/home/ui/homeblocks.dart';

class HomePage extends StatelessWidget {
  // Accept an optional GlobalKey so callers (e.g. main.dart) can refresh
  // the AnnouncementsBlock without needing its private State type.
  final GlobalKey? announcementsKey;

  const HomePage({super.key, this.announcementsKey});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(kPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const WelcomeBlock(),
            const SizedBox(height: kPage),
            AnnouncementsBlock(key: announcementsKey),
            const SizedBox(height: kPage),
            const SpiritMeterBlock(),
            const SizedBox(height: kPage),
            const ChaplaincyBlock(),
          ],
        ),
      ),
    );
  }
}
