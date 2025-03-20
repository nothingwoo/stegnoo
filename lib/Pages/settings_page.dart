import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main.dart';
import 'account_page.dart'; // Import the AccountPage

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  io.File? _image;
  XFile? _pickedFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _profileImageUrl;
  bool _isDNDEnabled = false; // State for Don't Disturb toggle

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadDNDPreference(); // Load Don't Disturb preference
  }

  // Load existing profile image URL from Firestore
  Future<void> _loadProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists && docSnapshot.data()!.containsKey('profilePicUrl')) {
          setState(() {
            _profileImageUrl = docSnapshot.data()!['profilePicUrl'];
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  // Load Don't Disturb preference from Firestore
  Future<void> _loadDNDPreference() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists && docSnapshot.data()!.containsKey('isDNDEnabled')) {
          setState(() {
            _isDNDEnabled = docSnapshot.data()!['isDNDEnabled'];
          });
        }
      }
    } catch (e) {
      print('Error loading Don\'t Disturb preference: $e');
    }
  }

  // Save Don't Disturb preference to Firestore
  Future<void> _saveDNDPreference(bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isDNDEnabled': value,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving Don\'t Disturb preference: $e');
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedFile = pickedFile;
          if (!kIsWeb) {
            _image = io.File(pickedFile.path);
          }
        });

        // Upload image to Firebase when picked
        _uploadImageToFirebase();
      }
    } catch (e) {
      print('Error picking image: $e');

      // More specific error handling
      String errorMessage = 'Error selecting image';
      if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please grant access to your photos';
      } else if (e.toString().contains('unsupported operation')) {
        errorMessage = 'This operation is not supported on your device';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  // Upload image to Firebase Storage and save URL to Firestore
  Future<void> _uploadImageToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _pickedFile == null) return;

    try {
      setState(() {
        _isUploading = true;
      });

      // Create storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload file - handle web differently
      UploadTask uploadTask;

      if (kIsWeb) {
        // For web, we need to read the file as bytes
        final bytes = await _pickedFile!.readAsBytes();
        uploadTask = storageRef.putData(bytes);
      } else {
        // For mobile, we can put the file directly
        uploadTask = storageRef.putFile(_image!);
      }

      // Get download URL after upload completes
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save URL to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profilePicUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update local state
      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
      print('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      if (_isUploading)
                        const CircularProgressIndicator(color: Colors.white),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _isUploading ? null : _pickImage,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Profile Picture',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Settings Options
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Dark Mode
                ListTile(
                  visualDensity: VisualDensity.compact, // Compact mode
                  leading: Icon(Icons.dark_mode, color: themeProvider.isDarkMode ? Colors.white : Colors.black87),
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // Don't Disturb
                ListTile(
                  visualDensity: VisualDensity.compact, // Compact mode
                  leading: Icon(Icons.notifications_off, color: themeProvider.isDarkMode ? Colors.white : Colors.black87),
                  title: Text(
                    'Don\'t Disturb',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: Switch(
                    value: _isDNDEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _isDNDEnabled = value;
                      });
                      await _saveDNDPreference(value);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // Account
                ListTile(
                  visualDensity: VisualDensity.compact, // Compact mode
                  leading: Icon(Icons.account_circle, color: themeProvider.isDarkMode ? Colors.white : Colors.black87),
                  title: Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AccountPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.grey[200],
    );
  }
}