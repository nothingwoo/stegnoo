import 'package:final_app/Pages/settings_page.dart';
import 'package:final_app/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  
void logout(){
  //get auth service
  final _auth = AuthService();
  _auth.signOut();
}

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer Header
          // Drawer Header with Image
DrawerHeader(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
  ),
  child: Center(
    // Replace the chat icon with an image
    child: CircleAvatar(
      radius: 40, // Adjust the size of the image
      backgroundImage: const AssetImage('assets/images/image.png'), // Replace with your image path
      child: ClipOval(
        child: Image.asset(
          'assets/images/image.png', // Replace with your image path
          fit: BoxFit.cover,
          width: 80, // Adjust the width
          height: 80, // Adjust the height
        ),
      ),
    ),
  ),
),

          // Home List Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListTile(
              contentPadding: EdgeInsets.zero, // Remove extra padding
              leading: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.primary,
                size: 20, // Reduced icon size
              ),
              title: Text(
                'Home',
                style: TextStyle(
                  fontSize: 14, // Reduced text size
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              onTap: () {
                // Navigate to home page
                Navigator.pop(context);
              },
            ),
          ),

          // Settings List Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListTile(
              contentPadding: EdgeInsets.zero, // Remove extra padding
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
                size: 20, // Reduced icon size
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 14, // Reduced text size
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              onTap: () {
                // Navigate to settings page
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                ); // Missing semicolon added here
              },
            ),
          ),

          // Spacer to push logout button to the bottom
          const Spacer(),

          // Logout List Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListTile(
              contentPadding: EdgeInsets.zero, // Remove extra padding
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.primary,
                size: 20, // Reduced icon size
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14, // Reduced text size
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              onTap: logout,
            ),
          ),

          // Optional: Footer for branding
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "SECURE SEND",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
