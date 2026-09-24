import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Registers/unregisters the device's FCM token on the user's profile
/// under `users/{uid}/fcmTokens`. Cloud Functions (see `functions/`) send
/// push notifications for new applications and status changes.
abstract class NotificationService {
  Future<void> register(String uid);
  Future<void> unregister(String uid);
}

/// Production implementation backed by Firebase Cloud Messaging.
class FirebaseNotificationService implements NotificationService {
  @override
  Future<void> register(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmTokens': FieldValue.arrayUnion([token])}, SetOptions(merge: true));
    } catch (_) {
      // Notifications are best-effort — never crash the app over a token.
    }
  }

  @override
  Future<void> unregister(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmTokens': FieldValue.arrayRemove([token])}, SetOptions(merge: true));
    } catch (_) {
      // Best-effort cleanup.
    }
  }
}