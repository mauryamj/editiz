import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:editiz/screens/main_screen.dart';
import 'package:editiz/widgets/expressive_loader.dart';

// Class: splash screen that displays animated logo and initializes storage and network.
class SplashScreen extends StatefulWidget {
  // Constructor: standard key constructor.
  const SplashScreen({super.key});

  // Override: creates State object.
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Class: state for splash animation and initialization lifecycle.
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Field: controller for logo elastic entry.
  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  // Field: curved elastic animation for logo.
  late final Animation<double> _logoScaleAnimation = CurvedAnimation(
    parent: _logoController,
    curve: Curves.elasticOut,
  );

  // Override: initializes animation and starts background initialization.
  @override
  void initState() {
    super.initState();
    _logoController.forward();
    _initializeApp();
  }

  // Override: disposes controller.
  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  // Method: initializes Hive, creates VideoEdits folder, configures Dio, and navigates.
  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    try {
      // 1. Initialize Hive Flutter
      await Hive.initFlutter();
      if (!Hive.isBoxOpen('creations')) {
        await Hive.openBox('creations');
      }

      // 2. Ensure VideoEdits folder exists in App Documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final videoEditsDir = Directory('${appDocDir.path}/VideoEdits');
      if (!await videoEditsDir.exists()) {
        await videoEditsDir.create(recursive: true);
      }

      // 3. Setup Dio instance defaults
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      assert(dio.options.connectTimeout == const Duration(seconds: 8));
    } catch (_) {
      // Graceful fallback: continue to main screen even if offline/partial init
    }

    // Keep splash visible for 2-3 seconds total
    final elapsed = DateTime.now().difference(startTime);
    const minSplashDuration = Duration(milliseconds: 2200);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    if (!mounted) return;

    // Navigate to MainScreen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // Override: builds the expressive splash UI.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withAlpha(50),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Animated Logo Squircle
              ScaleTransition(
                scale: _logoScaleAnimation,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withAlpha(90),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/icons/app_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.movie_creation_outlined,
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Brand Name
              Text(
                'editiz',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle
              Text(
                'Expressive On-Device Video Editor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              // Signature Expressive Loader
              const ExpressiveLoader(size: 36),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
