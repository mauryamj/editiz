import 'package:permission_handler/permission_handler.dart';
import 'package:editiz/models/app_exception.dart';

// Class: service for checking and requesting video access permissions.
class PermissionService {
  // Method: requests video/storage permissions; throws PermissionException if denied.
  Future<bool> checkAndRequestVideoPermission() async {
    final videoStatus = await Permission.videos.status;
    final storageStatus = await Permission.storage.status;

    if (videoStatus.isGranted || storageStatus.isGranted) {
      return true;
    }

    final permissions = <Permission>[
      Permission.videos,
      Permission.storage,
    ];
    final statuses = await permissions.request();

    final isGranted = (statuses[Permission.videos]?.isGranted ?? false) ||
        (statuses[Permission.storage]?.isGranted ?? false);

    if (isGranted) {
      return true;
    }

    final isPermanentlyDenied =
        (statuses[Permission.videos]?.isPermanentlyDenied ?? false) ||
            (statuses[Permission.storage]?.isPermanentlyDenied ?? false);

    throw PermissionException(
      message: 'Video access permission is needed to select and edit videos.',
      permanent: isPermanentlyDenied,
    );
  }

  // Method: opens system app settings page.
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
