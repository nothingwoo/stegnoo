import 'package:final_app/services/auth/auth_gate.dart';
// import 'package:final_app/auth/login_or_register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/light_mode.dart';
import 'firebase_options.dart';

void main() async {
  // Ensures all necessary bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the provided options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disables the debug banner
      home:  const AuthGate(), // Sets LoginOrRegister as the initial page
      theme: lighted, // Applies the light theme
    );
  }
}
