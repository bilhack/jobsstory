import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';

/// Initializes the app with Firebase when options are configured.
/// Runs before runApp and keeps the splash until ready.
class AppBootstrap {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) {
      // No Firebase project linked yet: app still boots in preview mode.
      return;
    }
    await Firebase.initializeApp(options: options);
  }
}