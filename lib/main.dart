import 'package:flutter/material.dart';
import 'package:editiz/screens/splash_screen.dart';
import 'package:editiz/theme.dart';

// Function: main app entry point.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EditizApp());
}

// Class: root widget providing themes and starting at SplashScreen.
class EditizApp extends StatelessWidget {
  // Constructor: const key constructor.
  const EditizApp({super.key});

  // Override: builds MaterialApp with light and dark themes.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'editiz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
