import 'package:flutter/material.dart';

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