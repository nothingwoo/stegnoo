import 'package:final_app/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap; // Go to register page

  const LoginPage({super.key, required this.onTap});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // Sign in function using AuthService
  Future<void> _signIn() async {
    try {
      await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Show success message on successful sign-in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful!')),
      );
      // Navigate to the home screen or other page after successful login
    } on Exception catch (e) {
      // Show error message if there's an issue during sign-in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212), // Dark background similar to WhatsApp's dark mode
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Icon(
              Icons.message,
              size: 100,
              color: Colors.white, // Light icon color for contrast
            ),
            const SizedBox(height: 30),

            // Welcome message
            Text(
              "Welcome Back!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for better contrast
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Please log in to continue.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70, // Slightly faded white for subtext
              ),
            ),
            const SizedBox(height: 40),

            // Email text field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.white70), // Lighter text color for labels
                filled: true,
                fillColor: Color(0xFF2C2F34), // Dark background for input fields
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white30),
                ),
                prefixIcon: Icon(Icons.email, color: Colors.white70),
              ),
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: Colors.white), // White text inside input fields
            ),
            const SizedBox(height: 20),  

            // Password text field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2C2F34),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                prefixIcon:const  Icon(Icons.lock, color: Colors.white70),
              ),
              obscureText: true,
              style: const TextStyle(color: Colors.white), // White text inside input fields
            ),
            const SizedBox(height: 30),

            // Login button
            ElevatedButton(
              onPressed: _signIn,
              child: const Text("Log In"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Color(0xFF25D366), padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            // Register now
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                TextButton(
                  onPressed: widget.onTap, // Toggle to the registration page
                  child: const Text("Register Now", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
