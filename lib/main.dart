import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:business_card_app_v1/constants/app_theme.dart'; // Custom theme
import 'package:business_card_app_v1/screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(MyApp()); // Removed 'const' here
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Kept 'const' here since MyApp itself can be const

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Business Card App',
      theme: AppTheme.lightTheme,
      home: LoginScreen(), // Removed 'const' here
    );
  }
}