import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:final_app/services/chat/chat_services.dart';

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
          receiverUsername = (userDoc.data() as Map<String, dynamic>)['username'] ?? widget.receiverEmail;
        });
      }
    } catch (e) {
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
      );
      _messageController.clear();
      _scrollToBottom();
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

  void deleteMessage(String messageId, bool deleteForEveryone) async {
    await _chatServices.deleteMessage(
      messageId,
      widget.receiverID,
      deleteForEveryone,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              receiverUsername,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.receiverID)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  bool isOnline = (snapshot.data!.data() as Map<String, dynamic>)['isOnline'] ?? false;
                  return Text(
                    isOnline ? 'Active now' : 'Offline',
                    style: TextStyle(fontSize: 12, color: isOnline ? Colors.green[400] : Colors.grey[500]),
                  );
                }
                return Container();
              },
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _chatServices.getMessages(widget.receiverID, _auth.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong', style: TextStyle(color: Colors.white70)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white70));
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.data!.docs.length,
                  // Added separator for more space between messages
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    var messageData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    var messageId = snapshot.data!.docs[index].id;
                    var timestamp = messageData['timestamp'] as Timestamp?;
                    var timeString = timestamp != null
                        ? DateFormat('hh:mm a').format(timestamp.toDate())
                        : '';
                    var isSender = messageData['senderId'] == _auth.currentUser!.uid;
                    var isDeleted = messageData['isDeleted'] ?? false;

                    return GestureDetector(
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Delete Message"),
                              content: const Text("Do you want to delete this message?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    deleteMessage(messageId, false); // Delete only for me
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Delete for Me"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deleteMessage(messageId, true); // Delete for everyone
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Delete for Everyone"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Row(
                        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isSender) const SizedBox(width: 8),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSender ? Theme.of(context).primaryColor : const Color(0xFF2D2D2D),
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
                                  isDeleted ? "This message was deleted" : messageData['message'],
                                  style: TextStyle(
                                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                                    color: isDeleted
                                        ? Colors.white.withOpacity(0.5)
                                        : (isSender ? Colors.white : Colors.white.withOpacity(0.87)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeString,
                                  style: TextStyle(
                                    color: isSender ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.4),
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
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF404040),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}