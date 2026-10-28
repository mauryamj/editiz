import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:editiz/controllers/creations_controller.dart';
import 'package:editiz/controllers/export_controller.dart';
import 'package:editiz/models/edit_state.dart';
import 'package:editiz/screens/main_screen.dart';

/// Modal bottom sheet showing export progress, success, or error.
class ExportSheet extends StatelessWidget {
  final String inputPath;
  final EditState editState;

  const ExportSheet({
    super.key,
    required this.inputPath,
    required this.editState,
  });

  /// Displays the ExportSheet modal
  static void show(
    BuildContext context, {
    required String inputPath,
    required EditState editState,
    required ExportController exportController,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: exportController,
          child: PopScope(
            canPop: false,
            child: ExportSheet(inputPath: inputPath, editState: editState),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final export = context.watch<ExportController>();

    if (export.isCancelled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (export.isExporting) ...[
              const Text(
                'Saving Video...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Encoding changes on your device...',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: export.progress > 0.05 ? export.progress : null,
                      strokeWidth: 6,
                    ),
                  ),
                  Text(
                    '${(export.progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: () => export.cancelExport(),
                child: const Text('Cancel'),
              ),
            ] else if (export.exportedCreation != null) ...[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.teal,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Video Saved Successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your clip has been saved to Creations.',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.read<CreationsController>().loadCreations();
                    MainScreen.tab.value = 1; // Switch to creations tab
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('View in Creations'),
                ),
              ),
            ] else if (export.errorMessage != null) ...[
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Export Failed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                export.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        export.startExport(
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
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
