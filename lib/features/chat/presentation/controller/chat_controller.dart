import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart' hide Key;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import '../../../custom_Preferences/preferences.dart';
import '../../../encryption.dart';
import '../../../notification_fcm_service.dart';
import 'package:vibe_chat/core/notification/notification_optional.dart';
import 'package:vibe_chat/features/call/presentation/screens/call_page.dart';
import '../../../../core/services/call_ringtone_service.dart';
import '../data/date_model.dart';

class ChatState {
  static String? currentChatUserId;
}

class ChatController extends GetxController {
  final AudioPlayer player = AudioPlayer();

  bool isInitialLoad = true;

  String currentUid = "";
  RxString roomId = "".obs;

  Future<void> playMessageTone() async {
    await player.play(AssetSource('sounds/message.mp3'));
  }

  Future<void> playReceiveTone() async {
    await player.play(AssetSource('sounds/receive.mp3'));
  }

  RxBool isUserOnline = false.obs;
  RxString lastSeen = "".obs;

  late String receiverUid;
  late String receiverName;
  late String? receiverPhoto;
  late String receiverfcm;

  final messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  final isTyping = false.obs;
  final isUserTyping = false.obs;
  final isUploading = false.obs;
  final showScrollToBottom = false.obs;

  // Reply state
  final Rx<ReceiveDataModel?> replyingTo = Rx<ReceiveDataModel?>(null);
  void setReply(ReceiveDataModel? msg) => replyingTo.value = msg;
  void clearReply() => replyingTo.value = null;

  RxList<ReceiveDataModel> messages = <ReceiveDataModel>[].obs;

  // Highlighted message state
  final highlightedMessageKey = "".obs;
  
  // To keep track of GlobalKeys for each message item to ensure exact scrolling
  final Map<String, GlobalKey> itemKeys = {};

  // Stream Subscriptions
  StreamSubscription<DatabaseEvent>? _chatSub;
  StreamSubscription<DatabaseEvent>? _chatChangedSub;
  StreamSubscription<DatabaseEvent>? _chatRemovedSub;
  StreamSubscription<DatabaseEvent>? _newMessageSub;

  final userPhotos = <String, String>{}.obs;
  Timer? _typingTimer;

