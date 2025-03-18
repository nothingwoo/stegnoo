import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

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

  // Send a message with support for text, image, and video messages
  Future<void> sendMessage(String receiverId, String content,
      {bool isImage = false, bool isVideo = false}) async {
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
      "isVideo": isVideo,
      "timestamp": timestamp,
      "isRead": false,
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

  // Get messages with optional image and video filtering
  Stream<QuerySnapshot> getMessages(String receiverId, String senderId,
      {bool showImagesOnly = false, bool showVideosOnly = false}) {
    Query query = _firestore
        .collection('chats')
        .doc(getChatRoomId(senderId, receiverId))
        .collection('messages')
        .orderBy("timestamp", descending: false);

    if (showImagesOnly) {
      query = query.where('isImage', isEqualTo: true);
    } else if (showVideosOnly) {
      query = query.where('isVideo', isEqualTo: true);
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

  // Delete message (with optional image or video deletion)
  Future<void> deleteMessage(String messageId, String receiverId,
      {String? fileUrl}) async {
    final String senderId = getCurrentUserId() ?? '';

    try {
      await _firestore
          .collection('chats')
          .doc(getChatRoomId(senderId, receiverId))
          .collection('messages')
          .doc(messageId)
          .delete();

      if (fileUrl != null && fileUrl.isNotEmpty) {
        await firebase_storage.FirebaseStorage.instance
            .refFromURL(fileUrl)
            .delete();
      }
    } catch (e) {
      print('Error deleting message: $e');
      throw Exception('Failed to delete message');
    }
  }

  // Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    DocumentSnapshot userDoc =
    await _firestore.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>?;
  }
}