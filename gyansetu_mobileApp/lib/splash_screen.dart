import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,  // Or your preferred background color
      body: Center(
        child: Image.asset(
          'assets/images/app_logo.png',
          width: 200,  // Adjust size as needed
          height: 200,
        ),
      ),
    );
  }
} 