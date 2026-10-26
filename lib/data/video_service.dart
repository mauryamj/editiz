import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:editiz/models/app_exception.dart';
import 'package:editiz/models/edit_state.dart';

// Class: service for executing asynchronous FFmpeg export and command construction.
class VideoService {
  // Method: builds the exact FFmpeg command arguments string from EditState.
  static String buildFFmpegCommand({
    required String inputPath,
    required String outputPath,
    required EditState editState,
  }) {
    final startSec = (editState.start.inMilliseconds / 1000.0).toStringAsFixed(3);
    final durationSec = (editState.selectedDuration.inMilliseconds / 1000.0).toStringAsFixed(3);

    final vfFilters = <String>[];

    // Transpose filter for rotations
    if (editState.quarterTurns == 1) {
      vfFilters.add('transpose=1');
    } else if (editState.quarterTurns == 2) {
      vfFilters.add('transpose=1,transpose=1');
    } else if (editState.quarterTurns == 3) {
      vfFilters.add('transpose=2');
    }

    // Brightness and contrast filters if not default
    if (editState.brightness != 0.0 || editState.contrast != 1.0) {
      final b = editState.brightness.toStringAsFixed(2);
      final c = editState.contrast.toStringAsFixed(2);
      vfFilters.add('eq=brightness=$b:contrast=$c');
    }

    final vfArg = vfFilters.isNotEmpty ? '-vf "${vfFilters.join(',')}"' : '';
    final audioArg = editState.isMuted ? '-an' : '-c:a aac';

    return '-y -ss $startSec -i "$inputPath" -t $durationSec '
        '$vfArg '
        '-c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p '
        '$audioArg "$outputPath"'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Method: executes export asynchronously, reporting progress and returning session ID.
  Future<void> exportVideo({
    required String inputPath,
    required String outputPath,
    required EditState editState,
    required void Function(double progress) onProgress,
    required void Function(int sessionId) onSessionCreated,
  }) async {
    final totalDurationMs = editState.selectedDuration.inMilliseconds;
    final command = buildFFmpegCommand(
      inputPath: inputPath,
      outputPath: outputPath,
      editState: editState,
    );

    var hasNoSpaceError = false;

    final session = await FFmpegKit.executeAsync(
      command,
      (session) async {
        // Complete callback
      },
      (log) {
        if (log.getMessage().toLowerCase().contains('no space left')) {
          hasNoSpaceError = true;
        }
      },
      (statistics) {
        if (totalDurationMs > 0) {
          final time = statistics.getTime();
          final progress = (time / totalDurationMs).clamp(0.0, 1.0);
          onProgress(progress);
        }
      },
    );

    final sessionId = session.getSessionId();
    if (sessionId != null) {
      onSessionCreated(sessionId);
    }

    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      onProgress(1.0);
      return;
    }

    // Clean up partial file on failure or cancel
    try {
      final file = File(outputPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    if (ReturnCode.isCancel(returnCode)) {
      throw const AppException('Export cancelled.');
    }

    if (hasNoSpaceError) {
      throw const AppException('Not enough storage to save.');
    }

    throw const AppException('Something went wrong while saving.');
  }

  // Method: cancels an active FFmpeg session by session ID.
  Future<void> cancelExport(int sessionId) async {
    await FFmpegKit.cancel(sessionId);
  }
}
