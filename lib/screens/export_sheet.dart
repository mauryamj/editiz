import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:editiz/cubits/creations_cubit.dart';
import 'package:editiz/cubits/export_cubit.dart';
import 'package:editiz/models/edit_state.dart';
import 'package:editiz/screens/main_screen.dart';
import 'package:editiz/widgets/expressive_loader.dart';

// Class: non-dismissible modal bottom sheet showing export progress, cancellation, success, or failure with retry.
class ExportSheet extends StatelessWidget {
  // Field: source video path.
  final String inputPath;

  // Field: edit state configuration snapshot.
  final EditState editState;

  // Constructor: requires inputPath and editState snapshot.
  const ExportSheet({
    super.key,
    required this.inputPath,
    required this.editState,
  });

  // Method: displays the ExportSheet modal.
  static void show(
    BuildContext context, {
    required String inputPath,
    required EditState editState,
    required ExportCubit exportCubit,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: exportCubit,
          child: PopScope(
            canPop: false,
            child: ExportSheet(inputPath: inputPath, editState: editState),
          ),
        );
      },
    );
  }

  // Override: builds the export sheet layout with reactive states.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<ExportCubit, ExportState>(
      listener: (context, state) {
        if (state is ExportCancelled) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state is ExportInProgress) ...[
                  const Text(
                    'Saving Video...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Encoding changes directly on your device.',
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: state.progress > 0.05 ? state.progress : null,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '${(state.progress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                      onPressed: () => context.read<ExportCubit>().cancelExport(),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ] else if (state is ExportSuccess) ...[
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B8A9).withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF00B8A9),
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Video Saved Successfully!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your clip is ready in Creations.',
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00B8A9),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        // Refresh creations list, switch tab to Creations, and pop back to MainScreen
                        context.read<CreationsCubit>().loadCreations();
                        MainScreen.tab.value = 1;
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('View in Creations', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ] else if (state is ExportFailure) ...[
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: colorScheme.error.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: colorScheme.error,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Export Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(shape: const StadiumBorder()),
                          onPressed: () {
                            context.read<ExportCubit>().startExport(
                                  inputPath: inputPath,
                                  editState: editState,
                                );
                          },
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: ExpressiveLoader(size: 48)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
