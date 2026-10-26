import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:editiz/cubits/editor_cubit.dart';
import 'package:editiz/cubits/export_cubit.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/data/video_service.dart';
import 'package:editiz/models/edit_state.dart';
import 'package:editiz/repositories/creations_repository.dart';
import 'package:editiz/screens/export_sheet.dart';
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

  // Field: selected edit tab (0 = Trim, 1 = Rotate, 2 = Filters, 3 = Audio).
  int _selectedTabIndex = 1; // Default to Rotate as in Stitch reference

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

  // Method: triggers export and opens the progress modal sheet.
  void _saveVideo(BuildContext context, EditState editState) {
    if (!editState.isValid) return;
    _editorCubit.pause();
    final exportCubit = ExportCubit(
      videoService: context.read<VideoService>(),
      fileService: context.read<FileService>(),
      creationsRepository: context.read<CreationsRepository>(),
    );
    exportCubit.startExport(
      inputPath: widget.videoPath,
      editState: editState.copyWith(),
    );
    ExportSheet.show(
      context,
      inputPath: widget.videoPath,
      editState: editState.copyWith(),
      exportCubit: exportCubit,
    );
  }

  // Override: builds the responsive editor screen.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fileName = widget.videoPath.split(RegExp(r'[\\/]')).last;

    return BlocProvider.value(
      value: _editorCubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: BlocBuilder<EditorCubit, EditorState>(
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (state is EditorReady)
                    Text(
                      formatDuration(state.editState.total),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              );
            },
          ),
          actions: [
            BlocBuilder<EditorCubit, EditorState>(
              builder: (context, state) {
                if (state is EditorReady) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restart_alt_rounded),
                        tooltip: 'Reset all',
                        onPressed: state.editState.hasEdits
                            ? () => _editorCubit.resetAll()
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A59),
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 36),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: state.editState.isValid
                              ? () => _saveVideo(context, state.editState)
                              : null,
                        ),
                      ),
                    ],
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

  // Method: builds scrollable editor layout matching Stitch design.
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
                  // Video Preview Container with Stitch Overlays
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 280),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
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
                              // Audio Muted Indicator Badge (Bottom Left)
                              if (editState.isMuted)
                                Positioned(
                                  bottom: 12,
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
                              // Center Play/Pause Glass Button
                              GestureDetector(
                                onTap: () => _editorCubit.togglePlayPause(),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(210),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(80),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    state.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: colorScheme.primary,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Unified Timeline Scrubbing Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(60),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.movie_creation_outlined,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Timeline',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withAlpha(60),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Trim ${formatDuration(editState.selectedDuration)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: editState.isValid
                                          ? colorScheme.primary
                                          : colorScheme.error,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total ${formatDuration(editState.total)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Trim RangeSlider
                        RangeSlider(
                          values: RangeValues(
                            editState.start.inMilliseconds.toDouble(),
                            editState.end.inMilliseconds.toDouble(),
                          ),
                          min: 0.0,
                          max: editState.total.inMilliseconds.toDouble(),
                          activeColor: editState.isValid
                              ? colorScheme.primary
                              : colorScheme.error,
                          onChanged: (values) {
                            _editorCubit.updateTrimRange(
                              Duration(milliseconds: values.start.toInt()),
                              Duration(milliseconds: values.end.toInt()),
                            );
                          },
                        ),
                        // Seek Scrubber Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
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
                              _editorCubit.seekTo(
                                Duration(milliseconds: val.toInt()),
                              );
                            },
                          ),
                        ),
                        // Time readouts: In, Current, Out
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${formatDuration(editState.start)} (In)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${formatDuration(state.position)} (Current)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${formatDuration(editState.end)} (Out)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (!editState.isValid) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Minimum trim duration is 1 second',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thumb-Zone Tool Category Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          avatar: const Icon(
                            Icons.content_cut_rounded,
                            size: 16,
                          ),
                          label: const Text('Trim'),
                          selected: _selectedTabIndex == 0,
                          onSelected: (val) =>
                              setState(() => _selectedTabIndex = 0),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(
                            Icons.rotate_right_rounded,
                            size: 18,
                          ),
                          label: const Text('Rotate'),
                          selected: _selectedTabIndex == 1,
                          onSelected: (val) =>
                              setState(() => _selectedTabIndex = 1),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                          ),
                          label: const Text('Filters'),
                          selected: _selectedTabIndex == 2,
                          onSelected: (val) =>
                              setState(() => _selectedTabIndex = 2),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.volume_up_rounded, size: 16),
                          label: const Text('Audio'),
                          selected: _selectedTabIndex == 3,
                          onSelected: (val) =>
                              setState(() => _selectedTabIndex = 3),
                        ),
                      ],
                    ),
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
                      color: colorScheme.surfaceContainerHighest.withAlpha(50),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            editState.editsSummary,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

         
        ],
      ),
    );
  }

  // Method: builds tool panel for Trim, Rotate, Filters, or Audio.
  Widget _buildToolPanel(BuildContext context, EditState editState) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_selectedTabIndex == 0) {
      // Trim Panel with quick adjustment hints
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.content_cut_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Trim Controls',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatDuration(editState.selectedDuration),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Drag the handles in the timeline above to trim your clip.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      final half = Duration(
                        milliseconds: editState.total.inMilliseconds ~/ 2,
                      );
                      _editorCubit.updateTrimRange(Duration.zero, half);
                    },
                    child: const Text('First Half'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      _editorCubit.updateTrimRange(
                        Duration.zero,
                        editState.total,
                      );
                    },
                    child: const Text('Reset Trim'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_selectedTabIndex == 1) {
      // Rotate Panel (Rotate Left, Rotate Right, Reset Rotation per Stitch reference)
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.screen_rotation_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Orientation & Transform',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(60),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${editState.quarterTurns * 90}° Step',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _editorCubit.rotateCounterClockwise(),
                    icon: const Icon(Icons.rotate_left_rounded, size: 20),
                    label: const Text(
                      '-90° Left',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _editorCubit.rotateClockwise(),
                    icon: const Icon(Icons.rotate_right_rounded, size: 20),
                    label: const Text(
                      '+90° Right',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _editorCubit.resetRotation(),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text(
                      'Reset',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_selectedTabIndex == 2) {
      // Filters Panel (Brightness & Contrast)
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.light_mode_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Brightness',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '${editState.brightness >= 0 ? '+' : ''}${(editState.brightness * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
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
                Row(
                  children: [
                    const Icon(Icons.contrast_rounded, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Contrast',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '${editState.contrast.toStringAsFixed(1)}x',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
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
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  editState.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  size: 24,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audio Track',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      editState.isMuted
                          ? 'Audio stripped (Muted)'
                          : 'Original audio enabled',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
