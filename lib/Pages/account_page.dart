import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isUpdatingUsername = false;
  bool _isUpdatingPassword = false;
  bool _isSendingVerification = false;
  bool _isRefreshing = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user data when returning to this page
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Load both username and email with refreshed verification status
  Future<void> _loadUserData() async {
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Reload the user to get the latest verification status
        await user.reload();
        final refreshedUser = _auth.currentUser;
        
        // Set email from FirebaseAuth
        setState(() {
          _emailController.text = refreshedUser?.email ?? '';
        });
        
        // Get username from Firestore
        try {
          final docSnapshot = await _firestore.collection('users').doc(refreshedUser?.uid).get();
          if (docSnapshot.exists && docSnapshot.data()!.containsKey('username')) {
            setState(() {
              _usernameController.text = docSnapshot.data()!['username'];
            });
          }
        } catch (e) {
          print('Error loading user data: $e');
        }
      }
    } catch (e) {
      print('Error refreshing user: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  // Update username in Firestore
  Future<void> _updateUsername() async {
    final user = _auth.currentUser;
    if (user == null || _usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid username')),
      );
      return;
    }

    setState(() {
      _isUpdatingUsername = true;
    });

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'username': _usernameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating username: $e')),
      );
    } finally {
      setState(() {
        _isUpdatingUsername = false;
      });
    }
  }

  // Send verification email
  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isSendingVerification = true;
    });

    try {
      await _auth.currentUser!.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending verification email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSendingVerification = false;
      });
    }
  }

  // Update password in Firebase Auth
  Future<void> _updatePassword() async {
    // Clear any previous error messages
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is signed in')),
      );
      return;
    }
    
    // Validate input fields
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all password fields')),
      );
      return;
    }
    
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters')),
      );
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
    });

    try {
      // Get current email
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'no-email',
          message: 'No email associated with this account'
        );
      }
      
      // Create credential with current email and password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      
      // Reauthenticate user
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      // Clear password fields on success
      _currentPasswordController.clear();
      _newPasswordController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'The current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'The new password is too weak';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please sign out and sign in again to update your password';
          break;
        case 'user-mismatch':
          errorMessage = 'The provided credentials do not match the current user';
          break;
        case 'user-not-found':
          errorMessage = 'User not found';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials provided';
          break;
        default:
          errorMessage = 'Error updating password: ${e.message}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      
      print('FirebaseAuthException: ${e.code} - ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Unexpected error during password update: $e');
    } finally {
      setState(() {
        _isUpdatingPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _loadUserData,
            icon: _isRefreshing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh account status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Account',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text('Email: ${_emailController.text}'),
                      const SizedBox(height: 5),
                      if (_auth.currentUser != null)
                        Row(
                          children: [
                            Icon(
                              _auth.currentUser!.emailVerified ? Icons.verified : Icons.warning,
                              color: _auth.currentUser!.emailVerified ? Colors.green : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _auth.currentUser!.emailVerified
                                  ? 'Email verified'
                                  : 'Email not verified',
                              style: TextStyle(
                                color: _auth.currentUser!.emailVerified ? Colors.green : Colors.orange,
                              ),
                            ),
                            const Spacer(),
                            if (!_auth.currentUser!.emailVerified)
                              TextButton(
                                onPressed: _isSendingVerification ? null : _sendVerificationEmail,
                                child: _isSendingVerification
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Send Verification Email'),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            
              // Update Username Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Username',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdatingUsername ? null : _updateUsername,
                          child: _isUpdatingUsername
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Update Username'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Update Password Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Password',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_open),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          helperText: 'Password must be at least 6 characters',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdatingPassword ? null : _updatePassword,
                          child: _isUpdatingPassword
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Update Password'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}