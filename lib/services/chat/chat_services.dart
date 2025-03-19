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
        bool isImage = false,
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
        'isImage': isImage,
        'isVideo': isVideo,
        'isAudio': isAudio,
      });

      // Update chat room metadata
      await _updateChatRoomMetadata(
        chatRoomId,
        currentUserId,
        receiverId,
        message,
        timestamp,
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Send an image message to another user
  Future<void> sendImageMessage(String receiverId, String imageUrl) async {
    await sendMessage(receiverId, imageUrl, isImage: true);
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
}