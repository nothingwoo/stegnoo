  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:firebase_storage/firebase_storage.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:final_app/services/auth/auth_gate.dart';
  import 'firebase_options.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'dart:io';
  import 'package:image_picker/image_picker.dart';

  // ✅ Theme Provider
  class ThemeProvider extends ChangeNotifier {
    bool _isDarkMode = false;
    bool get isDarkMode => _isDarkMode;

    ThemeProvider() {
      _loadThemePreference();
    }

    void toggleTheme() async {
      _isDarkMode = !_isDarkMode;
      notifyListeners();
      await _saveThemePreference();
    }

    Future<void> _loadThemePreference() async {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      notifyListeners();
    }

    Future<void> _saveThemePreference() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
    }
  }

  // ✅ Profile Provider (Manages Profile Picture & Loading State)
  class ProfileProvider extends ChangeNotifier {
    String _profileImageUrl = '';
    bool _isLoading = false;

    String get profileImageUrl => _profileImageUrl;
    bool get isLoading => _isLoading;

    void setLoading(bool loading) {
      _isLoading = loading;
      notifyListeners();
    }

    void updateProfileImage(String newUrl) {
      _profileImageUrl = newUrl;
      _isLoading = false; // Stop loading
      notifyListeners();
    }

    void loadProfileImage(String userId) async {
      setLoading(true);
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (doc.exists && doc.data()!.containsKey('profileImageUrl')) {
          _profileImageUrl = doc.data()!['profileImageUrl'] ?? '';
        } else {
          _profileImageUrl = '';
        }
      } catch (e) {
        print("Error loading profile image: $e");
        _profileImageUrl = '';
      }
      setLoading(false);
    }
  }

  // ✅ Auth Provider (Manages Authentication State)
  class AuthProvider extends ChangeNotifier {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? _user;

    User? get user => _user;

    AuthProvider() {
      _auth.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
    }

    // Check if user is signed in
    bool isSignedIn() {
      return _user != null;
    }

    // Get user ID
    String? getUserId() {
      return _user?.uid;
    }
  }

  // ✅ Main Function
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => ProfileProvider()),
          ChangeNotifierProvider(create: (context) => AuthProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }

  // ✅ SplashScreen (Web & Android)
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Navigate to AuthGate after splash
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const AuthGate()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fixed black background
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset('assets/images/image.png'), // Replace Icon and Text with Image
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


  // ✅ MyApp
  class MyApp extends StatelessWidget {
    const MyApp({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      final themeProvider = Provider.of<ThemeProvider>(context);

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stego',
        home: const SplashScreen(), // Directly use SplashScreen
        theme: themeProvider.isDarkMode 
            ? ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: Colors.green,
                  secondary: Colors.greenAccent,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            : ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.green,
                  secondary: Colors.greenAccent,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
      );
    }
  }

  // ✅ Function to Pick Image from Gallery
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  // ✅ Function to Upload Profile Picture
  Future<void> uploadProfilePicture(File imageFile, BuildContext context, String userId) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    profileProvider.setLoading(true);

    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_pics/$userId');
      final uploadTask = storageRef.putFile(imageFile);
      
      // Wait for the upload to complete
      await uploadTask.whenComplete(() => null);

      // Get the download URL
      String newImageUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profileImageUrl': newImageUrl,
      });

      profileProvider.updateProfileImage(newImageUrl);
    } catch (e) {
      print("Error uploading profile picture: $e");
      profileProvider.setLoading(false);
    }
  }

  // ✅ Profile Picture Widget
  class ProfilePicture extends StatelessWidget {
    final String userId;

    const ProfilePicture({Key? key, required this.userId}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      final profileProvider = Provider.of<ProfileProvider>(context);

      // Load profile image when widget is built
      if (profileProvider.profileImageUrl.isEmpty && !profileProvider.isLoading) {
        Future.microtask(() => profileProvider.loadProfileImage(userId));
      }

      return Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: profileProvider.profileImageUrl.isNotEmpty
                ? NetworkImage(profileProvider.profileImageUrl)
                : const AssetImage('assets/default_profile.png') as ImageProvider,
          ),
          if (profileProvider.isLoading)
            const CircularProgressIndicator(), // ✅ Loading Indicator

          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () async {
                File? pickedImage = await pickImage();
                if (pickedImage != null) {
                  await uploadProfilePicture(pickedImage, context, userId);
                }
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade700,
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }
  }

  // ✅ Settings Page (Add Dark Mode Toggle)
  class SettingsPage extends StatelessWidget {
    const SettingsPage({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      final themeProvider = Provider.of<ThemeProvider>(context);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Dark Mode Toggle Switch
              ListTile(
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(); // Toggle the theme
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }