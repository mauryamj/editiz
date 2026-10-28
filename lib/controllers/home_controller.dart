import 'package:flutter/foundation.dart';
import 'package:editiz/data/file_service.dart';
import 'package:editiz/data/permission_service.dart';
import 'package:editiz/models/app_exception.dart';

/// Simple controller for picking videos on Home screen.
class HomeController extends ChangeNotifier {
  final FileService fileService;
  final PermissionService permissionService;

  bool isPicking = false;
  String? pickedVideoPath;
  bool permissionDenied = false;
  bool isPermanentlyDenied = false;
  String? errorMessage;

  HomeController({
    required this.fileService,
    required this.permissionService,
  });

  /// Pick video from gallery
  Future<void> pickFromGallery() async {
    isPicking = true;
    _clearErrors();
    notifyListeners();

    try {
      await permissionService.checkAndRequestVideoPermission();
      final path = await fileService.pickVideoFromGallery();
      if (path != null) {
        pickedVideoPath = path;
      }
    } on PermissionException catch (e) {
      permissionDenied = true;
      isPermanentlyDenied = e.permanent;
    } on AppException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Failed to pick video.';
    } finally {
      isPicking = false;
      notifyListeners();
    }
  }

  /// Pick video from file system
  Future<void> pickFromFileSystem() async {
    isPicking = true;
    _clearErrors();
    notifyListeners();

    try {
      await permissionService.checkAndRequestVideoPermission();
      final path = await fileService.pickVideoFromFileSystem();
      if (path != null) {
        pickedVideoPath = path;
      }
    } on PermissionException catch (e) {
      permissionDenied = true;
      isPermanentlyDenied = e.permanent;
    } on AppException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Failed to pick video file.';
    } finally {
      isPicking = false;
      notifyListeners();
    }
  }

  /// Open app settings
  Future<void> openSettings() async {
    await permissionService.openSettings();
    reset();
  }

  /// Clears picked path once opened in editor
  void clearPickedPath() {
    pickedVideoPath = null;
    notifyListeners();
  }

  /// Resets state
  void reset() {
    isPicking = false;
    pickedVideoPath = null;
    permissionDenied = false;
    isPermanentlyDenied = false;
    errorMessage = null;
    notifyListeners();
  }

  void _clearErrors() {
    permissionDenied = false;
    isPermanentlyDenied = false;
    errorMessage = null;
    pickedVideoPath = null;
  }
}
