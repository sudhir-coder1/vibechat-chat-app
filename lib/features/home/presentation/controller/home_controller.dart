import 'dart:async';
import 'dart:developer';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import '../../../../core/route/page_route.dart';
import '../../../custom_Preferences/preferences.dart';
import '../../../encryption.dart';
import '../../../call/presentation/screens/call_page.dart';
import '../../../../core/services/call_ringtone_service.dart';
import '../data/datamodel.dart';

class HomeController extends GetxController {
  final users = <UserData>[].obs;
  final lastMessages = <String, String>{}.obs;
  final onlineStatus = <String, bool>{}.obs;
  final unreadCounts = <String, int>{}.obs;
  final pendingRequestsCount = 0.obs;


  void shorting(){
    users.sort(
        (a,b)=>b.lastMessageTime! .compareTo(a.lastMessageTime as num),
    );
  }

  HomeController() {
    log("HOME CONTROLLER CONSTRUCTOR");
  }
  final isLoading = true.obs;

  Future<void> getChatUsers() async {
    isLoading.value = true;
    try {
      String? currentUid = await getPreferences("UID");

      FirebaseDatabase.instance
          .ref("user/$currentUid/lastMessage")
          .onValue
          .listen((event) async {
        log("Listener Triggered");

        List<UserData> tempUsers = [];
        Map<String, String> tempLastMsg = {};

        if (event.snapshot.exists) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          for (var entry in data.entries) {
            final msgData = Map<String, dynamic>.from(entry.value);

            String receiverUid = msgData["receiverUid"] ?? "";
            if (receiverUid == currentUid) continue;

            String rawMsg = msgData["message"] ?? "";
            String lastMsg = "";

            if (rawMsg.isNotEmpty) {
              try {
                lastMsg = CustomEncryption.decrypt(rawMsg);
              } catch (e) {
                log("Last message decryption error: $e");
                lastMsg = rawMsg;
              }
            }

            int? lastTime = msgData["time"];
            int unread = msgData["unreadCount"] ?? 0;

            tempLastMsg[receiverUid] = lastMsg;
            unreadCounts[receiverUid] = unread;

            final userSnapshot = await FirebaseDatabase.instance
                .ref("user/$receiverUid")
                .get();

            if (userSnapshot.exists) {
              final userData = Map<String, dynamic>.from(userSnapshot.value as Map);

              final bool isOnline = userData["isOnline"] ?? false;

              tempUsers.add(
                UserData(
                  uid: receiverUid,
                  name: userData["name"] ?? "",
                  email: userData["email"] ?? "",
                  photo: userData["photo"] ?? "",
                  fcm: userData["fcm"] ?? "",
                  username: userData["username"] ?? "",
                  lastMessage: lastMsg,
                  lastMessageTime: lastTime,
                  isOnline: isOnline,
                  unreadCount: unread,
                ),
              );

              tempUsers.sort((a, b) =>
                  (b.lastMessageTime ?? 0).compareTo(a.lastMessageTime ?? 0));

              onlineStatus[receiverUid] = isOnline;
              _startOnlineStatusListener(receiverUid);
            }
          }
        }

        users.value = tempUsers;
        lastMessages.value = tempLastMsg;
        isLoading.value = false; // Data aa gayi, ab skeleton hatao
      });
      
      // Also listen to pending chat requests
      FirebaseDatabase.instance
          .ref("chat_requests/$currentUid/received")
          .onValue
          .listen((event) {
        int count = 0;
        if (event.snapshot.exists) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          for (var value in data.values) {
            final request = Map<String, dynamic>.from(value);
            if (request["status"] == "pending") {
              count++;
            }
          }
        }
        pendingRequestsCount.value = count;
      });
    } catch (e) {
      log("getChatUsers error: $e");
      isLoading.value = false;
    }
  }


  Future<void> resetUnreadCount(String receiverUid) async {
    String? currentUid = await getPreferences("UID");

    if (currentUid != null && currentUid.isNotEmpty) {
      List<String> ids = [currentUid, receiverUid];
      ids.sort();
      String roomId = ids.join("_");

      await FirebaseDatabase.instance
          .ref("user/$currentUid/lastMessage/$roomId")
          .update({"unreadCount": 0});
    }

    unreadCounts[receiverUid] = 0;

    final index = users.indexWhere((u) => u.uid == receiverUid);
    if (index != -1) {
      users[index].unreadCount = 0;
      users.refresh();
    }
  }
  void _startOnlineStatusListener(String uid) {

    FirebaseDatabase.instance.ref("user/$uid/isOnline").onValue.listen((event) {
      if (event.snapshot.exists) {
        final bool status = (event.snapshot.value == true);
        onlineStatus[uid] = status;

        final index = users.indexWhere((user) => user.uid == uid);
        if (index != -1) {
          users[index].isOnline = status;
          users.refresh();
        }
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    getChatUsers();
    _setupCurrentUserPresence();
    _listenForSingleDeviceLogin();
    _listenUserStatus();
    _listenGlobalIncomingCalls();
    shorting();
  }

  Future<void> _setupCurrentUserPresence() async {
    String? uid = await getPreferences("UID");
    if (uid == null) return;

    final userStatusRef = FirebaseDatabase.instance.ref("user/$uid");
    final connectedRef = FirebaseDatabase.instance.ref(".info/connected");

    connectedRef.onValue.listen((event) async {
      final connected = event.snapshot.value as bool? ?? false;
      if (!connected) return;

      await userStatusRef.onDisconnect().update({
        "isOnline": false,
        "lastSeen": ServerValue.timestamp,
      });

      await userStatusRef.update({
        "isOnline": true,
        "lastSeen": ServerValue.timestamp,
      });
    });
  }

  Future<void> _listenForSingleDeviceLogin() async {
    String? uid = await getPreferences("UID");
    if (uid == null) return;

    FirebaseDatabase.instance.ref("user/$uid/fcm").onValue.listen((event) async {
      try {
        final dbToken = event.snapshot.value?.toString();
        final currentToken = await FirebaseMessaging.instance.getToken();

        if (dbToken == null || currentToken == null) return;

        if (dbToken != currentToken) {
          await removePreferences("UID");
          Get.offAllNamed(AppRoute.login);
          Get.snackbar("Logged Out", "Account logged in on another device");
        }
      } catch (e) {
        log("FCM Listener Error: $e");
      }
    });
  }

  void _listenUserStatus() async {
    String? uid = await getPreferences("UID");
    if (uid == null) return;

    FirebaseDatabase.instance.ref("user/$uid").onValue.listen((event) async {
      if (!event.snapshot.exists) {
        await removePreferences("UID");
        Get.offAllNamed(AppRoute.login);
        Get.snackbar("Account Removed", "Your account no longer exists.");
      }
    });
  }
  StreamSubscription<DatabaseEvent>? _incomingCallSub;

  void _listenGlobalIncomingCalls() async {
    String? uid = await getPreferences("UID");
    if (uid == null || uid.isEmpty) return;

    _incomingCallSub?.cancel();
    _incomingCallSub = FirebaseDatabase.instance
        .ref("user/$uid/incomingCall")
        .onValue
        .listen((event) {
      // Node delete ho gaya — dialog close karo
      if (!event.snapshot.exists) {
        CallRingtoneService.stopRingtone();
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final status = data["status"]?.toString();
      final roomId = data["roomId"]?.toString();

      // Caller ne call cut kiya — dialog close karo
      if (status == "ended" || status == null) {
        CallRingtoneService.stopRingtone();
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        return;
      }

      if (status == "calling" &&
          roomId != null &&
          !Get.currentRoute.contains("CallPage")) {
        CallRingtoneService.startRingtone();
        _showGlobalIncomingCallDialog(data);
      }
    });
  }

  void _showGlobalIncomingCallDialog(Map<String, dynamic> callData) {
    if (Get.isDialogOpen == true) return;
    final callerName = callData["callerName"] ?? "User";
    final callerPhoto = callData["callerPhoto"] as String?;
    final roomId = callData["roomId"] as String;

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF0F1744),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFF1A265A),
                backgroundImage:
                    (callerPhoto != null && callerPhoto.isNotEmpty)
                        ? NetworkImage(callerPhoto)
                        : null,
                child: (callerPhoto == null || callerPhoto.isEmpty)
                    ? const Icon(Icons.person, size: 35, color: Colors.white60)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Incoming Video Call...",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    label: const Text(
                      "Decline",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      CallRingtoneService.stopRingtone();
                      Get.back();
                      await FirebaseDatabase.instance
                          .ref("calls/$roomId/status")
                          .set("ended");
                      String? currentUid = await getPreferences("UID");
                      if (currentUid != null) {
                        await FirebaseDatabase.instance
                            .ref("user/$currentUid/incomingCall")
                            .remove();
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.videocam, color: Colors.white),
                    label: const Text(
                      "Accept",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      CallRingtoneService.stopRingtone();
                      Get.back();
                      String? currentUid = await getPreferences("UID");
                      if (currentUid != null) {
                        await FirebaseDatabase.instance
                            .ref("user/$currentUid/incomingCall")
                            .remove();
                      }
                      Get.to(
                        () => const CallPage(),
                        arguments: {
                          'roomId': roomId,
                          'receiverName': callerName,
                          'receiverPhoto': callerPhoto,
                          'isCaller': false,
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  final Map<String, StreamSubscription> _subscriptions = {};
  @override
  void onClose() {
    _incomingCallSub?.cancel();
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    super.onClose();
  }
}