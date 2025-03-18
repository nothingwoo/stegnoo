import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      _profileImageUrl = doc['profileImageUrl'] ?? '';
    } catch (e) {
      print("Error loading profile image: $e");
    }
    setLoading(false);
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Navigate to AuthGate after splash
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthGate()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 32, 32, 33), // Change this to match your theme
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble, size: 100, color: Colors.white), // Replace with your logo
              SizedBox(height: 10),
              Text(
                "Stego",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 66, 232, 72),
                ),
              ),
            ],
          ),
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
      home: const SplashScreen(), // Show splash first
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
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
    await storageRef.putFile(imageFile);

    String newImageUrl = await storageRef.getDownloadURL();

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

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: profileProvider.profileImageUrl.isNotEmpty
              ? NetworkImage(profileProvider.profileImageUrl)
              : AssetImage('assets/default_profile.png') as ImageProvider,
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
              child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
