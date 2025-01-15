import 'package:flutter/material.dart';

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