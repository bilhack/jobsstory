import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Abstraction over picking media — lets widget tests avoid platform channels.
abstract class MediaPicker {
  Future<File?> pickVideo();
  Future<File?> pickImage();
}

class ImagePickerMediaPicker implements MediaPicker {
  ImagePickerMediaPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<File?> pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    return picked == null ? null : File(picked.path);
  }

  @override
  Future<File?> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    return picked == null ? null : File(picked.path);
  }
}