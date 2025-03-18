import 'package:final_app/Pages/home_page.dart';
import 'package:final_app/services/auth/login_or_register.dart';
import 'package:final_app/services/auth/auth_service.dart'; // Import AuthService
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService(); // Create an instance of AuthService

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;

            if (user != null) {
              // User is logged in
              authService.updateUserStatusOnline(user.uid); // Update status to online
              return HomePage();
            } else {
              // User is logged out
              authService.updateUserStatusOffline(user?.uid ?? ''); // Update status to offline
              return const LoginOrRegister();
            }
          }

          // Show a loading indicator while checking the auth state
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}