  @override
  Future<void> onInit() async {
    super.onInit();

    final args = Get.arguments;
    receiverUid = args["receiverUid"];
    receiverName = args["receiverName"];
    receiverPhoto = args["receiverPhoto"];
    receiverfcm = args["receiverfcm"] ?? "";

    await initChat();

    listenUserStatus(receiverUid);
    ChatState.currentChatUserId = receiverUid;

    setupScrollListener();

    messageController.addListener(() {
      final typing = messageController.text.trim().isNotEmpty;

      if (typing) {
        // User typing hai — Firebase update karo
        if (!isTyping.value) {
          isTyping.value = true;
          FirebaseDatabase.instance.ref("user/$currentUid").update({"isTyping": true});
        }
        // Timer reset karo — 2 second silence ke baad false
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          isTyping.value = false;
          FirebaseDatabase.instance.ref("user/$currentUid").update({"isTyping": false});
        });
      } else {
        // Text field empty — turant false
        _typingTimer?.cancel();
        isTyping.value = false;
        FirebaseDatabase.instance.ref("user/$currentUid").update({"isTyping": false});
      }
    });

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          animateToBottom();
        });
      }
    });
  }

  void setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.hasClients) {
        showScrollToBottom.value = scrollController.offset > 150;
      }
    });
  }

  Future<void> initChat() async {
    currentUid = await getPreferences("UID") ?? "";
    await createRoomId();
    receiveMessage();
    await markMessagesAsRead();
    listenTypingStatus();
    listenIncomingCalls();
  }

  Future<void> createRoomId() async {
    List<String> ids = [currentUid, receiverUid];
    ids.sort();
    roomId.value = ids.join("_");
    log("✅ Room ID Created: ${roomId.value}");
  }

  StreamSubscription<DatabaseEvent>? _callSub;

  void listenIncomingCalls() {
    if (roomId.value.isEmpty) return;
    _callSub = FirebaseDatabase.instance
        .ref("calls/${roomId.value}")
        .onValue
        .listen((event) {
      // Node delete ho gaya (caller ne call cut kiya before answer)
      if (!event.snapshot.exists) {
        CallRingtoneService.stopRingtone();
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final status = data["status"]?.toString();

      // Caller ne call cut kar di — dialog close karo
      if (status == "ended" || status == null) {
        CallRingtoneService.stopRingtone();
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        return;
      }

      if (status == "calling" &&
          data["offer"] != null &&
          !Get.currentRoute.contains("CallPage")) {
        CallRingtoneService.startRingtone();
        _showIncomingCallDialog();
      }
    });
  }

  void _showIncomingCallDialog() {
    if (Get.isDialogOpen == true) return;
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
                    (receiverPhoto != null && receiverPhoto!.isNotEmpty)
                        ? NetworkImage(receiverPhoto!)
                        : null,
                child: (receiverPhoto == null || receiverPhoto!.isEmpty)
                    ? const Icon(Icons.person, size: 35, color: Colors.white60)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                receiverName,
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
                    onPressed: () {
                      CallRingtoneService.stopRingtone();
                      Get.back();
                      FirebaseDatabase.instance
                          .ref("calls/${roomId.value}/status")
                          .set("ended");
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
                    onPressed: () {
                      CallRingtoneService.stopRingtone();
                      Get.back();
                      Get.to(
                        () => const CallPage(),
                        arguments: {
                          'roomId': roomId.value,
                          'receiverName': receiverName,
                          'receiverPhoto': receiverPhoto,
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

  // ================== ONLINE & TYPING ==================

  void listenUserStatus(String uid) {
    FirebaseDatabase.instance.ref("user/$uid").onValue.listen((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      isUserOnline.value = data["isOnline"] ?? false;

      if (data["lastSeen"] != null) {
        lastSeen.value = formatLastSeen(data["lastSeen"]);
      }
    });
  }

  String formatLastSeen(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "last seen today at ${date.hour > 12 ? date.hour - 12 : date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "last seen yesterday at ${date.hour > 12 ? date.hour - 12 : date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    } else {
      return "last seen ${date.day}/${date.month}/${date.year}";
    }
  }

  Future<void> listenTypingStatus() async {
    FirebaseDatabase.instance.ref("user/$receiverUid").onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        isUserTyping.value = data["isTyping"] ?? false;
      }
    });
  }

  final ImagePicker picker = ImagePicker();

  Future<void> sendImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 1080,
      );

      if (image == null) return;

      isUploading.value = true;

      File file = File(image.path);

      String imageUrl = await uploadToCloudinary(file) ?? "";

      if (imageUrl.isEmpty) return;

      await FirebaseDatabase.instance
          .ref("chats/${roomId.value}")
          .push()
          .set({
        "sender": currentUid,
        "receiver": receiverUid,
        "message": imageUrl,
        "type": "image",
        "isSee": false,
        "time": ServerValue.timestamp,
      });

      await lastMessage("📷 Photo");
      await incrementUnreadCount();

      String token = receiverfcm;
      if (token.isNotEmpty) {
        String? currentUser = await getPreferences("username");
        String? currentUserPhoto = await getPreferences("photo");
        String? currentUidPref = await getPreferences("UID");

        await FCMService.sendNotification(
          fcmToken: token,
          title: currentUser ?? "New Message",
          body: "📷 Photo",
          senderImage: currentUserPhoto ?? "",
          username: currentUser ?? "",
          senderUid: currentUidPref ?? currentUid,
        );
      } else {
        debugPrint("Receiver FCM token is empty!");
      }
    } catch (e) {
      debugPrint("Image upload error: $e");
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> deleteMessage(String key) async {
    try {
      await FirebaseDatabase.instance
          .ref("chats/${roomId.value}/$key")
          .remove();
      messages.removeWhere((msg) => msg.key == key);
      Get.snackbar(
        "Deleted",
        "Message deleted successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF101A4D),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  Future<void> downloadImage(String imageUrl) async {
    try {
      Get.snackbar(
        "Downloading...",
        "Saving image to Gallery",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF101A4D),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final fileName = "VibeChat_${DateTime.now().millisecondsSinceEpoch}";

        await Gal.putImageBytes(
          response.bodyBytes,
          name: fileName,
        );

        Get.snackbar(
          "Saved to Gallery! 📷",
          "Image saved to Phone Gallery",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00E676),
          colorText: Colors.black,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(12),
          borderRadius: 10,
        );
      } else {
        Get.snackbar("Failed", "Could not download image from server",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white);
      }
    } on GalException catch (e) {
      debugPrint("Gal permission error: ${e.type.message}");
      Get.snackbar(
        "Permission Denied",
        "Please allow Photos/Storage permission in App Settings",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint("Download image error: $e");
      Get.snackbar("Error", "Failed to save image: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }


  Future<String?> uploadToCloudinary(File file) async {
    const cloudName = "g5cnsxpk";
    const uploadPreset = "vibeimage";

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      ),
    );

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final data =
      jsonDecode(await response.stream.bytesToString());

      return data['secure_url'];
    }

    return null;
  }

  // ================== SEND MESSAGE ==================

  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    final encryptedMessage = CustomEncryption.encrypt(message);
    final reply = replyingTo.value;
    clearReply();
    messageController.clear();

    final Map<String, dynamic> payload = {
      "sender": currentUid,
      "receiver": receiverUid,
      "message": encryptedMessage,
      "isSee": false,
      "type": "text",
      "time": ServerValue.timestamp,
    };

    if (reply != null) {
      payload["replyMessage"] = reply.type == "text"
          ? CustomEncryption.encrypt(reply.message)
          : reply.message;
      payload["replyTo"] = reply.sender;
      payload["replyType"] = reply.type;
      payload["replyKey"] = reply.key;
    }

    await FirebaseDatabase.instance.ref("chats/${roomId.value}").push().set(payload);
    await lastMessage(encryptedMessage);
    await incrementUnreadCount();
    if (!isInitialLoad) playMessageTone();
  }

  /// Call end hone ke baad call ka record chat mein save karo
  Future<void> sendCallLog({
    required bool isCaller,
    required bool wasConnected,
    required int durationSeconds,
  }) async {
    if (roomId.value.isEmpty) return;
    try {
      String label;
      String durStr = '';
      if (!wasConnected) {
        label = isCaller ? '📵 No Answer' : '📵 Missed Call';
      } else {
        final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
        final s = (durationSeconds % 60).toString().padLeft(2, '0');
        durStr = '$m:$s';
        label = '📹 Video Call';
      }

      await FirebaseDatabase.instance.ref("chats/${roomId.value}").push().set({
        "sender": currentUid,
        "receiver": receiverUid,
        "message": label,
        "type": "call",
        "isSee": false,
        "time": ServerValue.timestamp,
        if (durStr.isNotEmpty) "duration": durStr,
      });
    } catch (e) {
      debugPrint("sendCallLog error: $e");
    }
  }

  Future<void> receiveMessage() async {
    await _chatSub?.cancel();
    await _chatChangedSub?.cancel();
    await _chatRemovedSub?.cancel();

    messages.clear();
    isInitialLoad = true;

    _chatSub = FirebaseDatabase.instance
        .ref("chats/${roomId.value}")
        .onChildAdded
        .listen((event) async {
      final value = event.snapshot.value;

      if (value == null || value is! Map) return;

      final msg = Map<String, dynamic>.from(value);

      String type = msg["type"]?.toString() ?? "text";

      String message;

      if (type == "image") {
        message = msg["message"]?.toString() ?? "";
      } else {
        try {
          message = CustomEncryption.decrypt(
            msg["message"]?.toString() ?? "",
          );
        } catch (e) {
          message = msg["message"]?.toString() ?? "";
        }
      }

      // Decrypt replyMessage if it was a text
      String? replyMsg = msg["replyMessage"]?.toString();
      final String? replyType = msg["replyType"]?.toString();
      final String? replyKey = msg["replyKey"]?.toString();
      if (replyMsg != null && replyType == 'text') {
        try { replyMsg = CustomEncryption.decrypt(replyMsg); } catch (_) {}
      }

      final data = ReceiveDataModel(
        key: event.snapshot.key ?? "",
        message: message,
        sender: msg["sender"]?.toString() ?? "",
        receiver: msg["receiver"]?.toString() ?? "",
        time: (msg["time"] ?? 0).toString(),
        isSee: msg["isSee"] == true,
        type: type,
        duration: msg["duration"]?.toString(),
        replyMessage: replyMsg,
        replyTo: msg["replyTo"]?.toString(),
        replyType: replyType,
        replyKey: replyKey,
      );

      messages.add(data);

      if (!isInitialLoad && data.sender != currentUid) {
        playReceiveTone();
        await markMessagesAsRead();
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        animateToBottom();
      });
    });

    _chatChangedSub = FirebaseDatabase.instance
        .ref("chats/${roomId.value}")
        .onChildChanged
        .listen((event) {
      final value = event.snapshot.value;

      if (value == null || value is! Map) return;

      final msg = Map<String, dynamic>.from(value);

      final changedKey = event.snapshot.key ?? "";

      final index = messages.indexWhere(
            (m) => m.key == changedKey,
      );

      if (index == -1) return;

      String type = msg["type"]?.toString() ?? "text";

      String message;

      if (type == "image") {
        message = msg["message"]?.toString() ?? "";
      } else {
        try {
          message = CustomEncryption.decrypt(
            msg["message"]?.toString() ?? "",
          );
        } catch (e) {
          message = msg["message"]?.toString() ?? "";
        }
      }

      // Decrypt replyMessage if text
      String? replyMsg2 = msg["replyMessage"]?.toString();
      final String? replyType2 = msg["replyType"]?.toString();
      final String? replyKey2 = msg["replyKey"]?.toString();
      if (replyMsg2 != null && replyType2 == 'text') {
        try { replyMsg2 = CustomEncryption.decrypt(replyMsg2); } catch (_) {}
      }

      messages[index] = ReceiveDataModel(
        key: changedKey,
        message: message,
        sender: msg["sender"]?.toString() ?? "",
        receiver: msg["receiver"]?.toString() ?? "",
        time: (msg["time"] ?? 0).toString(),
        isSee: msg["isSee"] == true,
        type: type,
        duration: msg["duration"]?.toString(),
        replyMessage: replyMsg2,
        replyTo: msg["replyTo"]?.toString(),
        replyType: replyType2,
        replyKey: replyKey2,
      );

      messages.refresh();
    });

    _chatRemovedSub = FirebaseDatabase.instance
        .ref("chats/${roomId.value}")
        .onChildRemoved
        .listen((event) {
      final removedKey = event.snapshot.key ?? "";
      if (removedKey.isNotEmpty) {
        messages.removeWhere((m) => m.key == removedKey);
      }
    });

    await markMessagesAsRead();

    Future.delayed(const Duration(seconds: 1), () {
      isInitialLoad = false;
    });
  }

  Future<void> lastMessage(String message) async {

    final timestamp = ServerValue.timestamp;

    await FirebaseDatabase.instance
        .ref("user/$currentUid/lastMessage/${roomId.value}")
        .update({
          "message": message,
          "receiverUid": receiverUid,
          "time": timestamp,
        });

    await FirebaseDatabase.instance
        .ref("user/$receiverUid/lastMessage/${roomId.value}")
        .update({
          "message": message,
          "receiverUid": currentUid,
          "time": timestamp,
        });
  }

  void animateToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        if (jump) {
          scrollController.jumpTo(0.0);
        } else {
          scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void scrollToMessage(String key) {
    if (!scrollController.hasClients) return;
    
    // Highlight the message for 3 seconds
    highlightedMessageKey.value = key;
    Future.delayed(const Duration(seconds: 3), () {
      if (highlightedMessageKey.value == key) {
        highlightedMessageKey.value = "";
      }
    });

    final targetContext = itemKeys[key]?.currentContext;
    
    if (targetContext != null) {
      // If the item is currently rendered in the list, scroll to it exactly
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.5, // Center the item vertically
      );
    } else {
      // If the item is off-screen (not rendered), do an approximate scroll
      // Find index of the message in the list
      final index = messages.indexWhere((m) => m.key == key);
      if (index != -1) {
        // The messages list has oldest at 0, newest at length - 1.
        // But the ListView has reverse: true, meaning offset 0 is newest.
        // So the number of items from the bottom is (messages.length - 1 - index).
        final itemsFromBottom = messages.length - 1 - index;
        
        // Use an approximate height of 150 to jump closer to the message
        final estimatedPosition = itemsFromBottom * 150.0;
        
        scrollController.animateTo(
          estimatedPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ).then((_) {
          // After jumping, hopefully the item is now rendered. Try ensureVisible again!
          Future.delayed(const Duration(milliseconds: 50), () {
            final asw = itemKeys[key]?.currentContext;
            if (asw != null && asw.mounted) {
              Scrollable.ensureVisible(
                asw,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: 0.5,
              );
            }
          });
        });
      }
    }
  }

  Future<void> markMessagesAsRead() async {
    if (roomId.value.isEmpty || currentUid.isEmpty) return;

    FirebaseNotificationService.instance.clearAllNotifications();

    final ref = FirebaseDatabase.instance.ref("chats/${roomId.value}");
    final snapshot = await ref.get();

    if (!snapshot.exists) return;

    final Map<String, dynamic> allMessages = Map<String, dynamic>.from(
      snapshot.value as Map,
    );

    final updates = <String, dynamic>{};

    allMessages.forEach((key, value) {
      final msg = Map<String, dynamic>.from(value);
      if (msg["receiver"].toString() == currentUid && msg["isSee"] == false) {
        updates["$key/isSee"] = true;
      }
    });

    if (updates.isNotEmpty) {
      await ref.update(updates);
    }

    await FirebaseDatabase.instance
        .ref("user/$currentUid/lastMessage/${roomId.value}")
        .update({"unreadCount": 0});
  }

  Future<void> incrementUnreadCount() async {
    final ref = FirebaseDatabase.instance.ref(
      "user/$receiverUid/lastMessage/${roomId.value}/unreadCount",
    );


    await ref.runTransaction((value) {
      return Transaction.success((value as int? ?? 0) + 1);
    });
  }

  @override
  void onClose() {
    markMessagesAsRead();
    _typingTimer?.cancel();
    _chatSub?.cancel();
    _chatChangedSub?.cancel();
    _chatRemovedSub?.cancel();
    _callSub?.cancel();
    player.dispose();
    _newMessageSub?.cancel();
    focusNode.dispose();
    messageController.dispose();
    scrollController.dispose();
    FirebaseDatabase.instance.ref("user/$currentUid").update({
      "isTyping": false,
    });
    ChatState.currentChatUserId = null;
    super.onClose();
  }
}
