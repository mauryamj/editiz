import 'package:flutter/material.dart';

// Class: placeholder home screen for Phase 2 navigation.
class HomeScreen extends StatelessWidget {
  // Constructor: const key constructor.
  const HomeScreen({super.key});

  // Override: builds the home screen placeholder.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Let's edit something",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.video_library_rounded,
                  size: 36,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Home',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Video picking and recent clips will connect in Phase 4',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
