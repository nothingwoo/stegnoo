import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main.dart';

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
  
  @override
  void initState() {
    super.initState();
    _loadProfileImage();
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
        SnackBar(content: Text(errorMessage))
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
        const SnackBar(content: Text('Profile picture updated successfully!'))
      );
      
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e'))
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
        elevation: 4,
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image Section
            Center(
              child: Stack(
                children: [
                  // Profile image with loading indicator
                  if (_isUploading)
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: const CircularProgressIndicator(),
                    )
                  else if (_profileImageUrl != null)
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: NetworkImage(_profileImageUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                  
                  // Camera icon for picking image
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: _isUploading 
                            ? Colors.grey 
                            : Colors.blueAccent,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dark Mode Toggle
            Container(
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.black54 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ListTile(
                leading: Icon(Icons.dark_mode, color: themeProvider.isDarkMode ? Colors.white : Colors.black87),
                title: const Text(
                  'Dark Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.grey[200],
    );
  }
}