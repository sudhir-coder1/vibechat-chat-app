import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import '../../../custom_Preferences/preferences.dart';
import '../../../notification_fcm_service.dart';
import '../../services/signaling_service.dart';
import '../../../chat/presentation/controller/chat_controller.dart';
import '../../../../core/services/call_ringtone_service.dart';
import '../../services/call_overlay_service.dart';
import '../../services/call_bubble_service.dart';

class CallController extends GetxController {
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  final SignalingService signalingService = SignalingService();

  late String roomId;
  late String receiverName;
  late String? receiverPhoto;
  late bool isCaller;

  final isMuted = false.obs;
  final isVideoOff = false.obs;
  final isConnected = false.obs;
  final isFrontCamera = true.obs;
  final callStatus = "Connecting...".obs;

  Timer? _callTimer;
  Timer? _timeoutTimer;
  final callDurationSeconds = 0.obs;

  final isMediaReady = false.obs;
  final isRemoteVideoReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    CallRingtoneService.stopRingtone();

    final args = Get.arguments ?? {};
    roomId = args['roomId'] ?? '';
    receiverName = args['receiverName'] ?? 'User';
    receiverPhoto = args['receiverPhoto'];
    isCaller = args['isCaller'] ?? true;
  }

  @override
  void onReady() {
    super.onReady();
    _startCallProcess();
  }

  /// Non-blocking call setup process triggered after screen render
  Future<void> _startCallProcess() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();

      await signalingService.openUserMedia(localRenderer, remoteRenderer);
      isMediaReady.value = true;

      final args = Get.arguments ?? {};

      if (isCaller) {
        callStatus.value = "Calling...";
        _startTimeoutTimer();

        // Background FCM notification fire (non-blocking)
        _sendCallNotification(args);

        await signalingService.createRoom(
          roomId,
          remoteRenderer,
          onConnected: () {
            _timeoutTimer?.cancel();
            isConnected.value = true;
            callStatus.value = "Connected";
            _startCallTimer();
          },
          onEnded: () {
            endCall();
          },
          onRemoteStream: () {
            isRemoteVideoReady.value = true;
          },
        );
      } else {
        callStatus.value = "Connecting...";
        await signalingService.joinRoom(
          roomId,
          remoteRenderer,
          onConnected: () {
            _timeoutTimer?.cancel();
            isConnected.value = true;
            callStatus.value = "Connected";
            _startCallTimer();
          },
          onEnded: () {
            endCall();
          },
          onRemoteStream: () {
            isRemoteVideoReady.value = true;
          },
        );
      }
    } catch (e) {
      debugPrint("Error starting video call: $e");
      callStatus.value = "Failed to connect";
    }
  }

  /// Sends call notification asynchronously in background
  Future<void> _sendCallNotification(Map<String, dynamic> args) async {
    try {
      String? currentUid = await getPreferences("UID");
      String? currentName = await getPreferences("username");
      String? currentPhoto = await getPreferences("photo");

      final receiverUid = args['receiverUid'];
      String receiverFcm = (args['receiverFcm'] ?? args['receiverfcm'] ?? "").toString();

      if ((receiverFcm.isEmpty || receiverFcm == "null") && receiverUid != null) {
        try {
          final snap = await FirebaseDatabase.instance.ref("user/$receiverUid/fcm").get();
          if (snap.exists && snap.value != null) {
            receiverFcm = snap.value.toString();
          }
        } catch (e) {
          debugPrint("Error fetching FCM token: $e");
        }
      }

      if (receiverUid != null && receiverUid.toString().isNotEmpty) {
        await FirebaseDatabase.instance
            .ref("user/$receiverUid/incomingCall")
            .set({
          "roomId": roomId,
          "callerName": currentName ?? "User",
          "callerPhoto": currentPhoto ?? "",
          "callerUid": currentUid ?? "",
          "status": "calling",
        });

        if (receiverFcm.isNotEmpty && receiverFcm != "null") {
          FCMService.sendNotification(
            fcmToken: receiverFcm,
            title: "Incoming Video Call 📹",
            body: "${currentName ?? 'User'} is video calling you...",
            senderImage: currentPhoto ?? "",
            username: currentName ?? "",
            senderUid: currentUid ?? "",
          ).catchError((e) {
            debugPrint("FCM notification error: $e");
          });
        }
      }
    } catch (e) {
      debugPrint("Error in _sendCallNotification: $e");
    }
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 35), () {
      if (!isConnected.value) {
        callStatus.value = "No answer";
        Future.delayed(const Duration(seconds: 2), () {
          endCall();
        });
      }
    });
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      callDurationSeconds.value++;
    });
  }

  String get formattedDuration {
    final minutes = (callDurationSeconds.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (callDurationSeconds.value % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void toggleAudio() {
    isMuted.value = !isMuted.value;
    signalingService.toggleAudio(isMuted.value);
  }

  void toggleVideo() {
    isVideoOff.value = !isVideoOff.value;
    signalingService.toggleVideo(isVideoOff.value);
  }

  void switchCamera() {
    isFrontCamera.value = !isFrontCamera.value;
    signalingService.switchCamera();
  }

  Future<void> endCall() async {
    CallBubbleService.hideSideCallBubble();
    CallOverlayService.hideFloatingCallBar();
    CallRingtoneService.stopRingtone();
    _callTimer?.cancel();
    _timeoutTimer?.cancel();
    callStatus.value = "Call ended";

    // Save call log in chat
    try {
      if (Get.isRegistered<ChatController>()) {
        final chatController = Get.find<ChatController>();
        await chatController.sendCallLog(
          isCaller: isCaller,
          wasConnected: isConnected.value,
          durationSeconds: callDurationSeconds.value,
        );
      }
    } catch (_) {}

    try {
      // calls node mein status "ended" set karo
      await FirebaseDatabase.instance
          .ref("calls/$roomId/status")
          .set("ended");

      await signalingService.hangUp(
        roomId,
        localRenderer: localRenderer,
        remoteRenderer: remoteRenderer,
      );
      final args = Get.arguments;
      final receiverUid = args != null ? args['receiverUid'] : null;
      if (receiverUid != null) {
        await FirebaseDatabase.instance
            .ref("user/$receiverUid/incomingCall")
            .remove();
      }
      String? currentUid = await getPreferences("UID");
      if (currentUid != null) {
        await FirebaseDatabase.instance
            .ref("user/$currentUid/incomingCall")
            .remove();
      }
    } catch (_) {}
    if (Get.currentRoute.contains('CallPage') || Get.isOverlaysOpen) {
      Get.back();
    }
  }

  @override
  void onClose() {
    CallBubbleService.hideSideCallBubble();
    CallOverlayService.hideFloatingCallBar();
    CallRingtoneService.stopRingtone();
    _callTimer?.cancel();
    _timeoutTimer?.cancel();
    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
      Future.delayed(const Duration(milliseconds: 50), () {
        try {
          localRenderer.dispose();
          remoteRenderer.dispose();
        } catch (e) {
          debugPrint("Renderer dispose error: $e");
        }
      });
    } catch (e) {
      debugPrint("onClose error: $e");
    }
    super.onClose();
  }
}
