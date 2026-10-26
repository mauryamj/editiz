# Editiz — On-Device Video Editing & Creation App

A modern, high-performance Flutter video editing application built with a clean, layered architecture (**Presentation → BLoC/Cubit → Repository → Data/Service**). All video transformations (trimming, 90° stepped rotation, brightness/contrast filters, audio muting) are processed **100% locally on-device** using asynchronous FFmpeg encoding, persisting creations to a local **Hive** database and demonstrating remote API integration via **Dio**.

---

## Table of Contents
1. [Key Features](#key-features)
2. [Architecture Overview](#architecture-overview)
3. [Component Hierarchy & Flow](#component-hierarchy--flow)
4. [Local Video Processing (FFmpeg)](#local-video-processing-ffmpeg)
5. [Local Data Persistence (Hive)](#local-data-persistence-hive)
6. [API Integration (Dio)](#api-integration-dio)
7. [Getting Started & Setup](#getting-started--setup)
8. [Permissions & Edge Cases](#permissions--edge-cases)

---

## Key Features

- **Media Picker**: Pick videos seamlessly from either system Gallery or File Manager with full permission management (`PermissionService`).
- **Precise Video Trimming**: Interactive visual dual-handle timeline scrubber with frame-accurate preview synchronization and duration validation (minimum 1 second).
- **Stepped 90° Rotation**: Rotate video clockwise (`+90°`) or counter-clockwise (`-90°`) with instantaneous preview orientation and wrap-around state (`0° → 90° → 180° → 270°`).
- **Color Filters**: Hardware-simulated live preview and FFmpeg `eq` filter curves for Brightness (`-0.5` to `+0.5`) and Contrast (`0.5` to `1.5`).
- **Audio Control**: Instant preview audio muting and FFmpeg `-an` track stripping for exported clips.
- **Background Async Processing**: Non-blocking local export via `ffmpeg_kit_flutter_new` with real-time encoding progress (`0% → 100%`), session cancellation support, and prevention of concurrent exports.
- **Creations Gallery**: Dynamic responsive grid displaying all saved creations with custom thumbnails, formatted duration (`mm:ss`), file size (`MB`), creation date, and interactive actions (In-App Play, System Share Sheet, Delete confirmation).
- **In-App Video Player**: Full-featured player (`PlayerScreen`) with play/pause, interactive seek scrubber, and real-time playback position.

---

## Architecture Overview

Editiz strictly adheres to Clean Flutter Architecture and the BLoC pattern:

```mermaid
graph TD
    subgraph UI ["Presentation Layer (Widgets & Screens)"]
        A[HomeScreen]
        B[EditorScreen]
        C[CreationsScreen]
        D[PlayerScreen]
    end

    subgraph Cubits ["State Management Layer (BLoC / Cubits)"]
        E[HomeCubit]
        F[EditorCubit]
        G[ExportCubit]
        H[CreationsCubit]
        I[TipsCubit]
    end

    subgraph Repositories ["Repository Layer"]
        J[CreationsRepository]
        K[TipsRepository]
    end

    subgraph Services ["Data & Service Layer"]
        L[FileService]
        M[VideoService (FFmpeg)]
        N[PermissionService]
        O[CreationsLocalSource (Hive)]
        P[TipsRemoteSource (Dio)]
    end

    A --> E
    A --> I
    B --> F
    B --> G
    C --> H
    
    E --> L
    E --> N
    F -.-> B
    G --> M
    G --> J
    H --> J
    I --> K
    
    J --> O
    J --> L
    K --> P
```

### The 4 Layers Explained:
1. **Presentation Layer (`lib/screens/`, `lib/widgets/`)**:
   Contains pure UI widgets. Listens to Cubits via `BlocBuilder`, `BlocConsumer`, and `BlocListener`. Contains no business logic or file/database calls.
2. **State Management (`lib/cubits/`)**:
   - `HomeCubit`: Manages media picker permissions and video file selection.
   - `EditorCubit`: Controls edit state (trim start/end, quarterTurns, brightness, contrast, audio mute, and video controller sync).
   - `ExportCubit`: Coordinates FFmpeg session creation, progress polling, cancellation, and creation persistence.
   - `CreationsCubit`: Manages the collection of exported creations (load, delete, share).
   - `TipsCubit`: Fetches editing tips via the repository layer with loading/success/error/retry states.
3. **Repository Layer (`lib/repositories/`)**:
   Acts as the single source of truth, abstracting data sources from Cubits:
   - `CreationsRepository`: Coordinates saving, fetching, and deleting video files and their Hive metadata.
   - `TipsRepository`: Fetches tip data from remote sources with fallback defaults.
4. **Data & Service Layer (`lib/data/`)**:
   - `VideoService`: Encapsulates FFmpeg command synthesis, execution, session tracking, and thumbnail extraction.
   - `FileService`: Manages file picking, file system directories (`/VideoEdits`), unique filename generation (`clip_<timestamp>.mp4`), and file size calculation.
   - `CreationsLocalSource`: Low-level Hive box operations using string-keyed JSON map records.
   - `TipsRemoteSource`: Network communication via `Dio` with connection timeouts and error handling.
   - `PermissionService`: Wraps `permission_handler` to query and request video/storage permissions.

---

## Local Video Processing (FFmpeg)

All rendering operations are executed locally on-device without remote servers:

### 1. Command Synthesis (`VideoService.buildFFmpegCommand`)
The app converts the user's `EditState` into an optimized FFmpeg pipeline:
- **Fast Seeking & Trimming**: `-ss <start>` placed before input for rapid keyframe seeking, followed by `-t <duration>`.
- **90° Stepped Rotation**: Uses FFmpeg's hardware-compatible `transpose` filter:
  - 90° Clockwise: `transpose=1`
  - 180° Flip: `transpose=1,transpose=1`
  - 270° Clockwise (90° Counter-Clockwise): `transpose=2`
- **Brightness & Contrast**: Evaluated through FFmpeg's `eq` filter: `eq=brightness=<val>:contrast=<val>`.
- **Audio Muting**: `-an` strips the audio stream entirely when muted.
- **Encoding Optimization**: `-c:v libx264 -preset ultrafast -crf 23 -pix_fmt yuv420p` ensures rapid on-device encoding and universal Android playback compatibility.

### 2. Asynchronous Execution & Progress Tracking
- Processing runs asynchronously via `FFmpegKit.executeAsync`.
- Live progress is computed using FFmpeg time-execution statistics relative to selected trim duration.
- Clean cancellation support: If cancelled, partial files are purged automatically from disk.

---

## Local Data Persistence (Hive)

Saved creations are persisted in a Hive key-value store (`creations_box`):

### Record Structure (`Creation` Model):
| Field | Type | Description |
|---|---|---|
| `id` | `int` | Unique millisecond timestamp identifier |
| `filePath` | `String` | Absolute path inside the app's internal `/VideoEdits` directory |
| `fileName` | `String` | Generated filename (`clip_<id>.mp4`) |
| `thumbnailPath` | `String` | Absolute path to extracted JPEG thumbnail |
| `durationMs` | `int` | Trimmed video duration in milliseconds |
| `sizeBytes` | `int` | File size on disk in bytes |
| `createdAt` | `DateTime` | ISO-8601 creation timestamp |
| `edits` | `Map<String, dynamic>` | Snapshot of applied edits (quarterTurns, brightness, contrast, isMuted) |

*Storage resilience:* Stored records persist across app restarts, background/foreground transitions, and device reboots.

---

## API Integration (Dio)

To demonstrate networking architecture alongside local video processing:
- `TipsRemoteSource` utilizes **Dio** with configured connection timeouts (5 seconds).
- Consumes remote endpoint data to display creative video editing tips on `HomeScreen`.
- Handles full lifecycle: `TipsLoading` → `TipsLoaded` / `TipsFailure` with an interactive **"Retry"** button when offline or on failure.
- Editing and local exports operate completely independently of network availability.

---

## Getting Started & Setup

### Prerequisites
- Flutter SDK `^3.10.0` or higher
- Android SDK (minSdkVersion 24, targetSdkVersion 34)
- Physical Android device or emulator with hardware acceleration

### Running the App
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on connected Android device
flutter run -d <device-id>
```

---

## Permissions & Edge Cases Handled

1. **Permissions**: Android 13+ `READ_MEDIA_VIDEO` and legacy `READ_EXTERNAL_STORAGE` are dynamically requested. If permanently denied, users are prompted with a direct button to open system App Settings.
2. **Concurrent Export Prevention**: `ExportCubit` enforces `_isExporting` lock to reject duplicate save taps while encoding is active.
3. **Empty & Error States**: Expressive empty states for both recent edits and creations gallery, with clear error banners and user-friendly error messages.
4. **Clean Disposal**: All video controllers, animation controllers, and stream subscriptions are safely disposed to prevent memory leaks.
