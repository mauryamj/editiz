import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:editiz/controllers/creations_controller.dart';
import 'package:editiz/models/creation.dart';
import 'package:editiz/screens/player_screen.dart';

/// Screen displaying saved videos in a responsive grid with play, share, and delete.
class CreationsScreen extends StatelessWidget {
  const CreationsScreen({super.key});

  static String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  static String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _shareVideo(BuildContext context, Creation creation) async {
    final file = File(creation.filePath);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video file not found.')),
      );
      context.read<CreationsController>().loadCreations();
      return;
    }

    final xFile = XFile(creation.filePath, name: creation.fileName);
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: 'Check out my edited video!',
      ),
    );
  }

  void _confirmDelete(BuildContext context, Creation creation) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Creation?'),
          content: Text('Are you sure you want to delete "${creation.fileName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<CreationsController>().deleteCreation(creation);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video deleted.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playVideo(BuildContext context, Creation creation) async {
    final file = File(creation.filePath);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video was deleted or moved.')),
      );
      context.read<CreationsController>().loadCreations();
      return;
    }

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          videoPath: creation.filePath,
          title: creation.fileName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final creationsCtrl = context.watch<CreationsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creations', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Builder(
        builder: (context) {
          if (creationsCtrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (creationsCtrl.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      creationsCtrl.errorMessage!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => creationsCtrl.loadCreations(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (creationsCtrl.creations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No creations yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved videos will appear here.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => creationsCtrl.loadCreations(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: creationsCtrl.creations.length,
              itemBuilder: (context, index) {
                final creation = creationsCtrl.creations[index];
                final thumbFile = File(creation.thumbnailPath);

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _playVideo(context, creation),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              thumbFile.existsSync()
                                  ? Image.file(thumbFile, fit: BoxFit.cover)
                                  : Container(
                                      color: colorScheme.surfaceContainerHighest,
                                      child: const Center(
                                        child: Icon(Icons.movie_outlined, size: 36),
                                      ),
                                    ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatDuration(creation.durationMs),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                creation.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDate(creation.createdAt)} • ${_formatSize(creation.sizeBytes)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    iconSize: 18,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.share_outlined),
                                    onPressed: () => _shareVideo(context, creation),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    iconSize: 18,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _confirmDelete(context, creation),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
}
