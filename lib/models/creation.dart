// Class: model representing an edited video saved in the creations list.
class Creation {
  // Field: unique creation identifier (timestamp in ms).
  final int id;

  // Field: absolute file path to the exported MP4 video.
  final String filePath;

  // Field: file name of the video.
  final String fileName;

  // Field: absolute file path to the video thumbnail image.
  final String thumbnailPath;

  // Field: total video duration in milliseconds.
  final int durationMs;

  // Field: file size in bytes.
  final int sizeBytes;

  // Field: creation timestamp in milliseconds since epoch.
  final int createdAt;

  // Field: human-readable summary of applied edits.
  final String edits;

  // Constructor: creates a Creation model.
  const Creation({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.thumbnailPath,
    required this.durationMs,
    required this.sizeBytes,
    required this.createdAt,
    required this.edits,
  });

  // Factory constructor: converts a Hive Map to a Creation instance.
  factory Creation.fromMap(Map<dynamic, dynamic> map) {
    return Creation(
      id: (map['id'] as num?)?.toInt() ?? 0,
      filePath: map['filePath'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      thumbnailPath: map['thumbnailPath'] as String? ?? '',
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      edits: map['edits'] as String? ?? '',
    );
  }

  // Method: converts a Creation instance to a Map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'thumbnailPath': thumbnailPath,
      'durationMs': durationMs,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt,
      'edits': edits,
    };
  }
}
