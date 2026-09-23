import 'package:firebase_core/firebase_core.dart';

/// Placeholder Firebase options.
///
/// IMPORTANT: run `flutterfire configure` from the project root after
/// creating your Firebase project. It will regenerate this file with the
/// real Android/iOS app ids. Until then the app boots without Firebase.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform => null;

  static FirebaseOptions get android => throw UnimplementedError(
        'Run `flutterfire configure` to generate Firebase options.',
      );

  static FirebaseOptions get ios => throw UnimplementedError(
        'Run `flutterfire configure` to generate Firebase options.',
      );
}