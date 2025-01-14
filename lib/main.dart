import 'package:flutter/material.dart';
import 'package:staapp2025/theme/theme.dart';
import 'package:staapp2025/theme/styles.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'St Augustie CHS',
      theme: appThemeData,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();  
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    CafeteriaMenuPage(),
    SongRequestsPage(),
    ProfilePage(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Styles.primary,
        selectedItemColor: Styles.secondary,
        unselectedItemColor: Styles.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,            


        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Cafeteria Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Song Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Center(
          child: Text('Welcome to the Home Page!', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class CafeteriaMenuPage extends StatelessWidget {
  const CafeteriaMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Center(
          child: Text('Check out our delicious menu!', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class SongRequestsPage extends StatelessWidget {
  const SongRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Center(
          child: Text('Request your favorite songs!', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Center(
          child: Text('View and edit your profile.', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

