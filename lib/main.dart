import 'package:flutter/material.dart';
// imports for block implementations moved to lib/homeblocks/
import 'styles.dart';
import 'theme.dart';
import 'home.dart';
import 'package:staapp2025/widgets/homeblocks/homeblocks.dart';
import 'songrequests.dart';
import 'profile.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'login_page.dart';

void main() {
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
      auth.refreshRemoteUser();
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
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      if (!mounted) return;
      if (!auth.isSignedIn) return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // If the user navigated to the Song Requests page, refresh the remote
    // profile so the counters displayed there are up-to-date.
    if (index == 1) {
      final auth = Provider.of<AuthService>(context, listen: false);
      auth.refreshRemoteUser();
    }
  }

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: kMaroon, // sampled maroon
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
    );
  }
}

// Block widgets (WelcomeBlock, AnnouncementsBlock, SpiritMeterBlock,
// ChaplaincyBlock) were moved to lib/widgets/homeblocks/ to remove duplication.
