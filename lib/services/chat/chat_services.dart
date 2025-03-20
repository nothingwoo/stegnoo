import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Constants for Firestore collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

  // Get current user ID
  String get currentUserId => _auth.currentUser!.uid;

  // Get a stream of all users except the current user
  Stream<QuerySnapshot> getUsersStream() {
    try {
      return _firestore
          .collection(usersCollection)
          .where('uid', isNotEqualTo: currentUserId)
          .snapshots();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get chat messages between two users
  Stream<QuerySnapshot> getMessages(String receiverId, String currentUserId) {
    try {
      // Create a chat room ID using both user IDs
      String chatRoomId = _getChatRoomId(receiverId, currentUserId);

      return _firestore
          .collection(chatsCollection)
          .doc(chatRoomId)
          .collection(messagesCollection)
          .orderBy('timestamp', descending: false)
          .snapshots();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Send a message to another user
  Future<void> sendMessage(
      String receiverId,
      String message, {
        bool isVideo = false,
        bool isAudio = false,
      }) async {
    try {
      // Get current user info
      final String currentUserId = _auth.currentUser!.uid;
      final Timestamp timestamp = Timestamp.now();

      // Create a chat room ID
      String chatRoomId = _getChatRoomId(receiverId, currentUserId);

      // Add message to Firestore
      await _firestore
          .collection(chatsCollection)
          .doc(chatRoomId)
          .collection(messagesCollection)
          .add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': timestamp,
        'isVideo': isVideo,
        'isAudio': isAudio,
        'isRead': false,  // Changed from 'readStatus' to 'isRead'
      });

      // Update chat room metadata
      await _updateChatRoomMetadata(
        chatRoomId,
        currentUserId,
        receiverId,
        message,
        timestamp,
      );

      // Trigger a notification or update to the receiver
      await _notifyReceiver(receiverId, currentUserId, message);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Notify the receiver about the new message
  Future<void> _notifyReceiver(String receiverId, String senderId, String message) async {
    try {
      // Update the receiver's notification status
      await _firestore
          .collection(usersCollection)
          .doc(receiverId)
          .update({
        'hasNewMessage': true,
        'lastMessageFrom': senderId,
        'lastMessageTimestamp': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to notify receiver: $e');
    }
  }

  // Send a video message to another user
  Future<void> sendVideoMessage(String receiverId, String videoUrl) async {
    await sendMessage(receiverId, videoUrl, isVideo: true);
  }

  // Send an audio message to another user
  Future<void> sendAudioMessage(String receiverId, String audioUrl) async {
    await sendMessage(receiverId, audioUrl, isAudio: true);
  }

  // Update the metadata for a chat room
  Future<void> _updateChatRoomMetadata(
      String chatRoomId,
      String currentUserId,
      String receiverId,
      String lastMessage,
      Timestamp timestamp,
      ) async {
    try {
      // Update the chat room metadata with last message info
      await _firestore.collection(chatsCollection).doc(chatRoomId).set({
        'users': [currentUserId, receiverId],
        'lastMessage': lastMessage,
        'lastMessageTimestamp': timestamp,
        'lastMessageSenderId': currentUserId,
        'hasUnreadMessages': true,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update chat room metadata: $e');
    }
  }

  // Create a unique chat room ID by sorting and joining the two user IDs
  String _getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Sort to ensure consistent chat room ID regardless of who initiates
    return ids.join('_');
  }
  
  // Mark a message as read
  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      // Get the current user ID
      final String currentUserId = _auth.currentUser!.uid;
      
      // Create chat room ID
      String chatRoomId = _getChatRoomId(userId, currentUserId);
      
      // Update the message's read status in Firestore
      await _firestore
          .collection(chatsCollection)
          .doc(chatRoomId)
          .collection(messagesCollection)
          .doc(messageId)
          .update({
        'isRead': true,
        'readTimestamp': Timestamp.now(),
      });

      // Update chat room metadata to reflect read status
      await _updateChatRoomReadStatus(chatRoomId, currentUserId);
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Update chat room read status
  Future<void> _updateChatRoomReadStatus(String chatRoomId, String currentUserId) async {
    try {
      // Get the chat room document
      DocumentSnapshot chatRoomSnapshot = await _firestore
          .collection(chatsCollection)
          .doc(chatRoomId)
          .get();

      if (chatRoomSnapshot.exists) {
        // Check if there are any unread messages
        QuerySnapshot unreadMessages = await _firestore
            .collection(chatsCollection)
            .doc(chatRoomId)
            .collection(messagesCollection)
            .where('isRead', isEqualTo: false)
            .where('receiverId', isEqualTo: currentUserId)
            .get();

        // Update the chat room metadata
        await _firestore
            .collection(chatsCollection)
            .doc(chatRoomId)
            .update({
          'hasUnreadMessages': unreadMessages.docs.isNotEmpty,
        });
      }
    } catch (e) {
      throw Exception('Failed to update chat room read status: $e');
    }
  }

  // Listen for chat updates
  void listenForChatUpdates(String userId, Function callback) {
    _firestore
        .collection(chatsCollection)
        .where('users', arrayContains: userId)
        .snapshots()
        .listen((_) {
      callback();
    });
  }
}