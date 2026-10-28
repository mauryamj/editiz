import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen in-app video player.
class PlayerScreen extends StatefulWidget {
  final String videoPath;
  final String title;

  const PlayerScreen({
    super.key,
    required this.videoPath,
    required this.title,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();
  }

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

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              )
            : (!_isInitialized || controller == null)
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                      ),
                      // Play / Pause overlay
                      IconButton(
                        iconSize: 64,
                        icon: Icon(
                          controller.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          if (controller.value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        },
                      ),
                      // Bottom Progress Slider
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(controller.value.position),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                Text(
                                  _formatDuration(controller.value.duration),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                            Slider(
                              value: controller.value.position.inMilliseconds
                                  .clamp(0, controller.value.duration.inMilliseconds)
                                  .toDouble(),
                              min: 0.0,
                              max: controller.value.duration.inMilliseconds.toDouble(),
                              onChanged: (val) {
                                controller.seekTo(Duration(milliseconds: val.toInt()));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
