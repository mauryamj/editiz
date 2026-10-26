import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:editiz/models/app_exception.dart';

// Class: service for file operations, folder structure, validation, and thumbnails.
class FileService {
  // Field: image picker instance for gallery picking.
  final ImagePicker _imagePicker = ImagePicker();

  // Field: supported video file extensions.
  static const Set<String> supportedExtensions = {
    'mp4',
    'mov',
    'mkv',
    'webm',
    '3gp',
  };

  // Method: returns the dedicated VideoEdits directory.
  Future<Directory> getEditsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/VideoEdits');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Method: generates a unique export path for a clip.
  Future<String> createExportPath(int id) async {
    final dir = await getEditsDirectory();
    return '${dir.path}/clip_$id.mp4';
  }

  // Method: generates a unique thumbnail path for a clip.
  Future<String> createThumbnailPath(int id) async {
    final dir = await getEditsDirectory();
    return '${dir.path}/thumb_$id.jpg';
  }

  // Method: validates file extension.
  void validateVideoPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (!supportedExtensions.contains(ext)) {
      throw const AppException("This format isn't supported.");
    }
  }

  // Method: picks a video from the system gallery.
  Future<String?> pickVideoFromGallery() async {
    final xFile = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (xFile == null) return null;
    validateVideoPath(xFile.path);
    return xFile.path;
  }

  // Method: picks a video file using the system file picker.
  Future<String?> pickVideoFromFileSystem() async {
    final files = await FilePicker.pickFiles(
      type: FileType.video,
    );
    if (files.isEmpty) return null;
    final path = files.first.path;
    if (path == null) return null;
    validateVideoPath(path);
    return path;
  }

  // Method: generates a video thumbnail using FFmpeg.
  Future<String> generateThumbnail(String videoPath, int id) async {
    final outPath = await createThumbnailPath(id);
    final command =
        '-y -ss 00:00:00.500 -i "$videoPath" -vframes 1 -vf "scale=480:-1" "$outPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      return outPath;
    }
    // Fallback: extract at 0s if 0.5s failed.
    final fallbackCmd =
        '-y -ss 00:00:00 -i "$videoPath" -vframes 1 -vf "scale=480:-1" "$outPath"';
    final fallbackSession = await FFmpegKit.execute(fallbackCmd);
    if (ReturnCode.isSuccess(await fallbackSession.getReturnCode())) {
      return outPath;
    }
    return '';
  }

  // Method: safely deletes a file if it exists.
  Future<void> deleteFile(String path) async {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignored: best-effort cleanup.
    }
  }
}
