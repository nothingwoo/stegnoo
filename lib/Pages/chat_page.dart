import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:final_app/services/chat/chat_services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'video_button.dart'; // Import the VideoUploadButton
import 'video_player.dart'; // Import the VideoPlayerPage
import 'audio_button.dart'; // Import the AudioUploadButton
import 'audio_player.dart'; // Import the AudioPlayerPage

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatServices _chatServices = ChatServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  String receiverUsername = "";
  String receiverProfilePicUrl = ""; // Variable to store profile picture URL

  @override
  void initState() {
    super.initState();
    _fetchReceiverUsername();
  }

  Future<void> _fetchReceiverUsername() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverID)
          .get();

      if (userDoc.exists) {
        setState(() {
          receiverUsername =
              (userDoc.data() as Map<String, dynamic>)['username'] ??
                  widget.receiverEmail;
          receiverProfilePicUrl =
              (userDoc.data() as Map<String, dynamic>)['profilePicUrl'] ?? ""; // Fetch profile picture URL
        });
      }
    } catch (e) {
      print("Error fetching username or profile picture: $e");
      receiverUsername = widget.receiverEmail;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      await _chatServices.sendMessage(
        widget.receiverID,
        _messageController.text.trim(),
        isVideo: false,
        isAudio: false,
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _sendVideoMessage(String videoUrl) async {
    try {
      await _chatServices.sendMessage(
        widget.receiverID,
        videoUrl,
        isVideo: true,
        isAudio: false,
      );
      _scrollToBottom();
    } catch (e) {
      print('Error sending video message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending video: $e')),
      );
    }
  }

  void _sendAudioMessage(String audioUrl) async {
    try {
      await _chatServices.sendMessage(
        widget.receiverID,
        audioUrl,
        isVideo: false,
        isAudio: true,
      );
      _scrollToBottom();
    } catch (e) {
      print('Error sending audio message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending audio: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Row(
          children: [
            // CircleAvatar for profile picture
            CircleAvatar(
              backgroundColor: Colors.green, // Use your desired background color
              radius: 20, // Adjust the radius as needed
              backgroundImage: receiverProfilePicUrl.isNotEmpty
                  ? NetworkImage(receiverProfilePicUrl) // Use the profile picture URL if available
                  : null, // Set backgroundImage to null when no profile picture is available
              child: receiverProfilePicUrl.isEmpty
                  ? const Icon(
                      Icons.person, // Use the person icon from Flutter's built-in icons
                      size: 20, // Adjust the size of the icon as needed
                      color: Colors.white, // Set the color of the icon
                    )
                  : null, // Show the icon if no profile picture is available
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiverUsername,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.receiverID)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      bool isOnline = (snapshot.data!.data()
                      as Map<String, dynamic>)['isOnline'] ??
                          false;
                      return Text(
                        isOnline ? 'Active now' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.green[400] : Colors.grey[500],
                        ),
                      );
                    }
                    return Container();
                  },
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
              ),
              child: StreamBuilder(
                stream: _chatServices.getMessages(
                  widget.receiverID,
                  _auth.currentUser!.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Something went wrong',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white70,
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var messageData = snapshot.data!.docs[index].data()
                      as Map<String, dynamic>;
                      var timestamp = messageData['timestamp'] as Timestamp?;
                      var timeString = timestamp != null
                          ? DateFormat('HH:mm').format(timestamp.toDate())
                          : '';
                      var isSender =
                          messageData['senderId'] == _auth.currentUser!.uid;
                      var isVideo = messageData['isVideo'] ?? false;
                      var isAudio = messageData['isAudio'] ?? false;
                      var message = messageData['message'] as String? ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: isSender
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isSender) const SizedBox(width: 8),
                            if (isVideo && message.isNotEmpty)
                            // Video message
                              GestureDetector(
                                onTap: () {
                                  // Navigate to the VideoPlayerPage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VideoPlayerPage(videoUrl: message),
                                    ),
                                  );
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                    MediaQuery.of(context).size.width * 0.6,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSender
                                        ? Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3)
                                        : const Color(0xFF2D2D2D),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            height: 150,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                "Video",
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.play_circle_fill,
                                            size: 50,
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeString,
                                        style: TextStyle(
                                          color: isSender
                                              ? Colors.white.withOpacity(0.6)
                                              : Colors.white.withOpacity(0.4),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (isAudio && message.isNotEmpty)
                            // Audio message
                              GestureDetector(
                                onTap: () {
                                  // Navigate to the AudioPlayerPage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AudioPlayerPage(audioUrl: message),
                                    ),
                                  );
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                    MediaQuery.of(context).size.width * 0.6,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSender
                                        ? Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3)
                                        : const Color(0xFF2D2D2D),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          // Navigate to the AudioPlayerPage
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AudioPlayerPage(audioUrl: message),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.play_circle_fill,
                                          size: 50,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeString,
                                        style: TextStyle(
                                          color: isSender
                                              ? Colors.white.withOpacity(0.6)
                                              : Colors.white.withOpacity(0.4),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                            // Text message
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                  MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSender
                                      ? Theme.of(context).primaryColor
                                      : const Color(0xFF2D2D2D),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message,
                                      style: TextStyle(
                                        color: isSender
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.87),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeString,
                                      style: TextStyle(
                                        color: isSender
                                            ? Colors.white.withOpacity(0.6)
                                            : Colors.white.withOpacity(0.4),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isSender) const SizedBox(width: 8),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: [
                VideoUploadButton(onVideoUploaded: _sendVideoMessage),
                const SizedBox(width: 8),
                AudioUploadButton(onAudioUploaded: _sendAudioMessage), // Audio button
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF404040),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}