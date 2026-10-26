// Class: immutable model holding the complete editing configuration.
class EditState {
  // Field: trim range start.
  final Duration start;

  // Field: trim range end.
  final Duration end;

  // Field: total video duration.
  final Duration total;

  // Field: rotation in quarter turns (0, 1, 2, or 3).
  final int quarterTurns;

  // Field: brightness offset (-0.5 to 0.5, default 0.0).
  final double brightness;

  // Field: contrast multiplier (0.5 to 1.5, default 1.0).
  final double contrast;

  // Field: whether audio should be stripped.
  final bool isMuted;

  // Constructor: creates an EditState instance.
  const EditState({
    required this.start,
    required this.end,
    required this.total,
    this.quarterTurns = 0,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.isMuted = false,
  });

  // Factory constructor: initializes default state from total duration.
  factory EditState.initial(Duration total) {
    return EditState(
      start: Duration.zero,
      end: total,
      total: total,
    );
  }

  // Getter: checks if trim duration is at least 1 second.
  bool get isValid => (end - start) >= const Duration(seconds: 1);

  // Getter: returns the effective duration after trimming.
  Duration get selectedDuration => end > start ? end - start : Duration.zero;

  // Getter: true if any visual or audio modification was applied.
  bool get hasEdits =>
      start > Duration.zero ||
      end < total ||
      quarterTurns != 0 ||
      brightness != 0.0 ||
      contrast != 1.0 ||
      isMuted;

  // Getter: summary description of current edits.
  String get editsSummary {
    final list = <String>[];
    if (start > Duration.zero || end < total) {
      final sec = selectedDuration.inSeconds;
      list.add('Trimmed (${sec}s)');
    }
    if (quarterTurns != 0) {
      list.add('Rotated ${quarterTurns * 90}°');
    }
    if (brightness != 0.0) {
      list.add('Brightness ${(brightness * 100).toInt()}%');
    }
    if (contrast != 1.0) {
      list.add('Contrast ${contrast.toStringAsFixed(1)}x');
    }
    if (isMuted) {
      list.add('Muted');
    }
    return list.isEmpty ? 'Original' : list.join(', ');
  }

  // Method: creates a copy with updated values.
  EditState copyWith({
    Duration? start,
    Duration? end,
    Duration? total,
    int? quarterTurns,
    double? brightness,
    double? contrast,
    bool? isMuted,
  }) {
    return EditState(
      start: start ?? this.start,
      end: end ?? this.end,
      total: total ?? this.total,
      quarterTurns: quarterTurns ?? this.quarterTurns,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  // Method: resets only filters (brightness, contrast, rotation, mute) keeping trim.
  EditState resetFilters() {
    return copyWith(
      quarterTurns: 0,
      brightness: 0.0,
      contrast: 1.0,
      isMuted: false,
    );
  }

  // Method: resets all edits back to initial video state.
  EditState resetAll() {
    return EditState.initial(total);
  }
}
