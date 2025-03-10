import 'package:final_app/Pages/login_page.dart';
import 'package:final_app/Pages/register_page.dart';
import 'package:flutter/material.dart';
 // Import the RegistrationPage

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({Key? key}) : super(key: key);

  @override
  _LoginOrRegisterState createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool _isLoginPage = true; // Track the current screen (login or register)

  // Toggle between login and registration
  void _togglePage() {
    setState(() {
      _isLoginPage = !_isLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoginPage
        ? LoginPage(onTap: _togglePage) // Show LoginPage
        : RegistrationPage(onTap: _togglePage); // Show RegistrationPage
  }
}
