import 'package:flutter/material.dart';
import 'package:staapp2025/theme/styles.dart';
import 'package:staapp2025/widgets/welcome.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
              parent: AlwaysScrollableScrollPhysics()
            ),
            children: <Widget>[
              Flexible(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Styles.mainHorizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: Styles.mainVerticalPadding),
                        WelcomeBanner(
                          dayNumber: 1,
                          userName: 'Cadawas',
                        ),

                      ],
                    ),
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