import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:editiz/screens/main_screen.dart';

/// Simple splash screen showing app title/logo and navigating after setup.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    final startTime = DateTime.now();

    try {
      // 1. Initialize Hive
      await Hive.initFlutter();
      if (!Hive.isBoxOpen('creations')) {
        await Hive.openBox('creations');
      }

      // 2. Ensure VideoEdits folder exists
      final appDocDir = await getApplicationDocumentsDirectory();
      final videoEditsDir = Directory('${appDocDir.path}/VideoEdits');
      if (!await videoEditsDir.exists()) {
        await videoEditsDir.create(recursive: true);
      }
    } catch (_) {}

    // Wait a brief moment to show app branding (~1.5s)
    final elapsed = DateTime.now().difference(startTime);
    const minSplashDuration = Duration(milliseconds: 1500);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icons/app_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.movie_creation_outlined,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'editiz',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Simple Video Editor',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
