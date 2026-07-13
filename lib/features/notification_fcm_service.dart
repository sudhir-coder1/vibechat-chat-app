import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMService {
  static const String projectId = "vibechat-44775";

  static Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    required String senderImage,
    required String senderUid,
    required String username,

  }) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/service_account.json',
      );

      final serviceAccount = ServiceAccountCredentials.fromJson(
        jsonDecode(jsonString),
      );

      final client = await clientViaServiceAccount(serviceAccount, [
        'https://www.googleapis.com/auth/firebase.messaging',
      ]);

      final accessToken = client.credentials.accessToken.data;

      final isCall = title.contains("Call");

      final payload = {
        "message": {
          "token": fcmToken,
          "notification": {
            "title": title,
            "body": body,
            "image": senderImage,
          },
          "android": {
            "priority": "high",
            "notification": {
              "channel_id": isCall ? "vibe_chat_call_channel_v3" : "optiko_vendor_high_importance_channel",
              "sound": "default",
              "image": senderImage,
            }
          },
          "data": {
            "type": isCall ? "call" : "chat",
            "senderUid": senderUid,
            "senderName": username,
            "senderPhoto": senderImage,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
          }
        }
      };

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(payload),
      );

      log(response.body);

      client.close();
    } catch (e) {
      log("FCM Error => $e");
    }
  }
}
