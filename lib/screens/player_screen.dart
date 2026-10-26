import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:editiz/widgets/expressive_loader.dart';

// Class: full in-app video player with responsive controls, seek bar, and lifecycle management.
class PlayerScreen extends StatefulWidget {
  // Field: absolute path to video file.
  final String videoPath;

  // Field: title/file name of the video.
  final String title;

  // Constructor: requires videoPath and title.
  const PlayerScreen({
    super.key,
    required this.videoPath,
    required this.title,
  });

  // Override: creates State object.
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

// Class: state managing VideoPlayerController, playback state, and background lifecycle.
class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  // Field: video player controller.
  VideoPlayerController? _controller;

  // Field: whether video is initialized.
  bool _isInitialized = false;

  // Field: error message if video fails to load.
  String? _errorMessage;

  // Field: whether playback controls are visible.
  bool _showControls = true;

  // Override: initializes controller and attaches lifecycle observer.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();
  }

  // Method: initializes VideoPlayerController from file.
  Future<void> _initPlayer() async {
    final file = File(widget.videoPath);
    if (!await file.exists()) {
      setState(() {
        _errorMessage = 'Video was deleted or moved.';
      });
      return;
    }

    try {
      final controller = VideoPlayerController.file(file);
      _controller = controller;

      await controller.initialize();
      controller.addListener(_onControllerUpdate);

      setState(() {
        _isInitialized = true;
      });
      controller.play();
    } catch (_) {
      setState(() {
        _errorMessage = "We can't play this video.";
      });
    }
  }

  // Method: listener called when position or state changes.
  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  // Override: pauses video when app is backgrounded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.pause();
    }
  }

  // Override: removes listener, observer, and disposes controller.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  // Method: formats Duration to MM:SS string.
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Override: builds the immersive dark video player UI.
  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_rounded, size: 56, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to Creations'),
                      ),
                    ],
                  ),
                ),
              )
            : (!_isInitialized || controller == null)
                ? const Center(child: ExpressiveLoader(size: 56))
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _showControls = !_showControls;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Centered Video
                        Center(
                          child: AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          ),
                        ),

                        // Animated Controls Overlay
                        AnimatedOpacity(
                          opacity: _showControls ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            color: Colors.black38,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(height: 20),
                                // Play / Pause center button
                                IconButton(
                                  iconSize: 64,
                                  icon: Icon(
                                    controller.value.isPlaying
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_fill_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    if (controller.value.isPlaying) {
                                      controller.pause();
                                    } else {
                                      controller.play();
                                    }
                                  },
                                ),
                                // Bottom Slider & Timestamps
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            formatDuration(controller.value.position),
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                          Text(
                                            formatDuration(controller.value.duration),
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: Theme.of(context).colorScheme.primary,
                                          inactiveTrackColor: Colors.white24,
                                          thumbColor: Theme.of(context).colorScheme.primary,
                                          trackHeight: 4,
                                        ),
                                        child: Slider(
                                          value: controller.value.position.inMilliseconds
                                              .clamp(0, controller.value.duration.inMilliseconds)
                                              .toDouble(),
                                          min: 0.0,
                                          max: controller.value.duration.inMilliseconds.toDouble(),
                                          onChanged: (val) {
                                            controller.seekTo(Duration(milliseconds: val.toInt()));
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
