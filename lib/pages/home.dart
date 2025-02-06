import 'package:flutter/material.dart';
import 'package:staapp2025/models/cafemenuitem.dart';
import 'package:staapp2025/theme/styles.dart';
import 'package:staapp2025/widgets/announcements.dart';
import 'package:staapp2025/widgets/cafeitems.dart';
import 'package:staapp2025/widgets/welcome.dart';
import 'package:staapp2025/models/announcement.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Test announcement dummy data
    List<Announcement> data = [];
    data.add(const Announcement(title: 'Choir', content: 'No practice!!!'));
    data.add(const Announcement(title: 'Band', content: 'No practice!!!'));
    data.add(
        const Announcement(title: 'App Dev', content: 'Keep practicing!!!'));
    data.add(const Announcement(title: 'Japang', content: 'Coming Soon!!!'));
    data.add(const Announcement(title: 'Choir', content: 'No practice!!!'));
    data.add(const Announcement(title: 'Band', content: 'No practice!!!'));
    data.add(
        const Announcement(title: 'App Dev', content: 'Keep practicing!!!'));
    data.add(const Announcement(title: 'Japang', content: 'Coming Soon!!!'));
    data.add(const Announcement(title: 'Choir', content: 'No practice!!!'));
    data.add(const Announcement(title: 'Band', content: 'No practice!!!'));
    data.add(
        const Announcement(title: 'App Dev', content: 'Keep practicing!!!'));
    data.add(const Announcement(title: 'Japang', content: 'Coming Soon!!!'));

    List<CafeMenuItem> menuitems = [];
    menuitems.add(const CafeMenuItem(
        name: 'pizza',
        price: 3.99,
        pictureUrl:
            'https://firebasestorage.googleapis.com/v0/b/staugustinechsapp.appspot.com/o/newCafeMenuItems%2FPizza.jpg?alt=media&token=25f12b06-65ca-408f-84d6-d2ef62752ccf'));

    // Ignore the OS safearea
    return SafeArea(
      top: true,
      left: true,
      right: true,
      bottom: true,
      // Create a stack and expand the contents?
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Create a listview that is scrollable
          ListView(
            // Allow Scroll physics
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: Styles.mainHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: Styles.mainVerticalPadding),
                    WelcomeBanner(
                      dayNumber: 1,
                      userName: 'Cadawas',
                    ),
                    SizedBox(height: Styles.mainVerticalPadding),
                    AnnouncementsBoard(
                      announcements: data,
                    ),
                    SizedBox(height: Styles.mainVerticalPadding),
                    CafeItems(title: 'Specials', items: menuitems),
                    SizedBox(height: Styles.mainVerticalPadding),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    /*
    SIMPLE SAMPLE
    return Center(
      child: Scaffold(
        body: Center(
          child: Text('Welcome to the Home Page!', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
    */
  }
}
