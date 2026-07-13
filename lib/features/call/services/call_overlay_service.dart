import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../presentation/controller/call_controller.dart';
import '../presentation/screens/call_page.dart';

class CallOverlayService {
  static OverlayEntry? _overlayEntry;
  static bool get isMinimized => _overlayEntry != null;

  /// Shows floating call bar at top of screen when call is minimized
  static void showFloatingCallBar() {
    hideFloatingCallBar();
    if (!Get.isRegistered<CallController>()) return;

    try {
      // Get global root navigator overlay state
      final overlayState = Get.key.currentState?.overlay ??
          (Get.overlayContext != null ? Overlay.maybeOf(Get.overlayContext!) : null) ??
          (Get.context != null ? Overlay.maybeOf(Get.context!) : null);

      if (overlayState == null) {
        log("OverlayState is null, cannot insert floating call bar");
        return;
      }

      _overlayEntry = OverlayEntry(
        builder: (context) {
          if (!Get.isRegistered<CallController>()) {
            hideFloatingCallBar();
            return const SizedBox.shrink();
          }
          final controller = Get.find<CallController>();

          return Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              elevation: 20,
              child: GestureDetector(
                onTap: () {
                  hideFloatingCallBar();
                  if (!Get.currentRoute.contains("CallPage")) {
                    Get.to(() => const CallPage());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1744),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFF8A4DFF), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x998A4DFF),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Video Call Icon Badge
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFEC4DFF), Color(0xFF8A4DFF)],
                          ),
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name & Live Duration
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.receiverName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Obx(
                              () => Text(
                                controller.isConnected.value
                                    ? "Ongoing Call • ${controller.formattedDuration} (Tap to Open)"
                                    : "${controller.callStatus.value} (Tap to Open)",
                                style: const TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Open Full Screen Button
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8A4DFF).withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Quick End Call Button
                      GestureDetector(
                        onTap: () {
                          hideFloatingCallBar();
                          controller.endCall();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 16,
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
      log("✅ Floating Call Bar successfully inserted to Overlay");
    } catch (e) {
      log("Error showing call overlay: $e");
      _overlayEntry = null;
    }
  }

  /// Removes floating call bar
  static void hideFloatingCallBar() {
    try {
      _overlayEntry?.remove();
    } catch (_) {}
    _overlayEntry = null;
  }
}
