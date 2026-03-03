import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    try {
      final managePermission = await Permission.manageExternalStorage.request();
      if (managePermission.isGranted) return true;

      final storagePermission = await Permission.storage.request();
      return storagePermission.isGranted;
    } catch (e) {
      return false;
    }
  }
}
