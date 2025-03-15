import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:flutter/material.dart';

class ChatServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get all users stream
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  // Send a message with additional metadata
  Future<void> sendMessage(String receiverId, String message,
      {required bool isImage}) async {
    final String senderId = getCurrentUserId() ?? '';
    final String senderEmail = _auth.currentUser?.email ?? '';

    // Get the current timestamp
    final timestamp = FieldValue.serverTimestamp();

    // Create message data
    Map<String, dynamic> messageData = {
      "senderId": senderId,
      "senderEmail": senderEmail,
      "receiverId": receiverId,
      "message": message,
      "timestamp": timestamp,
      "isRead": false,
    };

    // Add message to both users' chat collections
    await _firestore
        .collection('chats')
        .doc(getChatRoomId(senderId, receiverId))
        .collection('messages')
        .add(messageData);
  }

  // Get chat room ID
  String getChatRoomId(String user1Id, String user2Id) {
    // Sort IDs to ensure consistent chat room ID
    List<String> ids = [user1Id, user2Id];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Get messages between two users with better organization
  Stream<QuerySnapshot> getMessages(String receiverId, String senderId) {
    return _firestore
        .collection('chats')
        .doc(getChatRoomId(senderId, receiverId))
        .collection('messages')
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId, String receiverId) async {
    final String senderId = getCurrentUserId() ?? '';
    await _firestore
        .collection('chats')
        .doc(getChatRoomId(senderId, receiverId))
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  // Delete message
  Future<void> deleteMessage(String messageId, String receiverId) async {
    final String senderId = getCurrentUserId() ?? '';
    await _firestore
        .collection('chats')
        .doc(getChatRoomId(senderId, receiverId))
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>?;
  }
}
