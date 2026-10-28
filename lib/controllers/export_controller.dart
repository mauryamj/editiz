import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/data/video_service.dart';
import 'package:editiz/models/app_exception.dart';
import 'package:editiz/models/creation.dart';
import 'package:editiz/models/edit_state.dart';
import 'package:editiz/repositories/creations_repository.dart';

/// Simple controller handling video export.
class ExportController extends ChangeNotifier {
  final VideoService videoService;
  final FileService fileService;
  final CreationsRepository creationsRepository;

  bool isExporting = false;
  double progress = 0.0;
  Creation? exportedCreation;
  bool isCancelled = false;
  String? errorMessage;

  int? _activeSessionId;

  ExportController({
    required this.videoService,
    required this.fileService,
    required this.creationsRepository,
  });

  /// Starts exporting video
  Future<void> startExport({
    required String inputPath,
    required EditState editState,
  }) async {
    if (isExporting) return;

    isExporting = true;
    progress = 0.0;
    exportedCreation = null;
    isCancelled = false;
    errorMessage = null;
    notifyListeners();

    final id = DateTime.now().millisecondsSinceEpoch;
    final outPath = await fileService.createExportPath(id);

    try {
      await videoService.exportVideo(
        inputPath: inputPath,
        outputPath: outPath,
        editState: editState,
        onProgress: (prog) {
          progress = prog;
          notifyListeners();
        },
        onSessionCreated: (sessionId) {
          _activeSessionId = sessionId;
        },
      );

      final thumbPath = await fileService.generateThumbnail(outPath, id);
      final outFile = File(outPath);
      final sizeBytes = await outFile.length();

      final creation = Creation(
        id: id,
        filePath: outPath,
        fileName: 'clip_$id.mp4',
        thumbnailPath: thumbPath,
        durationMs: editState.selectedDuration.inMilliseconds,
        sizeBytes: sizeBytes,
        createdAt: id,
        edits: editState.editsSummary,
      );

      await creationsRepository.saveCreation(creation);
      exportedCreation = creation;
    } on AppException catch (e) {
      if (e.message == 'Export cancelled.') {
        isCancelled = true;
      } else {
        errorMessage = e.message;
      }
    } catch (_) {
      errorMessage = 'Something went wrong while saving.';
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  /// Cancels active export
  Future<void> cancelExport() async {
    final sessionId = _activeSessionId;
    if (sessionId != null) {
      await videoService.cancelExport(sessionId);
    }
    isCancelled = true;
    isExporting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (isExporting && _activeSessionId != null) {
      videoService.cancelExport(_activeSessionId!);
    }
    super.dispose();
  }
}
