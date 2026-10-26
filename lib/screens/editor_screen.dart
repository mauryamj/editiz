import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:editiz/cubits/editor_cubit.dart';
import 'package:editiz/models/edit_state.dart';
import 'package:editiz/widgets/expressive_loader.dart';

// Class: editor screen handling video preview, trim slider, rotate, filters, and audio adjustments.
class EditorScreen extends StatefulWidget {
  // Field: path to the local video file.
  final String videoPath;

  // Constructor: requires videoPath.
  const EditorScreen({super.key, required this.videoPath});

  // Override: creates State object.
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

// Class: state tracking lifecycle (WidgetsBindingObserver) and active tool tab.
class _EditorScreenState extends State<EditorScreen> with WidgetsBindingObserver {
  // Field: active editor cubit reference.
  late final EditorCubit _editorCubit;

  // Field: selected edit tab (0 = Rotate, 1 = Filters, 2 = Audio).
  int _selectedTabIndex = 0;

  // Override: attaches observer and initializes cubit.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _editorCubit = EditorCubit(videoPath: widget.videoPath);
  }

  // Override: pauses video on app background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _editorCubit.pause();
    }
  }

  // Override: removes observer and closes cubit.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _editorCubit.close();
    super.dispose();
  }

  // Method: formats Duration to MM:SS string.
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Method: computes 4x5 color matrix for real-time brightness and contrast.
  static ColorFilter computeColorFilter(double brightness, double contrast) {
    final off = (128.0 * (1.0 - contrast)) + (255.0 * brightness);
    return ColorFilter.matrix(<double>[
      contrast, 0, 0, 0, off,
      0, contrast, 0, 0, off,
      0, 0, contrast, 0, off,
      0, 0, 0, 1, 0,
    ]);
  }

  // Override: builds the responsive editor screen.
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _editorCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Video', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            BlocBuilder<EditorCubit, EditorState>(
              builder: (context, state) {
                if (state is EditorReady && state.editState.hasEdits) {
                  return TextButton(
                    onPressed: () => _editorCubit.resetAll(),
                    child: const Text('Reset All', style: TextStyle(fontWeight: FontWeight.w700)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<EditorCubit, EditorState>(
          builder: (context, state) {
            if (state is EditorLoading) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExpressiveLoader(size: 56),
                    SizedBox(height: 20),
                    Text(
                      'Loading video...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }

            if (state is EditorFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Choose Another Video'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is EditorReady) {
              return _buildEditorContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // Method: builds scrollable editor layout ensuring no overflow on small screens.
  Widget _buildEditorContent(BuildContext context, EditorReady state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final editState = state.editState;
    final controller = state.controller;

    final filter = computeColorFilter(editState.brightness, editState.contrast);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Preview Container
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 280),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio > 0
                              ? controller.value.aspectRatio
                              : 16 / 9,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ColorFiltered(
                                colorFilter: filter,
                                child: RotatedBox(
                                  quarterTurns: editState.quarterTurns,
                                  child: VideoPlayer(controller),
                                ),
                              ),
                              // Play/Pause Overlay Button
                              GestureDetector(
                                onTap: () => _editorCubit.togglePlayPause(),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24, width: 1.5),
                                  ),
                                  child: Icon(
                                    state.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                              // Audio Muted Indicator Badge
                              if (editState.isMuted)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.volume_off_rounded,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Seek Slider + Timestamps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(state.position),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formatDuration(editState.total),
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: state.position.inMilliseconds
                          .clamp(
                            editState.start.inMilliseconds,
                            editState.end.inMilliseconds,
                          )
                          .toDouble(),
                      min: editState.start.inMilliseconds.toDouble(),
                      max: editState.end.inMilliseconds.toDouble(),
                      onChanged: (val) {
                        _editorCubit.seekTo(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Trim Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trim Video',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Selected: ${formatDuration(editState.selectedDuration)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: editState.isValid ? colorScheme.primary : colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RangeSlider(
                    values: RangeValues(
                      editState.start.inMilliseconds.toDouble(),
                      editState.end.inMilliseconds.toDouble(),
                    ),
                    min: 0.0,
                    max: editState.total.inMilliseconds.toDouble(),
                    activeColor: editState.isValid ? colorScheme.primary : colorScheme.error,
                    onChanged: (values) {
                      _editorCubit.updateTrimRange(
                        Duration(milliseconds: values.start.toInt()),
                        Duration(milliseconds: values.end.toInt()),
                      );
                    },
                  ),
                  if (!editState.isValid)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        'Minimum trim duration is 1 second',
                        style: TextStyle(fontSize: 12, color: colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Tab Selection Chips: Rotate, Filters, Audio
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Rotate'),
                        selected: _selectedTabIndex == 0,
                        onSelected: (val) => setState(() => _selectedTabIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Filters'),
                        selected: _selectedTabIndex == 1,
                        onSelected: (val) => setState(() => _selectedTabIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Audio'),
                        selected: _selectedTabIndex == 2,
                        onSelected: (val) => setState(() => _selectedTabIndex = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tool Panel according to selected tab
                  _buildToolPanel(context, editState),
                  const SizedBox(height: 16),

                  // Summary of current edits
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(60),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Edits: ${editState.editsSummary}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Save Button Container at bottom (Save Coral: #FF7A59)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A59),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                onPressed: editState.isValid
                    ? () {
                        // Will trigger ExportSheet in Phase 6.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Export workflow begins in Phase 6')),
                        );
                      }
                    : null,
                child: const Text(
                  'Save Video',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method: builds tool panel for Rotate, Filters, or Audio.
  Widget _buildToolPanel(BuildContext context, EditState editState) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_selectedTabIndex == 0) {
      // Rotate Panel
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rotate 90°',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Current: ${editState.quarterTurns * 90}°',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            FilledButton.tonalIcon(
              onPressed: () => _editorCubit.rotateClockwise(),
              icon: const Icon(Icons.rotate_right_rounded),
              label: const Text('Rotate'),
            ),
          ],
        ),
      );
    } else if (_selectedTabIndex == 1) {
      // Filters Panel (Brightness & Contrast)
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Brightness', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${(editState.brightness * 100).toInt()}%'),
              ],
            ),
            Slider(
              value: editState.brightness,
              min: -0.5,
              max: 0.5,
              onChanged: (val) => _editorCubit.setBrightness(val),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Contrast', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${editState.contrast.toStringAsFixed(1)}x'),
              ],
            ),
            Slider(
              value: editState.contrast,
              min: 0.5,
              max: 1.5,
              onChanged: (val) => _editorCubit.setContrast(val),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _editorCubit.resetFilters(),
                child: const Text('Reset Filters', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    } else {
      // Audio Panel (Mute)
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Audio Track', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  editState.isMuted ? 'Audio stripped (Muted)' : 'Original audio enabled',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            Switch(
              value: !editState.isMuted,
              onChanged: (_) => _editorCubit.toggleMute(),
            ),
          ],
        ),
      );
    }
  }
}
