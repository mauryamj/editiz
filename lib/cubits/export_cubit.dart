import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/data/video_service.dart';
import 'package:editiz/models/app_exception.dart';
import 'package:editiz/models/creation.dart';
import 'package:editiz/models/edit_state.dart';
import 'package:editiz/repositories/creations_repository.dart';

// Class: base state for ExportCubit.
abstract class ExportState {
  const ExportState();
}

// Class: idle state before export is started.
class ExportIdle extends ExportState {
  const ExportIdle();
}

// Class: state during export with normalized progress (0.0 to 1.0).
class ExportInProgress extends ExportState {
  // Field: progress percentage from 0.0 to 1.0.
  final double progress;

  // Constructor: requires progress.
  const ExportInProgress(this.progress);
}

// Class: state when export and database persistence succeed.
class ExportSuccess extends ExportState {
  // Field: newly created Creation record.
  final Creation creation;

  // Constructor: requires creation.
  const ExportSuccess(this.creation);
}

// Class: state when export fails.
class ExportFailure extends ExportState {
  // Field: user-friendly error message.
  final String message;

  // Constructor: requires message.
  const ExportFailure(this.message);
}

// Class: state when user explicitly cancels export.
class ExportCancelled extends ExportState {
  const ExportCancelled();
}

// Class: cubit orchestrating video export, progress tracking, and persistence.
class ExportCubit extends Cubit<ExportState> {
  // Field: video service for FFmpeg execution.
  final VideoService _videoService;

  // Field: file service for paths and thumbnail generation.
  final FileService _fileService;

  // Field: creations repository for database persistence.
  final CreationsRepository _creationsRepository;

  // Field: active FFmpeg session ID for cancellation.
  int? _activeSessionId;

  // Field: flag to prevent concurrent double exports.
  bool _isExporting = false;

  // Constructor: starts in ExportIdle.
  ExportCubit({
    required this._videoService,
    required this._fileService,
    required this._creationsRepository,
  })  : super(const ExportIdle());

  // Method: executes export workflow.
  Future<void> startExport({
    required String inputPath,
    required EditState editState,
  }) async {
    if (_isExporting) return; // Prevent double export
    _isExporting = true;
    emit(const ExportInProgress(0.0));

    final id = DateTime.now().millisecondsSinceEpoch;
    final outPath = await _fileService.createExportPath(id);

    try {
      await _videoService.exportVideo(
        inputPath: inputPath,
        outputPath: outPath,
        editState: editState,
        onProgress: (progress) {
          if (!isClosed) emit(ExportInProgress(progress));
        },
        onSessionCreated: (sessionId) {
          _activeSessionId = sessionId;
        },
      );

      // On success: generate thumbnail, get file size, and save in Hive
      final thumbPath = await _fileService.generateThumbnail(outPath, id);
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

      await _creationsRepository.saveCreation(creation);

      _isExporting = false;
      if (!isClosed) emit(ExportSuccess(creation));
    } on AppException catch (e) {
      _isExporting = false;
      if (e.message == 'Export cancelled.') {
        if (!isClosed) emit(const ExportCancelled());
      } else {
        if (!isClosed) emit(ExportFailure(e.message));
      }
    } catch (_) {
      _isExporting = false;
      if (!isClosed) {
        emit(const ExportFailure('Something went wrong while saving.'));
      }
    }
  }

  // Method: cancels the active export session.
  Future<void> cancelExport() async {
    final sessionId = _activeSessionId;
    if (sessionId != null) {
      await _videoService.cancelExport(sessionId);
    }
  }

  // Override: cancels any active FFmpeg session on cubit close.
  @override
  Future<void> close() {
    if (_isExporting && _activeSessionId != null) {
      _videoService.cancelExport(_activeSessionId!);
    }
    return super.close();
  }
}
