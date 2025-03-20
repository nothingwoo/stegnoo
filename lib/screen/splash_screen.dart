import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Navigate to login page after splash
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login'); // Change '/login' to your actual login route
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fixed black background
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.message_rounded, size: 100, color: Colors.white), // Replace with your logo
              SizedBox(height: 10),
              Text(
                "Stego",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}