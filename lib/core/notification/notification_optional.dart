import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vibe_chat/core/route/page_route.dart';
import 'package:vibe_chat/core/services/call_ringtone_service.dart';

import '../../features/chat/presentation/controller/chat_controller.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Top-level background handler – MUST be a top-level function (not a method).
/// Firebase calls this when the app is terminated or in the background.
/// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised in main() before this is registered,
  // so no need to call Firebase.initializeApp() here again.
  printMessage('🔔 [BG] Notification received: ${message.messageId}');
}

void printMessage(String text) {
  log(text);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// FirebaseNotificationService
/// Handles every state: foreground, background-tap, and terminated-tap.
/// ─────────────────────────────────────────────────────────────────────────────
class FirebaseNotificationService {
  FirebaseNotificationService._();
  static final instance = FirebaseNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Android notification channel used for high-priority alerts.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'optiko_vendor_high_importance_channel',
    'Optiko Vendor High Tear Channel',
    description:
    'This channel is used for important Optiko Vendor notifications.',
    importance: Importance.max,
    playSound: true,
  );

  /// Android notification channel for video calls with ringing sound
  static const AndroidNotificationChannel _callChannel = AndroidNotificationChannel(
    'vibe_chat_call_channel_v3',
    'Incoming Video Calls',
    description: 'This channel is used for incoming video calls with ringing sound.',
    importance: Importance.max,
    playSound: true,
    audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
    enableVibration: true,
  );

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    printMessage('🔔 Notification permission: ${settings.authorizationStatus}');

    const androidInit = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // 3️⃣ Create the high-importance Android channels
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.createNotificationChannel(_callChannel);

    // 4️⃣ iOS foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5️⃣ Foreground messages → show local notification manually (Android)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6️⃣ Background → app opened via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 7️⃣ Terminated → app launched via notification tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _routeFromMessage(initialMessage);
      });
    }

    printMessage('✅ FirebaseNotificationService initialised');
  }

  // ─── Foreground ─────────────────────────────────────────────────────────────

  Future<void> _handleForegroundMessage(
      RemoteMessage message,
      ) async {
    printMessage('🔔 [FG] ${message.notification?.title}');

    final notification = message.notification;

    if (notification == null || kIsWeb) return;

    String? imageUrl = message.data["senderImage"];

    AndroidNotificationDetails androidDetails;
    final senderUid = message.data["senderUid"];

    // Agar user usi chat me hai to notification mat dikhao
    if (ChatState.currentChatUserId == senderUid && message.data["type"] != "call") {
      log("Same chat open hai, notification skip");
      return;
    }

    final isCall = message.data["type"] == "call" || (notification.title?.contains("Call") ?? false);
    if (isCall) {
      CallRingtoneService.startRingtone();
    }

    final activeChannel = isCall ? _callChannel : _channel;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final imagePath = await _downloadImage(imageUrl);

      if (imagePath != null) {
        androidDetails = AndroidNotificationDetails(
          activeChannel.id,
          activeChannel.name,
          channelDescription: activeChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          audioAttributesUsage: isCall ? AudioAttributesUsage.notificationRingtone : AudioAttributesUsage.notification,
          largeIcon: FilePathAndroidBitmap(imagePath),
          styleInformation: BigPictureStyleInformation(
            FilePathAndroidBitmap(imagePath),
            largeIcon: FilePathAndroidBitmap(imagePath),
          ),
        );
      } else {
        androidDetails = AndroidNotificationDetails(
          activeChannel.id,
          activeChannel.name,
          channelDescription: activeChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.max,
          audioAttributesUsage: isCall ? AudioAttributesUsage.notificationRingtone : AudioAttributesUsage.notification,
        );
      }
    } else {
      androidDetails = AndroidNotificationDetails(
        activeChannel.id,
        activeChannel.name,
        channelDescription: activeChannel.description,
        icon: '@mipmap/ic_launcher',
        importance: Importance.max,
        priority: Priority.max,
        audioAttributesUsage: isCall ? AudioAttributesUsage.notificationRingtone : AudioAttributesUsage.notification,
      );
    }

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ─── Background tap ──────────────────────────────────────────────────────────

  void _handleMessageOpenedApp(RemoteMessage message) {
    printMessage('🔔 [BG-tap] ${message.notification?.title}');
    _routeFromMessage(message);
  }

  // ─── Local notification tap ───────────────────────────────────────────────────

  void _onLocalNotificationTap(NotificationResponse response) {
    CallRingtoneService.stopRingtone();
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _routeFromData(data);
    } catch (_) {}
  }

  // ─── Routing logic ────────────────────────────────────────────────────────────

  void _routeFromMessage(RemoteMessage message) {
    _routeFromData(message.data);
  }

  /// Adjust the routing map below to match your backend's `type` payloads.
  void _routeFromData(Map<String, dynamic> data) {
    final senderUid = data["senderUid"];
    final senderName = data["senderName"];
    final senderPhoto = data["senderPhoto"];
    Get.toNamed(
      AppRoute.chat,
      arguments: {
        "receiverUid": senderUid,
        "receiverName": senderName,
        "receiverPhoto": senderPhoto,
      },
    );
  }
  Future<String?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();

        final file = File(
          '${directory.path}/sender_profile.jpg',
        );

        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      }
    } catch (e) {
      log("Image Download Error: $e");
    }

    return null;
  }

  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      log("Error clearing notifications: $e");
    }
  }
}