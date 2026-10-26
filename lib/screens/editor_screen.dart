import 'package:flutter/material.dart';

// Class: initial placeholder for EditorScreen to satisfy route and allow Phase 4 testing.
class EditorScreen extends StatelessWidget {
  // Field: path to the picked video file.
  final String videoPath;

  // Constructor: requires videoPath.
  const EditorScreen({super.key, required this.videoPath});

  // Override: builds editor placeholder.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Picked: $videoPath\n\nFull Editor will be wired in Phase 5.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
