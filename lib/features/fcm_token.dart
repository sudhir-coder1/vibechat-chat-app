import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationServices {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> fcmToken() async {
    await _messaging.requestPermission();
    return await _messaging.getToken();
  }
}