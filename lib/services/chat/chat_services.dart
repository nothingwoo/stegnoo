import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
<<<<<<< HEAD
=======
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
>>>>>>> e8d6f575db687a5e90b06e89566e0900e7355c7f

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

  // Send a message with support for text and image messages
  Future<void> sendMessage(String receiverId, String content,
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
      "message": content,
      "isImage": isImage,
      "timestamp": timestamp,
      "isRead": false,
      "isDeleted": false, // New field for tracking deletions
    };

    try {
      await _firestore
          .collection('chats')
          .doc(getChatRoomId(senderId, receiverId))
          .collection('messages')
          .add(messageData);
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  // Get chat room ID
  String getChatRoomId(String user1Id, String user2Id) {
    List<String> ids = [user1Id, user2Id];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

<<<<<<< HEAD
  // Get messages between two users
  Stream<QuerySnapshot> getMessages(String receiverId, String senderId) {
    return _firestore
=======
  // Get messages with optional image filtering
  Stream<QuerySnapshot> getMessages(String receiverId, String senderId,
      {bool showImagesOnly = false}) {
    Query query = _firestore
>>>>>>> e8d6f575db687a5e90b06e89566e0900e7355c7f
        .collection('chats')
        .doc(getChatRoomId(senderId, receiverId))
        .collection('messages')
        .orderBy("timestamp", descending: false);

    if (showImagesOnly) {
      query = query.where('isImage', isEqualTo: true);
    }

    return query.snapshots();
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

<<<<<<< HEAD
  // Delete message for "Me" or "Everyone"
  Future<void> deleteMessage(String messageId, String receiverId, bool deleteForEveryone) async {
    final String senderId = getCurrentUserId() ?? '';

    DocumentReference messageRef = _firestore
        .collection('chats')
        .doc(getChatRoomId(senderId, receiverId))
        .collection('messages')
        .doc(messageId);

    DocumentSnapshot messageSnapshot = await messageRef.get();

    if (messageSnapshot.exists) {
      Map<String, dynamic> messageData = messageSnapshot.data() as Map<String, dynamic>;

      if (deleteForEveryone) {
        // Delete the message for everyone
        await messageRef.delete();
      } else {
        // Mark the message as deleted instead of deleting it fully
        await messageRef.update({"isDeleted": true});
      }
=======
  // Delete message (with optional image deletion)
  Future<void> deleteMessage(String messageId, String receiverId,
      {String? imageUrl}) async {
    final String senderId = getCurrentUserId() ?? '';

    try {
      await _firestore
          .collection('chats')
          .doc(getChatRoomId(senderId, receiverId))
          .collection('messages')
          .doc(messageId)
          .delete();

      if (imageUrl != null && imageUrl.isNotEmpty) {
        await firebase_storage.FirebaseStorage.instance
            .refFromURL(imageUrl)
            .delete();
      }
    } catch (e) {
      print('Error deleting message: $e');
      throw Exception('Failed to delete message');
>>>>>>> e8d6f575db687a5e90b06e89566e0900e7355c7f
    }
  }

  // Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>?;
  }
}
