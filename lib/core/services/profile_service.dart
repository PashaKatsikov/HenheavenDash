import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the chef's profile photo for the white-game part.
///
/// Persists the chosen image path across launches and tracks whether the user
/// has already allowed camera access through this feature. The gray-flow
/// [WebCounter] reads [hasCameraPermission] before granting its own in-WebView
/// camera requests: the system-level NSCameraUsageDescription string is
/// justified precisely because this feature can use the camera.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const _kPhotoPath = 'chef_photo_path';
  static const _kCameraGranted = 'chef_camera_granted';

  static const _kMaxDimension = 512.0;
  static const _kQuality = 85;

  late SharedPreferences _prefs;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  /// Absolute path of the currently saved profile photo, or null if none.
  String? get photoPath => _prefs.getString(_kPhotoPath);

  /// Returns the photo [File] only if it exists on disk; null otherwise.
  ///
  /// The file may be absent even when [photoPath] is set if the OS purged the
  /// temporary directory between launches — callers should treat null as "no
  /// photo" and show the placeholder instead.
  File? get photoFile {
    final path = photoPath;
    if (path == null) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  /// True once the user has successfully taken a photo with the camera
  /// (not just gallery) through the chef-profile picker.
  ///
  /// The gray-flow WebView gates its own camera permission requests on this
  /// flag so the NSCameraUsageDescription usage is always user-initiated from
  /// within the white part first.
  bool get hasCameraPermission => _prefs.getBool(_kCameraGranted) ?? false;

  /// Opens the system picker and saves the result.
  ///
  /// Returns the picked [File], or null if the user cancelled.
  /// When [fromCamera] is true and a photo is returned, sets
  /// [hasCameraPermission] to true permanently.
  Future<File?> pickPhoto({required bool fromCamera}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: _kQuality,
      maxWidth: _kMaxDimension,
      maxHeight: _kMaxDimension,
    );
    if (picked == null) return null;

    await _prefs.setString(_kPhotoPath, picked.path);
    if (fromCamera) {
      await _prefs.setBool(_kCameraGranted, true);
    }
    return File(picked.path);
  }

  /// Removes the saved profile photo. [hasCameraPermission] is unchanged.
  Future<void> removePhoto() async {
    await _prefs.remove(_kPhotoPath);
  }
}
