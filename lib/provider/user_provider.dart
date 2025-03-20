import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  String? _profileImageUrl; // Store the profile picture URL

  String? get profileImageUrl => _profileImageUrl; // Getter

  // Load user profile image when the app starts
  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists && docSnapshot.data()!.containsKey('profilePicUrl')) {
        _profileImageUrl = docSnapshot.data()!['profilePicUrl'];
        notifyListeners(); // Notify all UI components using this provider
      }
    }
  }

  // Update the profile picture URL and notify all listeners
  void updateProfileImage(String newUrl) {
    _profileImageUrl = newUrl;
    notifyListeners();
  }
}
