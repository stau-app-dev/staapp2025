import 'package:flutter/material.dart';

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