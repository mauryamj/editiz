import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:editiz/models/edit_state.dart';

/// Simple controller managing video player and editing parameters.
class EditorController extends ChangeNotifier {
  final String videoPath;
  VideoPlayerController? playerController;

  bool isLoading = true;
  String? errorMessage;
  Duration position = Duration.zero;
  bool isPlaying = false;

  EditState editState = const EditState(
    start: Duration.zero,
    end: Duration.zero,
    total: Duration.zero,
  );

  EditorController({required this.videoPath}) {
    _initVideo();
  }

  Future<void> _initVideo() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        errorMessage = 'Video file not found.';
        isLoading = false;
        notifyListeners();
        return;
      }

      final controller = VideoPlayerController.file(file);
      playerController = controller;

      await controller.initialize();
      final totalDuration = controller.value.duration;

      if (totalDuration <= Duration.zero) {
        errorMessage = "We can't read this video.";
        isLoading = false;
        notifyListeners();
        return;
      }

      editState = EditState.initial(totalDuration);
      controller.addListener(_onVideoTick);

      isLoading = false;
      notifyListeners();
    } catch (_) {
      errorMessage = "We can't read this video.";
      isLoading = false;
      notifyListeners();
    }
  }

  void _onVideoTick() {
    final controller = playerController;
    if (controller == null) return;

    final currentPos = controller.value.position;
    final isPlayingNow = controller.value.isPlaying;

    // Enforce trim boundary
    if (currentPos >= editState.end) {
      controller.pause();
      controller.seekTo(editState.start);
      position = editState.start;
      isPlaying = false;
      notifyListeners();
      return;
    }

    if (position != currentPos || isPlaying != isPlayingNow) {
      position = currentPos;
      isPlaying = isPlayingNow;
      notifyListeners();
    }
  }

  /// Toggle Play / Pause
  void togglePlayPause() {
    final controller = playerController;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
      isPlaying = false;
    } else {
      if (controller.value.position >= editState.end) {
        controller.seekTo(editState.start);
      }
      controller.play();
      isPlaying = true;
    }
    notifyListeners();
  }

  /// Pause playback
  void pause() {
    final controller = playerController;
    if (controller != null && controller.value.isPlaying) {
      controller.pause();
      isPlaying = false;
      notifyListeners();
    }
  }

  /// Seek video position
  void seekTo(Duration target) {
    final controller = playerController;
    if (controller == null) return;

    final clampedTarget = target < editState.start
        ? editState.start
        : (target > editState.end ? editState.end : target);

    controller.seekTo(clampedTarget);
    position = clampedTarget;
    notifyListeners();
  }

  /// Update trim range
  void updateTrimRange(Duration start, Duration end) {
    editState = editState.copyWith(start: start, end: end);

    if (position < start) {
      seekTo(start);
    } else if (position > end) {
      seekTo(end);
    } else {
      notifyListeners();
    }
  }

  /// Rotate 90° clockwise
  void rotateClockwise() {
    final newTurns = (editState.quarterTurns + 1) % 4;
    editState = editState.copyWith(quarterTurns: newTurns);
    notifyListeners();
  }

  /// Rotate 90° counter-clockwise
  void rotateCounterClockwise() {
    final newTurns = (editState.quarterTurns + 3) % 4;
    editState = editState.copyWith(quarterTurns: newTurns);
    notifyListeners();
  }

  /// Reset rotation
  void resetRotation() {
    editState = editState.copyWith(quarterTurns: 0);
    notifyListeners();
  }

  /// Adjust brightness (-0.5 to 0.5)
  void setBrightness(double value) {
    editState = editState.copyWith(brightness: value);
    notifyListeners();
  }

  /// Adjust contrast (0.5 to 1.5)
  void setContrast(double value) {
    editState = editState.copyWith(contrast: value);
    notifyListeners();
  }

  /// Toggle audio mute
  void toggleMute() {
    final newMute = !editState.isMuted;
    playerController?.setVolume(newMute ? 0.0 : 1.0);
    editState = editState.copyWith(isMuted: newMute);
    notifyListeners();
  }

  /// Reset filters
  void resetFilters() {
    playerController?.setVolume(1.0);
    editState = editState.resetFilters();
    notifyListeners();
  }

  /// Reset all edits
  void resetAll() {
    playerController?.setVolume(1.0);
    seekTo(Duration.zero);
    editState = editState.resetAll();
    notifyListeners();
  }

  @override
  void dispose() {
    playerController?.removeListener(_onVideoTick);
    playerController?.dispose();
    super.dispose();
  }
}
