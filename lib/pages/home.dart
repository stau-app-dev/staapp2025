import 'package:flutter/material.dart';
import 'package:staapp2025/models/cafemenuitem.dart';
import 'package:staapp2025/models/spirit_meters.dart';
import 'package:staapp2025/theme/styles.dart';
import 'package:staapp2025/widgets/announcements.dart';
import 'package:staapp2025/widgets/cafeitems.dart';
import 'package:staapp2025/widgets/spirit_meter.dart';
import 'package:staapp2025/widgets/welcome.dart';
import 'package:staapp2025/models/announcement.dart';
import 'package:staapp2025/widgets/chaplaincycorner.dart';
import 'package:staapp2025/models/verseofday.dart';

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
    menuitems.add(const CafeMenuItem(
        name: 'pizza',
        price: 3.99,
        pictureUrl:
            'https://firebasestorage.googleapis.com/v0/b/staugustinechsapp.appspot.com/o/newCafeMenuItems%2FPizza.jpg?alt=media&token=25f12b06-65ca-408f-84d6-d2ef62752ccf'));
    menuitems.add(const CafeMenuItem(
        name: 'pizza',
        price: 3.99,
        pictureUrl:
            'https://firebasestorage.googleapis.com/v0/b/staugustinechsapp.appspot.com/o/newCafeMenuItems%2FPizza.jpg?alt=media&token=25f12b06-65ca-408f-84d6-d2ef62752ccf'));

    SpiritMeters gradespirit =
        SpiritMeters(nine: 4, ten: 8, eleven: 16, twelve: 32);

    VerseOfDay todaysverse = VerseOfDay(
        verseOfDay: 'Love is patient.  Love is kind.  Love is never envious.');

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
                    SpiritMeterBars(
                      spiritMeters: gradespirit,
                    ),
                    SizedBox(height: Styles.mainVerticalPadding),
                    ChaplaincyCorner(),
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
