import 'package:flutter/material.dart';
import 'package:staapp2025/theme/theme.dart';
import 'package:staapp2025/theme/styles.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'St Augustie CHS',
      theme: appThemeData,
      home: const MyHomePage(title: 'St Augustine CHS'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PageController pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        children: const <Widget>[
          Center(
            child: Home(),
          ),
          Center(
            child: CafeteriaMenu(),
          ),
          Center(
            child: SongRequests(),
          ),
          Center(
            child: Profile(),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Styles.primary,
            selectedItemColor: Styles.secondary,
            unselectedItemColor: Styles.white,
            showSelectedLabels: false,
            showUnselectedLabels: false,            
            onTap: (index) {
              setState(() {
                pageController.jumpToPage(index);
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_pizza),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
                label: '',
              ),
            ],            
        ),
      ),
    );
  }
}
class Home extends StatelessWidget {
    const Home({super.key});

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Hello World Everybody',
            ),
            const Text(
              'HOME',
            ),
          ],
        ),
      );
    }
}

class CafeteriaMenu extends StatelessWidget {
    const CafeteriaMenu({super.key});

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Hello World Everybody',
            ),
            const Text(
              'CAFETERIA MENU',
            ),
          ],
        ),
      );
    }
}

class SongRequests extends StatelessWidget {
    const SongRequests({super.key});

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Hello World Everybody',
            ),
            const Text(
              'SONG REQUESTS',
            ),
          ],
        ),
      );
    }
}

class Profile extends StatelessWidget {
    const Profile({super.key});

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Hello World Everybody',
            ),
            const Text(
              'Profile',
            ),
          ],
        ),
      );
    }
}

