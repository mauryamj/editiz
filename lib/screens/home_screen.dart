import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:editiz/controllers/creations_controller.dart';
import 'package:editiz/controllers/home_controller.dart';
import 'package:editiz/controllers/tips_controller.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/data/permission_service.dart';
import 'package:editiz/screens/editor_screen.dart';

/// Home screen allowing user to pick video, see tip, and view recent edits.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showPickOptionsSheet(BuildContext context, HomeController homeCtrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Video Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  subtitle: const Text('Pick from photos & videos'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    homeCtrl.pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('File Picker'),
                  subtitle: const Text('Browse device files'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    homeCtrl.pickFromFileSystem();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPermissionDialog(BuildContext context, HomeController homeCtrl, bool permanent) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permission Needed'),
          content: Text(
            permanent
                ? 'Video permission is permanently denied. Please enable it in Settings.'
                : 'Permission to access video files is required to select videos.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                homeCtrl.reset();
              },
              child: const Text('Cancel'),
            ),
            if (permanent)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  homeCtrl.openSettings();
                },
                child: const Text('Open Settings'),
              )
            else
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  homeCtrl.pickFromGallery();
                },
                child: const Text('Allow'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create: (context) => HomeController(
        fileService: context.read<FileService>(),
        permissionService: context.read<PermissionService>(),
      ),
      child: Consumer<HomeController>(
        builder: (context, homeCtrl, _) {
          // Listen to state changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (homeCtrl.pickedVideoPath != null) {
              final path = homeCtrl.pickedVideoPath!;
              homeCtrl.clearPickedPath();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditorScreen(videoPath: path),
                ),
              );
            } else if (homeCtrl.permissionDenied) {
              _showPermissionDialog(context, homeCtrl, homeCtrl.isPermanentlyDenied);
            } else if (homeCtrl.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(homeCtrl.errorMessage!),
                  backgroundColor: colorScheme.error,
                ),
              );
              homeCtrl.reset();
            }
          });

          return Scaffold(
            appBar: AppBar(
              title: const Text('editiz', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero card to pick video
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: colorScheme.primary,
                                    child: const Icon(Icons.movie_edit, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Create New Video',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Trim, rotate, adjust brightness & contrast, and mute audio locally.',
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => _showPickOptionsSheet(context, homeCtrl),
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('Select Video to Edit'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tips card
                      const _TipSection(),
                      const SizedBox(height: 20),

                      // Recent edits
                      const Text(
                        'Recent Edits',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const _RecentEditsList(),
                    ],
                  ),
                ),

                // Loading overlay while picking video
                if (homeCtrl.isPicking)
                  Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TipSection extends StatelessWidget {
  const _TipSection();

  @override
  Widget build(BuildContext context) {
    final tipsCtrl = context.watch<TipsController>();

    if (tipsCtrl.isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (tipsCtrl.errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tipsCtrl.errorMessage!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => tipsCtrl.loadTip(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.teal.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tipsCtrl.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tipsCtrl.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentEditsList extends StatelessWidget {
  const _RecentEditsList();

  @override
  Widget build(BuildContext context) {
    final creationsCtrl = context.watch<CreationsController>();

    if (creationsCtrl.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = creationsCtrl.creations.take(3).toList();
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'No saved videos yet.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: list.map((creation) {
        final thumbFile = File(creation.thumbnailPath);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: thumbFile.existsSync()
                    ? Image.file(thumbFile, fit: BoxFit.cover)
                    : const Icon(Icons.movie_outlined),
              ),
            ),
            title: Text(
              creation.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              creation.edits.isNotEmpty ? creation.edits : 'Edited Clip',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              HomeScreen._formatDuration(creation.durationMs),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
