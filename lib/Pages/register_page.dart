import 'package:flutter/material.dart';
import 'package:final_app/services/auth/auth_service.dart';

class RegistrationPage extends StatefulWidget {
  final void Function()? onTap; // Go to login page

  const RegistrationPage({super.key, required this.onTap});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _isPasswordFocused = false;
  final FocusNode _passwordFocusNode = FocusNode();

  // Password rules and their validation functions
  final List<Map<String, dynamic>> _passwordRules = [
    {
      'rule': 'At least 8 characters',
      'validator': (String password) => password.length >= 8,
    },
    {
      'rule': 'Contains an uppercase letter',
      'validator': (String password) => password.contains(RegExp(r'[A-Z]')),
    },
    {
      'rule': 'Contains a number',
      'validator': (String password) => password.contains(RegExp(r'[0-9]')),
    },
    {
      'rule': 'Contains a special character',
      'validator': (String password) => password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    },
    {
      'rule': 'Does not contain email name',
      'validator': (String password, String email) {
        if (email.isEmpty) return true;
        String emailName = email.split('@')[0];
        for (int i = 0; i < emailName.length - 2; i++) {
          if (password.toLowerCase().contains(emailName.substring(i, i + 3).toLowerCase())) {
            return false;
          }
        }
        return true;
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Register function using AuthService
  Future<void> _register() async {
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    // Password validation
    String password = _passwordController.text.trim();
    String email = _emailController.text.trim();
    if (!isValidPassword(password, email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid password format.")),
      );
      return;
    }

    try {
      await _authService.registerWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );
      // Navigate to login screen or home page after registration
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  bool isValidPassword(String password, String email) {
    for (var rule in _passwordRules) {
      if (rule['validator'] is Function) {
        if (rule['validator'] is Function(String, String)) {
          if (!rule['validator'](password, email)) return false;
        } else {
          if (!rule['validator'](password)) return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.app_registration,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 30),
              const Text(
                "Create an Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Fill in the details to get started.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2F34),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onSubmitted: (value) {
                  // Move focus to the next field or call _register
                  FocusScope.of(context).nextFocus();
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2F34),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.white70),
                ),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (value) {
                  // Move focus to the next field or call _register
                  FocusScope.of(context).nextFocus();
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2F34),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: (value) {
                  // Move focus to the next field or call _register
                  FocusScope.of(context).nextFocus();
                },
              ),
              if (_isPasswordFocused)
                Column(
                  children: _passwordRules.map((rule) {
                    bool isValid = rule['validator'] is Function(String, String)
                        ? rule['validator'](_passwordController.text.trim(), _emailController.text.trim())
                        : rule['validator'](_passwordController.text.trim());
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: isValid ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rule['rule'],
                            style: TextStyle(
                              color: isValid ? Colors.green : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2F34),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (value) {
                  // Call the _register function when Enter is pressed
                  _register();
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _register,
                child: const Text("Sign Up"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onTap,
                    child: const Text("Log In", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}