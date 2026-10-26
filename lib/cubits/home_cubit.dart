import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/data/permission_service.dart';
import 'package:editiz/models/app_exception.dart';

// Class: base state for HomeCubit.
abstract class HomeState {
  const HomeState();
}

// Class: initial idle state.
class HomeIdle extends HomeState {
  const HomeIdle();
}

// Class: state when picking is in progress.
class HomePicking extends HomeState {
  const HomePicking();
}

// Class: state when video path was successfully selected.
class HomePicked extends HomeState {
  // Field: file path to the selected video.
  final String path;

  // Constructor: requires video path.
  const HomePicked(this.path);
}

// Class: state when video access permissions are denied.
class HomePermissionDenied extends HomeState {
  // Field: true if permanently denied.
  final bool permanent;

  // Constructor: requires permanent flag.
  const HomePermissionDenied({required this.permanent});
}

// Class: state when an error occurs.
class HomeFailure extends HomeState {
  // Field: user-friendly message.
  final String message;

  // Constructor: requires error message.
  const HomeFailure(this.message);
}

// Class: cubit controlling video selection, permissions, and picker workflows.
class HomeCubit extends Cubit<HomeState> {
  // Field: file service for picking and format checking.
  final FileService _fileService;

  // Field: permission service.
  final PermissionService _permissionService;

  // Constructor: initializes in HomeIdle state.
  HomeCubit({
    required this._fileService,
    required this._permissionService,
  })  : super(const HomeIdle());

  // Method: picks a video from the system gallery.
  Future<void> pickFromGallery() async {
    emit(const HomePicking());
    try {
      await _permissionService.checkAndRequestVideoPermission();
      final path = await _fileService.pickVideoFromGallery();
      if (isClosed) return;
      if (path != null) {
        emit(HomePicked(path));
      } else {
        emit(const HomeIdle());
      }
    } on PermissionException catch (e) {
      if (!isClosed) emit(HomePermissionDenied(permanent: e.permanent));
    } on AppException catch (e) {
      if (!isClosed) emit(HomeFailure(e.message));
    } catch (_) {
      if (!isClosed) emit(const HomeFailure('Failed to pick video.'));
    }
  }

  // Method: picks a video from file system explorer.
  Future<void> pickFromFileSystem() async {
    emit(const HomePicking());
    try {
      await _permissionService.checkAndRequestVideoPermission();
      final path = await _fileService.pickVideoFromFileSystem();
      if (isClosed) return;
      if (path != null) {
        emit(HomePicked(path));
      } else {
        emit(const HomeIdle());
      }
    } on PermissionException catch (e) {
      if (!isClosed) emit(HomePermissionDenied(permanent: e.permanent));
    } on AppException catch (e) {
      if (!isClosed) emit(HomeFailure(e.message));
    } catch (_) {
      if (!isClosed) emit(const HomeFailure('Failed to pick video file.'));
    }
  }

  // Method: opens system settings if permission was permanently denied.
  Future<void> openSettings() async {
    await _permissionService.openSettings();
    emit(const HomeIdle());
  }

  // Method: resets state to idle.
  void reset() {
    emit(const HomeIdle());
  }
}
