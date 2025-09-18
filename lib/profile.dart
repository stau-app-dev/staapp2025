import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/styles.dart';
import 'package:staapp2025/auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final displayName = auth.displayName ?? '';
    final email = auth.email ?? '';
    final photoUrl = auth.photoUrl;

    // Helper to derive a deterministic pastel color from a string (name/email)
    Color deterministicPastel(String key) {
      final hash = key.runes.fold<int>(0, (p, c) => (p * 31 + c) & 0x7fffffff);
      final r = (hash & 0xFF0000) >> 16;
      final g = (hash & 0x00FF00) >> 8;
      final b = (hash & 0x0000FF);
      // mix with white to make pastel
      final mix = 180;
      final rr = ((r + mix) ~/ 2).clamp(0, 255);
      final gg = ((g + mix) ~/ 2).clamp(0, 255);
      final bb = ((b + mix) ~/ 2).clamp(0, 255);
      return Color.fromARGB(255, rr, gg, bb);
    }

    // Helper to build avatar: network photo if available, otherwise first initial in CircleAvatar.
    Widget avatar() {
      if (photoUrl != null && photoUrl.isNotEmpty) {
        return ClipOval(
          child: Image.network(
            photoUrl,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                Icon(Icons.school, size: 64, color: kMaroonAccent),
          ),
        );
      }

      final nameKey = (displayName.isNotEmpty ? displayName : email).isNotEmpty
          ? (displayName.isNotEmpty ? displayName : email)
          : 'A';
      final firstInitial = nameKey.trim().isNotEmpty
          ? nameKey.trim().split(RegExp(r"\s+"))[0][0].toUpperCase()
          : 'A';
      final bg = deterministicPastel(nameKey);

      return CircleAvatar(
        radius: 60,
        backgroundColor: bg,
        child: Text(
          firstInitial,
          style: TextStyle(fontSize: 40, color: Colors.white),
        ),
      );
    }

    // (display name parsing handled inline where needed)

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(kPage),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: kWelcomeBannerDecoration,
              padding: const EdgeInsets.symmetric(
                vertical: mainVerticalPadding,
                horizontal: mainHorizontalPadding,
              ),
              child: Column(
                children: [
                  // Avatar with gold border ring
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kGold, width: 4),
                    ),
                    child: ClipOval(
                      child: SizedBox(width: 120, height: 120, child: avatar()),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    displayName.isNotEmpty ? displayName : 'No name',
                    style: kWelcomeTitle.copyWith(color: kWhite),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(email, style: kWelcomeBody.copyWith(color: kWhite)),
                  SizedBox(height: 12),
                  // Logout button below the email
                  ElevatedButton.icon(
                    onPressed: auth.isSignedIn
                        ? () async {
                            await auth.signOut();
                          }
                        : null,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: kWhite,
                      padding: kButtonPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius: mainBorderRadius,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Add a small spacer so bottom nav doesn't overlap content
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
