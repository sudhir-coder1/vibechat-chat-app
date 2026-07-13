import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../presentation/controller/call_controller.dart';
import '../presentation/screens/call_page.dart';

class CallBubbleService {
  static OverlayEntry? _overlayEntry;
  static bool get isBubbleActive => _overlayEntry != null;

  /// Shows a compact floating call bubble on the side of the screen when call is minimized
  static void showSideCallBubble() {
    hideSideCallBubble();
    if (!Get.isRegistered<CallController>()) return;

    try {
      final overlayState = Get.key.currentState?.overlay ??
          (Get.overlayContext != null ? Overlay.maybeOf(Get.overlayContext!) : null) ??
          (Get.context != null ? Overlay.maybeOf(Get.context!) : null);

      if (overlayState == null) {
        log("OverlayState is null, cannot insert side call bubble");
        return;
      }

      _overlayEntry = OverlayEntry(
        builder: (context) {
          if (!Get.isRegistered<CallController>()) {
            hideSideCallBubble();
            return const SizedBox.shrink();
          }
          final controller = Get.find<CallController>();

          return Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 14,
            child: Material(
              color: Colors.transparent,
              elevation: 12,
              child: GestureDetector(
                onTap: () {
                  hideSideCallBubble();
                  if (!Get.currentRoute.contains("CallPage")) {
                    Get.to(() => const CallPage());
                  }
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFEC4DFF),
                        Color(0xFF8A4DFF),
                        Color(0xFF3D8BFF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8A4DFF).withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Stack(
                    children: [
                      // User Avatar / Video Icon
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: const Color(0xFF0F1744),
                        backgroundImage: (controller.receiverPhoto != null &&
                                controller.receiverPhoto!.isNotEmpty)
                            ? NetworkImage(controller.receiverPhoto!)
                            : null,
                        child: (controller.receiverPhoto == null ||
                                controller.receiverPhoto!.isEmpty)
                            ? const Icon(Icons.videocam_rounded,
                                color: Colors.white, size: 24)
                            : null,
                      ),

                      // Green Active Call Dot
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      overlayState.insert(_overlayEntry!);
      log("✅ Side Call Bubble inserted successfully");
    } catch (e) {
      log("Error showing side call bubble: $e");
      _overlayEntry = null;
    }
  }

  /// Hides the floating call bubble
  static void hideSideCallBubble() {
    try {
      _overlayEntry?.remove();
    } catch (_) {}
    _overlayEntry = null;
  }
}
