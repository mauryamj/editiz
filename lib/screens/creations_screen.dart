import 'package:flutter/material.dart';

// Class: placeholder creations screen for Phase 2 navigation.
class CreationsScreen extends StatelessWidget {
  // Constructor: const key constructor.
  const CreationsScreen({super.key});

  // Override: builds the creations screen placeholder.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Creations',
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
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.movie_filter_rounded,
                  size: 36,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No creations yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Edited videos saved to local storage will appear here',
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
