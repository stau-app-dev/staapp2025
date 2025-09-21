import 'package:flutter/material.dart';
import 'core/firebase_bootstrap.dart';
// You can still import shared styles/theme directly, or via common/ barrels.
import 'common/styles.dart';
import 'common/theme.dart';
// Feature UI imports (direct, after removing forwarder files)
import 'package:staapp2025/features/home/ui/home.dart';
import 'package:staapp2025/features/home/ui/homeblocks.dart';
import 'package:staapp2025/features/song_requests/ui/song_requests_page.dart';
import 'package:staapp2025/features/profile/ui/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/features/auth/auth_service.dart';
import 'package:staapp2025/features/auth/guard.dart';
import 'package:staapp2025/common/pwa.dart' as pwa;

// no async zone hacks to avoid zone mismatch errors

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Also print to console for visibility.
    // In debug we keep failing, in release we'd report.
    // ignore: avoid_print
    print('FlutterError: \\n${details.exceptionAsString()}\\n${details.stack}');
  };
  try {
    await bootstrapFirebase();
  } catch (e, st) {
    // ignore: avoid_print
    print('bootstrapFirebase failed: $e');
    // ignore: avoid_print
    print(st);
  }
  // Firebase initialized
  runApp(const StaApp());
}

class StaApp extends StatelessWidget {
  const StaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final s = AuthService();
        s.init();
        return s;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'St. Augustine CHS',
        theme: appThemeData.copyWith(scaffoldBackgroundColor: kBackground),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<AnnouncementsBlockState> _announcementsKey =
      GlobalKey<AnnouncementsBlockState>();

  @override
  void initState() {
    super.initState();
    // After the first frame, ensure the AuthService attempts to refresh the
    // remote profile. This ensures songRequestCount/songUpvoteCount are
    // loaded early when the app starts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      // Fire-and-forget; refreshRemoteUser is safe when not signed in.
      auth.refreshRemoteUser(caller: 'home.init');
    });
  }

  void _onItemTapped(int index) {
    _handleNavigation(index);
  }

  Future<void> _handleNavigation(int index) async {
    if (index == 0) {
      setState(() {
        _selectedIndex = index;
      });
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isSignedIn) {
      // Use guard helper to handle login flow
      final ok = await ensureSignedIn(context);
      if (!mounted || !ok) return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // If the user navigated to the Song Requests page, refresh the remote
    // profile so the counters displayed there are up-to-date.
    // Redundant with songs.init (page-owned refresh), so skip here
    // if (index == 1) {
    //   final auth = Provider.of<AuthService>(context, listen: false);
    //   auth.refreshRemoteUser(caller: 'home.navToSongs');
    // }
  }

  @override
  Widget build(BuildContext context) {
    final extraBottom = pwa.extraNavBarBottomPadding();
    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final pages = <Widget>[
              // HomePage now lives in lib/home.dart and accepts the key so
              // the parent can trigger a refresh on the AnnouncementsBlock.
              HomePage(announcementsKey: _announcementsKey),
              const SongRequestsPage(),
              const ProfilePage(),
            ];

            final current = pages[_selectedIndex];

            // Wrap only the HomePage with RefreshIndicator so pull-to-refresh
            // works and delegates to the announcements key.
            if (_selectedIndex == 0) {
              return RefreshIndicator(
                onRefresh: () async {
                  final state = _announcementsKey.currentState;
                  if (state != null) {
                    await (state as dynamic).refreshAnnouncements();
                  }
                },
                child: current,
              );
            }

            return current;
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: kMaroon,
        padding: EdgeInsets.only(bottom: extraBottom),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: kMaroon, // sampled maroon
          elevation: extraBottom > 0 ? 0 : 8,
          selectedItemColor: kGold, // sampled gold
          unselectedItemColor: kWhite,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note),
              label: 'Song Requests',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// Block widgets (WelcomeBlock, AnnouncementsBlock, SpiritMeterBlock,
// ChaplaincyBlock) were moved to lib/widgets/homeblocks/ to remove duplication.
