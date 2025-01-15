import 'package:flutter/material.dart';

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