import 'dart:io';
import 'package:editiz/data/creations_local_source.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/models/creation.dart';

// Class: repository managing the lifecycle and persistence of creations.
class CreationsRepository {
  // Field: local Hive data source.
  final CreationsLocalSource _localSource;

  // Field: file service for disk operations.
  final FileService _fileService;

  // Constructor: requires localSource and fileService.
  const CreationsRepository({
    required this._localSource,
    required this._fileService,
  });

  // Method: loads all saved creations, purging entries whose video files were deleted.
  Future<List<Creation>> getCreations() async {
    final rawList = _localSource.getAllCreations();
    final validCreations = <Creation>[];

    for (final map in rawList) {
      final creation = Creation.fromMap(map);
      final exists = await File(creation.filePath).exists();
      if (!exists) {
        // Automatically cleanup orphaned record and thumbnail.
        await _localSource.deleteCreation(creation.id);
        await _fileService.deleteFile(creation.thumbnailPath);
      } else {
        validCreations.add(creation);
      }
    }

    // Sort newest first.
    validCreations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return validCreations;
  }

  // Method: saves a newly exported creation.
  Future<void> saveCreation(Creation creation) async {
    await _localSource.addCreation(creation.toMap());
  }

  // Method: deletes the creation record and its associated video and thumbnail files.
  Future<void> deleteCreation(Creation creation) async {
    await _localSource.deleteCreation(creation.id);
    await _fileService.deleteFile(creation.filePath);
    await _fileService.deleteFile(creation.thumbnailPath);
  }
}
