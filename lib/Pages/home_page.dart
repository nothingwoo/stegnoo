// ignore_for_file: unused_field

import 'dart:async';
import 'package:final_app/Pages/chat_page.dart';
import 'package:final_app/components/my_drawer.dart';
import 'package:final_app/services/auth/auth_service.dart';
import 'package:final_app/services/chat/chat_services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kWhatsAppGreen = Color(0xFF075E54);
const Color kWhatsAppLightGreen = Color(0xFF128C7E);
const Color kDarkBackground = Color(0xFF121B22);
const Color kDarkCardColor = Color(0xFF1F2C34);
const Color kOnlineGreen = Color(0xFF25D366);

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
        primaryColor: kWhatsAppGreen,
        appBarTheme: const AppBarTheme(
          backgroundColor: kDarkCardColor,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kWhatsAppLightGreen,
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
                  'STEGNO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          actions: [
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _stopSearch,
              )
            else
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _startSearch,
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshUserList,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ],
        ),
        drawer: const MyDrawer(),
        body: _buildUserList(),
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
              color: kWhatsAppLightGreen,
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
                  color: kWhatsAppLightGreen,
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
          userId, currentUserId
        ).first;

        List<QueryDocumentSnapshot> messages = messagesSnapshot.docs;
        
        bool hasMessages = messages.isNotEmpty;

        // Filter out messages sent by the current user when calculating unread count
        int unreadCount = messages.where((msg) {
          Map<String, dynamic> messageData = msg.data() as Map<String, dynamic>;
          return !messageData['isRead'] && messageData['senderId'] != currentUserId;
        }).length;

        // Get the last message (regardless of sender)
        String lastMessage = "No messages yet";
        Timestamp lastMessageTime = Timestamp.fromDate(DateTime(2000));
        
        if (hasMessages) {
          // Sort messages by timestamp (newest last)
          messages.sort((a, b) {
            Timestamp aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            Timestamp bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            return aTime.compareTo(bTime);
          });
          
          lastMessage = (messages.last.data() as Map<String, dynamic>)['message'];
          lastMessageTime = (messages.last.data() as Map<String, dynamic>)['timestamp'];
        }

        // Add processed user data with message info
        processedUsers.add({
          'userData': userData,
          'hasMessages': hasMessages,
          'unreadCount': unreadCount,
          'lastMessage': lastMessage,
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
      // First sort by having messages
      if (a['hasMessages'] && !b['hasMessages']) return -1;
      if (!a['hasMessages'] && b['hasMessages']) return 1;

      // If both have or don't have messages, sort by timestamp (newest first)
      return b['lastMessageTime'].compareTo(a['lastMessageTime']);
    });

    return processedUsers;
  }

  Widget _buildUserListItemFromProcessed(Map<String, dynamic> processedData, BuildContext context) {
    Map<String, dynamic> user = processedData['userData'];
    String displayName = user["username"] ?? user["email"].toString().split('@')[0];
    String userId = user["uid"];
    bool hasMessages = processedData['hasMessages'];
    bool hasUnread = processedData['unreadCount'] > 0;
    int unreadCount = processedData['unreadCount'];
    String lastMessage = processedData['lastMessage'];
    Timestamp lastMessageTime = processedData['lastMessageTime'];

   // Format timestamp
String timeString = "";
if (hasMessages) {
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
            // Mark messages as read
            _chatServices.getMessages(userId, _authService.getCurrentUser()!.uid)
              .first.then((messagesSnapshot) {
                for (var msg in messagesSnapshot.docs) {
                  Map<String, dynamic> messageData = msg.data() as Map<String, dynamic>;
                  if (messageData['senderId'] != _authService.getCurrentUser()!.uid) {
                    _chatServices.markMessageAsRead(msg.id, userId);
                  }
                }
              });

            // Navigate to chat page and wait for it to complete
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverEmail: user["email"],
                  receiverID: userId,
                ),
              ),
            );
            
            // Explicitly refresh the user list when returning from chat
            _refreshUserList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.transparent,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: kWhatsAppLightGreen,
                  radius: 25,
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                          if (hasMessages)
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
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: TextStyle(
                                color: hasUnread ? Colors.white : Colors.grey[500],
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hasUnread)
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
}