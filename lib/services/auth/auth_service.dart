import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user status to online
      await updateUserStatusOnline(userCredential.user!.uid);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Error during sign-in: ${e.message}');
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailPassword(String email, String password, String username) async {
    try {
      // Create user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user info in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set(
        {
          'uid': userCredential.user!.uid,
          'email': email,
          'username': username, // Store the username
          'isOnline': true, // Set user status to online
          'lastSeen': FieldValue.serverTimestamp(), // Track last seen time
          'createdAt': FieldValue.serverTimestamp(), // Optional: track account creation time
        },
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Error during registration: ${e.message}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update user status to offline
        await updateUserStatusOffline(user.uid);
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error during sign-out: $e');
    }
  }

  // Update user status to online
  Future<void> updateUserStatusOnline(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Update user status to offline
  Future<void> updateUserStatusOffline(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Get currently signed-in user
  User? get currentUser => _auth.currentUser;

  // Error handling
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'The email is already registered.';
      default:
        return 'An unknown error occurred.';
    }
  }
}