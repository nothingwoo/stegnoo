// ignore_for_file: unused_field

import 'dart:async';
import 'package:final_app/Pages/chat_page.dart';
import 'package:final_app/components/my_drawer.dart';
import 'package:final_app/services/auth/auth_service.dart';
import 'package:final_app/services/chat/chat_services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kDarkBackground = Color(0xFF0F0028); // Dark purple background
const Color kDarkCardColor = Color(0xFF330066); // Deeper violet for cards
const Color kOnlineGreen = Color(0xFF25D366); // Online status green

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ChatServices _chatServices = ChatServices();
  final AuthService _authService = AuthService();
  bool _isSearching = false;
  String _searchQuery = "";

  // Key for forcing a rebuild of the StreamBuilder
  GlobalKey _streamKey = GlobalKey();

  // Used to store current user ID
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.getCurrentUser()!.uid;

    // Add observer to detect when app comes back to foreground
    WidgetsBinding.instance.addObserver(this);

    // Listen for chat updates to refresh user list
    _chatServices.listenForChatUpdates(_currentUserId, () {
      _refreshUserList();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      setState(() {
        // This will trigger a refresh
        _streamKey = GlobalKey();
      });
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = "";
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      _searchQuery = newQuery;
    });
  }

  // Force refresh the user list
  void _refreshUserList() {
    setState(() {
      // Using a new key forces the StreamBuilder to rebuild
      // which will fetch fresh data
      _streamKey = GlobalKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kDarkBackground,
        primaryColor: kDarkCardColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kDarkCardColor,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kDarkCardColor,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: _updateSearchQuery,
                )
              : const Text(
                  'STEGO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
          actions: [
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _stopSearch,
              )
            else
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _startSearch,
              ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshUserList,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        drawer: const MyDrawer(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0028), // Even darker, more intense purple
                Color(0xFF330066), // Deeper, saturated violet
                Colors.black87, // Slightly transparent black for depth
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: _buildUserList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(
            Icons.chat,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      key: _streamKey,
      stream: _chatServices.getUsersStream(),
      builder: (context, snapshot) {
        // Debug print statement to see what's coming from Firestore
        print("Stream data status: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, error: ${snapshot.error}");
        if (snapshot.hasData) {
          print("Number of docs: ${snapshot.data!.docs.length}");
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error occurred while loading users: ${snapshot.error}",
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  "No conversations yet",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        List<DocumentSnapshot> users = snapshot.data!.docs;
        String currentUserEmail = _authService.getCurrentUser()!.email!;

        // Filter out current user
        users = users.where((user) {
          Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
          return userData["email"] != currentUserEmail;
        }).toList();

        // Debug print for filtered users
        print("Filtered users count after removing current user: ${users.length}");

        // Filter users based on search query
        if (_searchQuery.isNotEmpty) {
          users = users.where((user) {
            Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
            String username = userData["username"] ?? userData["email"].toString().split('@')[0];
            return username.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
          print("Filtered users count after search: ${users.length}");
        }

        // If no users found after filtering
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? "No users found matching '$_searchQuery'"
                      : "No conversations yet",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _processUsers(users),
          builder: (context, processedSnapshot) {
            if (processedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }

            if (processedSnapshot.hasError) {
              print("Error processing users: ${processedSnapshot.error}");
              return Center(
                child: Text(
                  "Error processing users",
                  style: TextStyle(color: Colors.grey[400]),
                ),
              );
            }

            if (!processedSnapshot.hasData || processedSnapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No conversations yet",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            List<Map<String, dynamic>> processedUsers = processedSnapshot.data!;
            print("Processed users count: ${processedUsers.length}");

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: processedUsers.length,
              itemBuilder: (context, index) {
                return _buildUserListItemFromProcessed(processedUsers[index], context);
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _processUsers(List<DocumentSnapshot> users) async {
    List<Map<String, dynamic>> processedUsers = [];
    String currentUserId = _authService.getCurrentUser()!.uid;

    for (var userDoc in users) {
      try {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String userId = userData["uid"];

        // Get messages for this user
        QuerySnapshot messagesSnapshot = await _chatServices.getMessages(
            userId, currentUserId)
            .first;

        List<QueryDocumentSnapshot> messages = messagesSnapshot.docs;

        // Filter out messages sent by the current user when calculating unread count
        int unreadCount = messages.where((msg) {
          Map<String, dynamic> messageData = msg.data() as Map<String, dynamic>;
          return !messageData['isRead'] && messageData['senderId'] != currentUserId;
        }).length;

        // Get the last message time
        Timestamp lastMessageTime = Timestamp.fromDate(DateTime(2000));
        if (messages.isNotEmpty) {
          // Sort messages by timestamp (newest last)
          messages.sort((a, b) {
            Timestamp aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            Timestamp bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            return aTime.compareTo(bTime);
          });

          lastMessageTime = (messages.last.data() as Map<String, dynamic>)['timestamp'];
        }

        // Add processed user data with message info
        processedUsers.add({
          'userData': userData,
          'unreadCount': unreadCount,
          'lastMessageTime': lastMessageTime,
        });
      } catch (e) {
        print("Error processing user ${userDoc.id}: $e");
        // Skip this user if there's an error processing it
        continue;
      }
    }

    // Sort users by last message time (newest first)
    processedUsers.sort((a, b) {
      return b['lastMessageTime'].compareTo(a['lastMessageTime']);
    });

    return processedUsers;
  }

  Widget _buildUserListItemFromProcessed(Map<String, dynamic> processedData, BuildContext context) {
    Map<String, dynamic> user = processedData['userData'];
    String displayName = user["username"] ?? user["email"].toString().split('@')[0];
    String userId = user["uid"];
    int unreadCount = processedData['unreadCount'];
    Timestamp lastMessageTime = processedData['lastMessageTime'];

    // Format timestamp in 12-hour format
    String timeString = "";
    if (lastMessageTime != null) {
      DateTime messageDateTime = lastMessageTime.toDate();
      DateTime now = DateTime.now();
      bool isToday = messageDateTime.year == now.year &&
          messageDateTime.month == now.month &&
          messageDateTime.day == now.day;

      if (isToday) {
        // Format as 12-hour time with AM/PM for today's messages
        int hour = messageDateTime.hour > 12 ? messageDateTime.hour - 12 : messageDateTime.hour;
        // Handle midnight (0 hour) case
        if (hour == 0) hour = 12;
        String period = messageDateTime.hour >= 12 ? "PM" : "AM";
        timeString = "${hour.toString()}:${messageDateTime.minute.toString().padLeft(2, '0')} $period";
      } else {
        // Format as date for older messages
        timeString = "${messageDateTime.day}/${messageDateTime.month}/${messageDateTime.year}";
      }
    }

    return Column(
      children: [
        InkWell(
          onTap: () async {
            // Navigate to the chat page immediately
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverEmail: user["email"],
                  receiverID: userId,
                ),
              ),
            );

            // After returning from the chat page, mark messages as read and refresh the list
            await _markAllMessagesAsRead(userId);
            _refreshUserList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.transparent,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: kDarkCardColor,
                  radius: 25,
                  backgroundImage: user["profilePicUrl"] != null && user["profilePicUrl"].isNotEmpty
                      ? NetworkImage(user["profilePicUrl"]) // Use the profile picture URL if available
                      : null, // Set backgroundImage to null when no profile picture is available
                  child: user["profilePicUrl"] == null || user["profilePicUrl"].isEmpty
                      ? const Icon(
                    Icons.person, // Use the person icon from Flutter's built-in icons
                    size: 30, // Adjust the size of the icon as needed
                    color: Colors.white, // Set the color of the icon
                  )
                      : null, // Show the icon if no profile picture is available
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              if (user["isOnline"] == true)
                                const SizedBox(width: 8),
                              if (user["isOnline"] == true)
                                Icon(Icons.circle, size: 10, color: kOnlineGreen),
                            ],
                          ),
                          if (lastMessageTime != null)
                            Text(
                              timeString,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (unreadCount > 0)
                            CircleAvatar(
                              backgroundColor: kOnlineGreen,
                              radius: 10,
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(color: Colors.grey[900], height: 1, indent: 82),
      ],
    );
  }

  // New method to mark all messages from a specific user as read
  Future<void> _markAllMessagesAsRead(String senderId) async {
    try {
      String currentUserId = _authService.getCurrentUser()!.uid;

      // Get all unread messages from this sender
      QuerySnapshot messagesSnapshot = await _chatServices.getMessages(senderId, currentUserId).first;

      // Get unread messages not sent by current user
      List<QueryDocumentSnapshot> unreadMessages = messagesSnapshot.docs.where((msg) {
        Map<String, dynamic> messageData = msg.data() as Map<String, dynamic>;
        return !messageData['isRead'] && messageData['senderId'] == senderId;
      }).toList();

      // Mark each message as read
      for (var msg in unreadMessages) {
        await _chatServices.markMessageAsRead(msg.id, senderId);
      }
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }
}