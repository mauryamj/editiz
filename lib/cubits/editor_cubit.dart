import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:editiz/models/edit_state.dart';

// Class: base state for EditorCubit.
abstract class EditorState {
  const EditorState();
}

// Class: state while video player controller is initializing.
class EditorLoading extends EditorState {
  const EditorLoading();
}

// Class: state when video is initialized and ready for editing.
class EditorReady extends EditorState {
  // Field: active edits state.
  final EditState editState;

  // Field: initialized video player controller.
  final VideoPlayerController controller;

  // Field: current playback position.
  final Duration position;

  // Field: true if video is currently playing.
  final bool isPlaying;

  // Constructor: requires editState, controller, position, isPlaying.
  const EditorReady({
    required this.editState,
    required this.controller,
    required this.position,
    required this.isPlaying,
  });

  // Method: returns updated copy of state.
  EditorReady copyWith({
    EditState? editState,
    Duration? position,
    bool? isPlaying,
  }) {
    return EditorReady(
      editState: editState ?? this.editState,
      controller: controller,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

// Class: state when video fails to load or is corrupted.
class EditorFailure extends EditorState {
  // Field: user-friendly error message.
  final String message;

  // Constructor: requires message.
  const EditorFailure(this.message);
}

// Class: cubit controlling video editing state and player synchronization.
class EditorCubit extends Cubit<EditorState> {
  // Field: path to the local video file.
  final String videoPath;

  // Field: video player controller instance.
  VideoPlayerController? _controller;

  // Constructor: starts initialization of video.
  EditorCubit({required this.videoPath}) : super(const EditorLoading()) {
    _initVideo();
  }

  // Method: initializes VideoPlayerController and loads metadata.
  Future<void> _initVideo() async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        if (!isClosed) emit(const EditorFailure('Video file not found.'));
        return;
      }

      final controller = VideoPlayerController.file(file);
      _controller = controller;

      await controller.initialize();
      final totalDuration = controller.value.duration;

      if (totalDuration <= Duration.zero) {
        if (!isClosed) emit(const EditorFailure("We can't read this video."));
        return;
      }

      controller.addListener(_onVideoTick);

      if (!isClosed) {
        emit(
          EditorReady(
            editState: EditState.initial(totalDuration),
            controller: controller,
            position: Duration.zero,
            isPlaying: false,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) emit(const EditorFailure("We can't read this video."));
    }
  }

  // Method: listens to controller playback and enforces trim boundaries.
  void _onVideoTick() {
    final state = this.state;
    if (state is! EditorReady || isClosed) return;

    final currentPos = state.controller.value.position;
    final isPlaying = state.controller.value.isPlaying;

    // Check if playback exceeded the trim end boundary.
    if (currentPos >= state.editState.end) {
      state.controller.pause();
      state.controller.seekTo(state.editState.start);
      emit(state.copyWith(position: state.editState.start, isPlaying: false));
      return;
    }

    emit(state.copyWith(position: currentPos, isPlaying: isPlaying));
  }

  // Method: toggles play / pause.
  void togglePlayPause() {
    final state = this.state;
    if (state is! EditorReady) return;

    if (state.controller.value.isPlaying) {
      state.controller.pause();
      emit(state.copyWith(isPlaying: false));
    } else {
      // If at or past trim end, seek back to start before playing.
      if (state.controller.value.position >= state.editState.end) {
        state.controller.seekTo(state.editState.start);
      }
      state.controller.play();
      emit(state.copyWith(isPlaying: true));
    }
  }

  // Method: pauses playback (e.g. When app is sent to background).
  void pause() {
    final state = this.state;
    if (state is! EditorReady) return;
    state.controller.pause();
    emit(state.copyWith(isPlaying: false));
  }

  // Method: seeks video clamped to trim range.
  void seekTo(Duration target) {
    final state = this.state;
    if (state is! EditorReady) return;

    final clampedTarget = target < state.editState.start
        ? state.editState.start
        : (target > state.editState.end ? state.editState.end : target);

    state.controller.seekTo(clampedTarget);
    emit(state.copyWith(position: clampedTarget));
  }

  // Method: updates start and end trim boundaries.
  void updateTrimRange(Duration start, Duration end) {
    final state = this.state;
    if (state is! EditorReady) return;

    final updated = state.editState.copyWith(start: start, end: end);
    emit(state.copyWith(editState: updated));

    // Keep playhead within new bounds.
    if (state.position < start) {
      seekTo(start);
    } else if (state.position > end) {
      seekTo(end);
    }
  }

  // Method: rotates video 90 degrees clockwise (0 -> 1 -> 2 -> 3 -> 0).
  void rotateClockwise() {
    final state = this.state;
    if (state is! EditorReady) return;

    final newQuarterTurns = (state.editState.quarterTurns + 1) % 4;
    emit(state.copyWith(
      editState: state.editState.copyWith(quarterTurns: newQuarterTurns),
    ));
  }

  // Method: updates brightness offset (-0.5 to 0.5).
  void setBrightness(double brightness) {
    final state = this.state;
    if (state is! EditorReady) return;

    emit(state.copyWith(
      editState: state.editState.copyWith(brightness: brightness),
    ));
  }

  // Method: updates contrast multiplier (0.5 to 1.5).
  void setContrast(double contrast) {
    final state = this.state;
    if (state is! EditorReady) return;

    emit(state.copyWith(
      editState: state.editState.copyWith(contrast: contrast),
    ));
  }

  // Method: toggles audio mute state.
  void toggleMute() {
    final state = this.state;
    if (state is! EditorReady) return;

    final newMute = !state.editState.isMuted;
    state.controller.setVolume(newMute ? 0.0 : 1.0);
    emit(state.copyWith(
      editState: state.editState.copyWith(isMuted: newMute),
    ));
  }

  // Method: resets only filters keeping trim range.
  void resetFilters() {
    final state = this.state;
    if (state is! EditorReady) return;

    state.controller.setVolume(1.0);
    emit(state.copyWith(editState: state.editState.resetFilters()));
  }

  // Method: resets all edits back to initial video state.
  void resetAll() {
    final state = this.state;
    if (state is! EditorReady) return;

    state.controller.setVolume(1.0);
    seekTo(Duration.zero);
    emit(state.copyWith(editState: state.editState.resetAll()));
  }

  // Override: removes listener and disposes controller.
  @override
  Future<void> close() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    return super.close();
  }
}
