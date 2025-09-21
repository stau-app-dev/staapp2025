import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const StaApp());
}

class StaApp extends StatelessWidget {
  const StaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'St. Augustine CHS',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF8B1534),
        ), // sampled maroon
        scaffoldBackgroundColor: Color(
          0xFFF6F6F6,
        ), // slightly lighter background
      ),
      home: const HomeScreen(),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WelcomeBlock(),
                SizedBox(height: 16),
                AnnouncementsBlock(),
                SizedBox(height: 16),
                CafeteriaBlock(),
                SizedBox(height: 16),
                SpiritMeterBlock(),
                SizedBox(height: 16),
                ChaplaincyBlock(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF8B1534), // sampled maroon
        selectedItemColor: Color(0xFFFFD600), // sampled gold
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Cafeteria',
          ),
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

class WelcomeBlock extends StatefulWidget {
  const WelcomeBlock({super.key});

  @override
  State<WelcomeBlock> createState() => _WelcomeBlockState();
}

class _WelcomeBlockState extends State<WelcomeBlock> {
  int? dayNumber;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDayNumber();
  }

  Future<void> _fetchDayNumber() async {
    const url =
        'https://us-central1-staugustinechsapp.cloudfunctions.net/getDayNumber';
    try {
      final resp = await http.get(Uri.parse(url)).timeout(Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        final dn = body['data']?['dayNumber'];
        if (dn is int) {
          setState(() {
            dayNumber = dn;
            loading = false;
          });
          return;
        }
      }
    } catch (e) {
      // ignore, fallback below
    }
    // fallback: leave null and stop loading
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate = DateFormat('MMMM d, yyyy').format(today);
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF8B1534), // sampled maroon
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Color(0xFFE6B800),
          width: 2,
        ), // deeper gold, thinner border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to St. Augustine',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    if (loading) ...[
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        'Today is a beautiful day ${dayNumber ?? '?'}',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.asset(
              'assets/logos/sta_logo.png',
              width: 76,
              height: 76,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.school, size: 48, color: Color(0xFF971B36)),
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementsBlock extends StatelessWidget {
  final List<Map<String, String>> announcements = const [
    {
      'title': 'Varsity Girls Basketball',
      'body':
          'All girls in gr. 9-12 interested in trying out for girls basketball team are asked to check the poster outside of room 216 at the top of the foyer stairs for more information',
    },
    {
      'title': 'Senior Boys Soccer',
      'body':
          'Tryouts for the Senior Boys Soccer team will begin on Fri Sept 4th. Join the Google Classroom using the code (6fzaopqa) found on the poster in front of Room 221. Permission Form required.',
    },
    {
      'title': 'St. Augustine Concert Band',
      'body':
          'Interested in joining the St. Augustine Concert Band? There will be a meeting for information about auditions this Thursday, September 4, after school in room 115. See you there!',
    },
    {
      'title': 'Girls Golf Team',
      'body':
          'All girls interested in joining the Girls Golf Team, see the Phys Ed office for more information.',
    },
    {
      'title': 'STA',
      'body':
          'Want these morning announcements on your devices? Want to know if it is day 1 or 2? Goto staugustinechs.ca now!',
    },
  ];

  const AnnouncementsBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Announcements Board',
            style: TextStyle(
              color: Color(0xFF971B36),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          SizedBox(height: 12),
          ...announcements.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF8B1534), width: 1),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['title']!,
                            style: TextStyle(
                              color: Color(0xFF971B36),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            a['body']!,
                            style: TextStyle(
                              color: Color(0xFF971B36),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CafeteriaBlock extends StatelessWidget {
  final List<Map<String, String>> specials = const [
    {'name': 'Burger with Fries', 'image': ''},
    {'name': 'Chicken Burger', 'image': ''},
    {
      'name': 'Fries',
      'image':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
    },
  ];

  const CafeteriaBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Cafe Items',
                style: TextStyle(
                  color: Color(0xFF971B36),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                'View More >',
                style: TextStyle(
                  color: Color(0xFFFFD600),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: specials.length,
              separatorBuilder: (context, index) => SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = specials[index];
                return Container(
                  width: 110,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF8B1534), width: 2),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: item['image']!.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    'Image Unavailable',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                                child: Image.network(
                                  item['image']!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 70,
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          item['name']!,
                          style: TextStyle(
                            color: Color(0xFF971B36),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SpiritMeterBlock extends StatelessWidget {
  final Map<String, double> spiritLevels = const {
    '9': 0.7,
    '10': 0.5,
    '11': 0.4,
    '12': 0.9,
  };

  const SpiritMeterBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spirit Meter',
            style: TextStyle(
              color: Color(0xFF8B1534),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 12),
          ...spiritLevels.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: Color(0xFF8B1534),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: entry.value,
                      minHeight: 10,
                      backgroundColor: Color(0xFFFFF9C4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFD600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChaplaincyBlock extends StatelessWidget {
  const ChaplaincyBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chaplaincy Corner',
            style: TextStyle(
              color: Color(0xFF971B36),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFF8B1534), width: 1),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verse of The Day',
                  style: TextStyle(
                    color: Color(0xFF8B1534),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'What you heard from me, keep as the pattern of sound teaching, with faith and love in Christ Jesus. Guard the good deposit that was entrusted to you—guard it with the help of the Holy Spirit who lives in us.',
                  style: TextStyle(color: Color(0xFF8B1534), fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
