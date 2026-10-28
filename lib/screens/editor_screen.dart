import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:editiz/controllers/editor_controller.dart';
import 'package:editiz/controllers/export_controller.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/data/video_service.dart';
import 'package:editiz/models/edit_state.dart';
import 'package:editiz/repositories/creations_repository.dart';
import 'package:editiz/screens/export_sheet.dart';

/// Video editing screen: trim, rotate, filters, and mute controls.
class EditorScreen extends StatefulWidget {
  final String videoPath;

  const EditorScreen({super.key, required this.videoPath});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with WidgetsBindingObserver {
  late final EditorController _editorController;
  int _selectedTabIndex = 0; // 0: Trim, 1: Rotate, 2: Filters, 3: Audio

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _editorController = EditorController(videoPath: widget.videoPath);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _editorController.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _editorController.dispose();
    super.dispose();
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static ColorFilter _computeColorFilter(double brightness, double contrast) {
    final off = (128.0 * (1.0 - contrast)) + (255.0 * brightness);
    return ColorFilter.matrix(<double>[
      contrast, 0, 0, 0, off,
      0, contrast, 0, 0, off,
      0, 0, contrast, 0, off,
      0, 0, 0, 1, 0,
    ]);
  }

  void _saveVideo(BuildContext context, EditState editState) {
    if (!editState.isValid) return;
    _editorController.pause();

    final exportController = ExportController(
      videoService: context.read<VideoService>(),
      fileService: context.read<FileService>(),
      creationsRepository: context.read<CreationsRepository>(),
    );

    exportController.startExport(
      inputPath: widget.videoPath,
      editState: editState,
    );

    ExportSheet.show(
      context,
      inputPath: widget.videoPath,
      editState: editState,
      exportController: exportController,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.videoPath.split(RegExp(r'[\\/]')).last;

    return ChangeNotifierProvider.value(
      value: _editorController,
      child: Consumer<EditorController>(
        builder: (context, editor, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(fileName, style: const TextStyle(fontSize: 16)),
              actions: [
                if (!editor.isLoading && editor.errorMessage == null) ...[
                  IconButton(
                    icon: const Icon(Icons.restart_alt),
                    tooltip: 'Reset edits',
                    onPressed: editor.editState.hasEdits ? () => editor.resetAll() : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A59),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: editor.editState.isValid
                          ? () => _saveVideo(context, editor.editState)
                          : null,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ],
            ),
            body: Builder(
              builder: (context) {
                if (editor.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading video...'),
                      ],
                    ),
                  );
                }

                if (editor.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(
                            editor.errorMessage!,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Back'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final controller = editor.playerController;
                if (controller == null) return const SizedBox.shrink();

                final editState = editor.editState;
                final filter = _computeColorFilter(editState.brightness, editState.contrast);

                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Video Player Preview
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 280),
                              color: Colors.black,
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
                                    // Mute indicator
                                    if (editState.isMuted)
                                      const Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Icon(Icons.volume_off, color: Colors.white70, size: 20),
                                      ),
                                    // Play / pause button
                                    IconButton(
                                      iconSize: 56,
                                      icon: Icon(
                                        editor.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () => editor.togglePlayPause(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Timeline & Trim Section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Trim & Seek', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      'Duration: ${_formatDuration(editState.selectedDuration)}',
                                      style: TextStyle(
                                        color: editState.isValid ? Theme.of(context).colorScheme.primary : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                RangeSlider(
                                  values: RangeValues(
                                    editState.start.inMilliseconds.toDouble(),
                                    editState.end.inMilliseconds.toDouble(),
                                  ),
                                  min: 0.0,
                                  max: editState.total.inMilliseconds.toDouble(),
                                  onChanged: (values) {
                                    editor.updateTrimRange(
                                      Duration(milliseconds: values.start.toInt()),
                                      Duration(milliseconds: values.end.toInt()),
                                    );
                                  },
                                ),
                                Slider(
                                  value: editor.position.inMilliseconds
                                      .clamp(editState.start.inMilliseconds, editState.end.inMilliseconds)
                                      .toDouble(),
                                  min: editState.start.inMilliseconds.toDouble(),
                                  max: editState.end.inMilliseconds.toDouble(),
                                  onChanged: (val) {
                                    editor.seekTo(Duration(milliseconds: val.toInt()));
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Start: ${_formatDuration(editState.start)}', style: const TextStyle(fontSize: 12)),
                                    Text('Cur: ${_formatDuration(editor.position)}', style: const TextStyle(fontSize: 12)),
                                    Text('End: ${_formatDuration(editState.end)}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                if (!editState.isValid)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Center(
                                      child: Text(
                                        'Minimum trim duration is 1 second',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Edit Tool Tabs
                        Row(
                          children: [
                            _buildTabChip(0, 'Trim', Icons.content_cut),
                            const SizedBox(width: 8),
                            _buildTabChip(1, 'Rotate', Icons.rotate_right),
                            const SizedBox(width: 8),
                            _buildTabChip(2, 'Filters', Icons.tune),
                            const SizedBox(width: 8),
                            _buildTabChip(3, 'Audio', Icons.volume_up),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tool Panel Body
                        _buildToolBody(context, editor),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabChip(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTabIndex = index),
    );
  }

  Widget _buildToolBody(BuildContext context, EditorController editor) {
    final editState = editor.editState;

    if (_selectedTabIndex == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final half = Duration(milliseconds: editState.total.inMilliseconds ~/ 2);
                    editor.updateTrimRange(Duration.zero, half);
                  },
                  child: const Text('First Half'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => editor.updateTrimRange(Duration.zero, editState.total),
                  child: const Text('Reset Trim'),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_selectedTabIndex == 1) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Rotation: ${editState.quarterTurns * 90}°', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => editor.rotateCounterClockwise(),
                      icon: const Icon(Icons.rotate_left),
                      label: const Text('-90°'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => editor.rotateClockwise(),
                      icon: const Icon(Icons.rotate_right),
                      label: const Text('+90°'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => editor.resetRotation(),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (_selectedTabIndex == 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Brightness'),
                  Text('${(editState.brightness * 100).toInt()}%'),
                ],
              ),
              Slider(
                value: editState.brightness,
                min: -0.5,
                max: 0.5,
                onChanged: (v) => editor.setBrightness(v),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Contrast'),
                  Text('${editState.contrast.toStringAsFixed(1)}x'),
                ],
              ),
              Slider(
                value: editState.contrast,
                min: 0.5,
                max: 1.5,
                onChanged: (v) => editor.setContrast(v),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => editor.resetFilters(),
                  child: const Text('Reset Filters'),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mute Audio', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    editState.isMuted ? 'Audio will be stripped from video' : 'Audio enabled',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              Switch(
                value: editState.isMuted,
                onChanged: (_) => editor.toggleMute(),
              ),
            ],
          ),
        ),
      );
    }
  }
}
