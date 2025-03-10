import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Instance of FirebaseAuth
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

      // Optionally, you can fetch user data from Firestore here
      // DocumentSnapshot userDoc = await _firestore.collection("users").doc(userCredential.user!.uid).get();

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
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error during sign-out: $e');
    }
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
