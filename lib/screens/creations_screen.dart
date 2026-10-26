import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:editiz/cubits/creations_cubit.dart';
import 'package:editiz/models/creation.dart';
import 'package:editiz/screens/player_screen.dart';
import 'package:editiz/widgets/expressive_loader.dart';

// Class: creations screen showing responsive grid of exported videos, playback, share, and deletion.
class CreationsScreen extends StatelessWidget {
  // Constructor: const key constructor.
  const CreationsScreen({super.key});

  // Method: formats milliseconds duration into MM:SS string.
  static String formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Method: formats epoch timestamp to readable date string.
  static String formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // Method: formats bytes to MB.
  static String formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  // Method: shares video file with share_plus.
  Future<void> _shareVideo(BuildContext context, Creation creation) async {
    final file = File(creation.filePath);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video file was deleted or moved.')),
      );
      context.read<CreationsCubit>().loadCreations();
      return;
    }

    final xFile = XFile(creation.filePath, name: creation.fileName);
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: 'Check out my clip edited with editiz!',
      ),
    );
  }

  // Method: confirms deletion and cleans up both Hive record and video/thumbnail files.
  void _confirmDelete(BuildContext context, Creation creation) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Creation?'),
          content: Text(
            'Are you sure you want to delete "${creation.fileName}"? This will permanently remove the video from your device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<CreationsCubit>().deleteCreation(creation);
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

  // Method: checks if video exists before navigating to player.
  Future<void> _playVideo(BuildContext context, Creation creation) async {
    final file = File(creation.filePath);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video was deleted or moved.')),
      );
      context.read<CreationsCubit>().loadCreations();
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

  // Override: builds the Creations tab UI.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Creations',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<CreationsCubit, CreationsState>(
        builder: (context, state) {
          if (state is CreationsLoading) {
            return const Center(child: ExpressiveLoader(size: 48));
          }

          if (state is CreationsFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.read<CreationsCubit>().loadCreations(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is CreationsLoaded) {
            if (state.creations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(80),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.video_library_outlined,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No creations yet',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Videos you edit and save will appear here in your collection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<CreationsCubit>().loadCreations(),
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: state.creations.length,
                itemBuilder: (context, index) {
                  final creation = state.creations[index];
                  return _CreationCard(
                    creation: creation,
                    onTap: () => _playVideo(context, creation),
                    onShare: () => _shareVideo(context, creation),
                    onDelete: () => _confirmDelete(context, creation),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// Class: adaptive creation card with thumbnail, duration badge, metadata, and quick actions.
class _CreationCard extends StatelessWidget {
  // Field: creation data.
  final Creation creation;

  // Field: tap callback for playing.
  final VoidCallback onTap;

  // Field: share callback.
  final VoidCallback onShare;

  // Field: delete callback.
  final VoidCallback onDelete;

  // Constructor: requires creation and callbacks.
  const _CreationCard({
    required this.creation,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  // Override: builds creation card according to Material 3 Expressive guidelines.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final thumbFile = File(creation.thumbnailPath);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(70),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail container with duration badge
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    child: thumbFile.existsSync()
                        ? Image.file(thumbFile, fit: BoxFit.cover)
                        : Container(
                            color: colorScheme.primaryContainer,
                            child: const Center(
                              child: Icon(Icons.movie_creation_outlined, size: 40),
                            ),
                          ),
                  ),
                  // Duration badge bottom right
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        CreationsScreen.formatDuration(creation.durationMs),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card metadata & actions
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creation.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${CreationsScreen.formatDate(creation.createdAt)} • ${CreationsScreen.formatSize(creation.sizeBytes)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.share_outlined),
                        onPressed: onShare,
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: Colors.redAccent,
                        onPressed: onDelete,
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
  }
}
