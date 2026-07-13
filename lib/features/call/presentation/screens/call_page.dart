import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import '../controller/call_controller.dart';
import '../../services/call_bubble_service.dart';

class CallPage extends StatelessWidget {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CallController controller = Get.isRegistered<CallController>()
        ? Get.find<CallController>()
        : Get.put(CallController());

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            CallBubbleService.showSideCallBubble();
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF030B33),
        body: Stack(
        children: [
          // 1. Remote Video Stream / Calling Placeholder
          Obx(
            () => (controller.isConnected.value &&
                    (controller.isRemoteVideoReady.value ||
                        controller.remoteRenderer.srcObject != null))
                ? RTCVideoView(
                    controller.remoteRenderer,
                    key: ValueKey(
                      controller.remoteRenderer.srcObject?.id ?? 'remote_view',
                    ),
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : _buildCallingPlaceholder(controller),
          ),

          // 2. Ambient Gradient Overlays for Text Legibility
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xCC030B33),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xEE030B33),
                    ],
                    stops: [0.0, 0.22, 0.70, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // 3. Top Glass Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildTopHeader(controller),
          ),

          // 4. Draggable Local Camera Picture-in-Picture View
          _DraggablePipView(controller: controller),

          // 5. Bottom Floating Glass Control Bar
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 20,
            right: 20,
            child: _buildBottomControlBar(controller),
          ),
        ],
      ),
    ),
  );
  }

  // ─── 1. Calling / Connecting Placeholder View ────────────────────────────────
  Widget _buildCallingPlaceholder(CallController controller) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [
            Color(0xFF1E144A),
            Color(0xFF0C0926),
            Color(0xFF030B33),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Pulsing Avatar Container
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow Aura
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8A4DFF).withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4DFF).withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Gradient Ring Border
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFEC4DFF),
                      Color(0xFF8A4DFF),
                      Color(0xFF3D8BFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: const Color(0xFF101A4D),
                  backgroundImage: (controller.receiverPhoto != null &&
                          controller.receiverPhoto!.isNotEmpty)
                      ? NetworkImage(controller.receiverPhoto!)
                      : null,
                  child: (controller.receiverPhoto == null ||
                          controller.receiverPhoto!.isEmpty)
                      ? const Icon(Icons.person, size: 56, color: Colors.white70)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Receiver Name
          Text(
            controller.receiverName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Status Badge Pill
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF101A4D).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEC4DFF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.callStatus.value,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Loading Progress Indicator
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF8A4DFF).withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. Top Header Bar Widget ───────────────────────────────────────────────
  Widget _buildTopHeader(CallController controller) {
    return Row(
      children: [
        // Back Button (Minimize to Side Bubble)
        GestureDetector(
          onTap: () {
            Get.back();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              CallBubbleService.showSideCallBubble();
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF101A4D).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // User Info & Duration Pill
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.receiverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                ),
              ),
              const SizedBox(height: 2),
              Obx(
                () => Row(
                  children: [
                    if (controller.isConnected.value)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    Text(
                      controller.isConnected.value
                          ? controller.formattedDuration
                          : controller.callStatus.value,
                      style: TextStyle(
                        color: controller.isConnected.value
                            ? const Color(0xFF00E676)
                            : Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 6)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quality Badge
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF101A4D).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.high_quality_rounded,
                      color: Color(0xFF3D8BFF), size: 18),
                  SizedBox(width: 4),
                  Text(
                    "HD",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── 4. Glassmorphic Control Bar ───────────────────────────────────────────
  Widget _buildBottomControlBar(CallController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF08103A).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mute Button
              Obx(
                () => _buildControlButton(
                  icon: controller.isMuted.value
                      ? Icons.mic_off_rounded
                      : Icons.mic_rounded,
                  label: controller.isMuted.value ? "Muted" : "Mute",
                  isActive: controller.isMuted.value,
                  activeColor: Colors.redAccent,
                  onTap: controller.toggleAudio,
                ),
              ),

              // Camera Toggle Button
              Obx(
                () => _buildControlButton(
                  icon: controller.isVideoOff.value
                      ? Icons.videocam_off_rounded
                      : Icons.videocam_rounded,
                  label: controller.isVideoOff.value ? "Video Off" : "Video",
                  isActive: controller.isVideoOff.value,
                  activeColor: Colors.redAccent,
                  onTap: controller.toggleVideo,
                ),
              ),

              // Flip Camera Button
              _buildControlButton(
                icon: Icons.cameraswitch_rounded,
                label: "Flip",
                isActive: false,
                onTap: controller.switchCamera,
              ),

              // End Call Button (Gradient Red Glow)
              _buildEndCallButton(onTap: controller.endCall),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for standard action buttons
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    Color activeColor = const Color(0xFF8A4DFF),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor
                  : const Color(0xFF1E2D77).withValues(alpha: 0.6),
              border: Border.all(
                color: isActive
                    ? activeColor.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.1),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for glowing End Call button
  Widget _buildEndCallButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF3B30),
                  Color(0xFFE02020),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.5),
                  blurRadius: 14,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "End",
            style: TextStyle(
              color: Color(0xFFFF5252),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Draggable Picture-In-Picture Local Camera View ──────────────────────────
class _DraggablePipView extends StatefulWidget {
  final CallController controller;
  const _DraggablePipView({required this.controller});

  @override
  State<_DraggablePipView> createState() => _DraggablePipViewState();
}

class _DraggablePipViewState extends State<_DraggablePipView> {
  Offset? position;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final defaultTop = media.padding.top + 75.0;
    final defaultLeft = media.size.width - 120.0;

    final top = position?.dy ?? defaultTop;
    final left = position?.dx ?? defaultLeft;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double newX = (position?.dx ?? left) + details.delta.dx;
            double newY = (position?.dy ?? top) + details.delta.dy;

            // Screen boundary constraints
            newX = newX.clamp(10.0, media.size.width - 115.0);
            newY = newY.clamp(media.padding.top + 40.0, media.size.height - 180.0);

            position = Offset(newX, newY);
          });
        },
        child: Obx(
          () => Container(
            width: 105,
            height: 145,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
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
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: (widget.controller.isVideoOff.value ||
                          !widget.controller.isMediaReady.value ||
                          widget.controller.localRenderer.srcObject == null)
                      ? Container(
                          color: const Color(0xFF0F1744),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_off_rounded,
                                    color: Colors.white54, size: 28),
                                SizedBox(height: 4),
                                Text(
                                  "Off",
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RTCVideoView(
                          widget.controller.localRenderer,
                          key: ValueKey(
                            widget.controller.localRenderer.srcObject?.id ??
                                'local_view',
                          ),
                          mirror: widget.controller.isFrontCamera.value,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                ),

                // Quick Flip Camera Icon Badge
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: widget.controller.switchCamera,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
