import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:editiz/cubits/creations_cubit.dart';
import 'package:editiz/cubits/home_cubit.dart';
import 'package:editiz/cubits/tips_cubit.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/data/permission_service.dart';
import 'package:editiz/models/creation.dart';
import 'package:editiz/screens/editor_screen.dart';
import 'package:editiz/widgets/expressive_loader.dart';

// Class: home screen displaying hero action card, video pick sheet, recent edits, and tips.
class HomeScreen extends StatelessWidget {
  // Constructor: const key constructor.
  const HomeScreen({super.key});

  // Method: formats milliseconds into MM:SS string.
  static String formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Method: displays bottom sheet with Gallery and File picker options.
  void _showPickOptionsSheet(BuildContext context, HomeCubit homeCubit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Video Source',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose where you want to import your video clip from.',
                  style: TextStyle(fontSize: 14, color: Colors.white60),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text(
                    'Gallery / Photos',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Pick from your phone gallery'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    homeCubit.pickFromGallery();
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_open_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text(
                    'Files / Device Storage',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Browse mp4, mov, mkv, webm files'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    homeCubit.pickFromFileSystem();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method: shows permission error dialog with settings action.
  void _showPermissionDialog(BuildContext context, HomeCubit cubit, bool permanent) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Text(
            permanent
                ? 'Video access permission is permanently denied. Please enable it in Settings to continue.'
                : 'editiz requires video permission to select and edit clips on your device.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                cubit.reset();
              },
              child: const Text('Cancel'),
            ),
            if (permanent)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  cubit.openSettings();
                },
                child: const Text('Open Settings'),
              )
            else
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  cubit.pickFromGallery();
                },
                child: const Text('Grant Access'),
              ),
          ],
        );
      },
    );
  }

  // Override: builds the home screen with BlocProvider for HomeCubit.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider(
      create: (context) => HomeCubit(
        fileService: context.read<FileService>(),
        permissionService: context.read<PermissionService>(),
      ),
      child: Builder(
        builder: (screenContext) {
          final homeCubit = screenContext.read<HomeCubit>();

          return BlocListener<HomeCubit, HomeState>(
            listener: (context, state) {
              if (state is HomePicked) {
                homeCubit.reset();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditorScreen(videoPath: state.path),
                  ),
                );
              } else if (state is HomePermissionDenied) {
                _showPermissionDialog(context, homeCubit, state.permanent);
              } else if (state is HomeFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: colorScheme.error,
                  ),
                );
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Let's edit something",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                centerTitle: false,
              ),
              body: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Card
                        _HeroCard(
                          onPickPressed: () => _showPickOptionsSheet(context, homeCubit),
                        ),
                        const SizedBox(height: 24),

                        // Tip Card
                        const _TipCardSection(),
                        const SizedBox(height: 24),

                        // Recent Videos Section Header
                        const Text(
                          'Recent Edits',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),

                        // Recent Videos List or Empty State
                        const _RecentEditsSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Picking loading overlay
                  BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) {
                      if (state is HomePicking) {
                        return Container(
                          color: Colors.black54,
                          child: const Center(
                            child: ExpressiveLoader(size: 56),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Class: decorative hero card with gradient and pick action button.
class _HeroCard extends StatelessWidget {
  // Field: callback when pick action is tapped.
  final VoidCallback onPickPressed;

  // Constructor: requires callback.
  const _HeroCard({required this.onPickPressed});

  // Override: builds hero card.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.primary.withAlpha(40),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_fix_high_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Transform.rotate(
                  angle: -0.06,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(50),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary.withAlpha(80)),
                    ),
                    child: Text(
                      'On-Device Fast',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Create Fast Clips',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Trim, rotate, enhance brightness, adjust contrast, and mute audio with zero quality loss.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: onPickPressed,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text(
                'Pick a Video',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Class: section displaying recent creations or an expressive empty state.
class _RecentEditsSection extends StatelessWidget {
  // Constructor: const key constructor.
  const _RecentEditsSection();

  // Override: builds recent creations section.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<CreationsCubit, CreationsState>(
      builder: (context, state) {
        if (state is CreationsLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: ExpressiveLoader(size: 36)),
          );
        }

        if (state is CreationsLoaded) {
          if (state.creations.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(60),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.video_collection_outlined,
                    size: 44,
                    color: colorScheme.onSurfaceVariant.withAlpha(120),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No videos yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your exported videos will appear right here.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final recentList = state.creations.take(3).toList();
          return Column(
            children: recentList.map((creation) {
              return _RecentCreationTile(creation: creation);
            }).toList(),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// Class: compact tile for displaying a recent creation on Home screen.
class _RecentCreationTile extends StatelessWidget {
  // Field: creation model.
  final Creation creation;

  // Constructor: requires creation.
  const _RecentCreationTile({required this.creation});

  // Override: builds recent video tile.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final thumbFile = File(creation.thumbnailPath);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 64,
              height: 64,
              color: colorScheme.primaryContainer,
              child: thumbFile.existsSync()
                  ? Image.file(thumbFile, fit: BoxFit.cover)
                  : const Icon(Icons.movie_creation_outlined),
            ),
          ),
          const SizedBox(height: 0, width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creation.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  creation.edits.isNotEmpty ? creation.edits : 'Edited Clip',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              HomeScreen.formatDuration(creation.durationMs),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// Class: widget rendering the dynamic editing tip card with retry capability.
class _TipCardSection extends StatelessWidget {
  // Constructor: const key constructor.
  const _TipCardSection();

  // Override: builds the tip card with success teal accents.
  @override
  Widget build(BuildContext context) {
    const successTeal = Color(0xFF00B8A9);

    return BlocBuilder<TipsCubit, TipsState>(
      builder: (context, state) {
        if (state is TipsLoading) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: successTeal.withAlpha(25),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: successTeal.withAlpha(60)),
            ),
            child: const Center(child: ExpressiveLoader(size: 28)),
          );
        }

        if (state is TipsLoaded) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: successTeal.withAlpha(30),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: successTeal.withAlpha(70)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded, color: successTeal, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: successTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  state.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          );
        }

        if (state is TipsFailure) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.white60),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(48, 36),
                  ),
                  onPressed: () => context.read<TipsCubit>().loadTip(),
                  child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
