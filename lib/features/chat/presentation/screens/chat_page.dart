import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vibe_chat/features/chat/presentation/controller/chat_controller.dart';

import '../../../custom_Preferences/preferences.dart';
import '../../../notification_fcm_service.dart';
import 'package:vibe_chat/features/call/presentation/screens/call_page.dart';
import '../data/date_model.dart';

class ChatPage extends GetWidget<ChatController> {
  const ChatPage({super.key});

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1744),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOptionItem(
                context: context,
                icon: Icons.camera_alt_rounded,
                label: "Camera",
                color: const Color(0xFF8A4DFF),
                onTap: () {
                  Navigator.pop(context);
                  controller.sendImage(source: ImageSource.camera);
                },
              ),
              _buildOptionItem(
                context: context,
                icon: Icons.photo_library_rounded,
                label: "Gallery",
                color: const Color(0xFF3D8BFF),
                onTap: () {
                  Navigator.pop(context);
                  controller.sendImage(source: ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ReceiveDataModel data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1744),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 15),
            if (data.type == "text")
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white70),
                title: const Text("Copy Text", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: data.message));
                  Get.snackbar(
                    "Copied",
                    "Message copied to clipboard",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF101A4D),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(12),
                    borderRadius: 10,
                  );
                },
              ),
            if (data.type == "image" && data.sender != controller.currentUid)
              ListTile(
                leading: const Icon(Icons.download_rounded, color: Colors.white70),
                title: const Text("Download Image", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  controller.downloadImage(data.message);
                },
              ),
            if (data.sender == controller.currentUid && data.key.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text("Delete Message", style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  controller.deleteMessage(data.key);
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030B33),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
        titleSpacing: 0,
        backgroundColor: const Color(0xFF030B33),
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFF101B4B),
            height: 1,
          ),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1A265A),
                  backgroundImage:
                      (controller.receiverPhoto != null &&
                          controller.receiverPhoto!.isNotEmpty)
                      ? NetworkImage(controller.receiverPhoto!)
                      : null,
                  child:
                      (controller.receiverPhoto == null ||
                          controller.receiverPhoto!.isEmpty)
                      ? const Icon(Icons.person, size: 24, color: Colors.white60)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Obx(
                    () => controller.isUserOnline.value
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF030B33),
                                width: 2,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.receiverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(
                  () => Text(
                    controller.isUserTyping.value
                        ? "typing..."
                        : controller.isUserOnline.value
                        ? "online"
                        : controller.lastSeen.value,
                    style: TextStyle(
                      fontSize: 12,
                      color: controller.isUserTyping.value
                          ? const Color(0xFF00E676)
                          : controller.isUserOnline.value
                          ? Colors.white70
                          : Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: const [
                    Icon(Icons.lock_rounded, size: 9, color: Color(0xFF00E676)),
                    SizedBox(width: 3),
                    Text(
                      "End-to-end encrypted",
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF00E676),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 24),
            onPressed: () {
              Get.to(
                () => const CallPage(),
                arguments: {
                  'roomId': controller.roomId.value,
                  'receiverName': controller.receiverName,
                  'receiverPhoto': controller.receiverPhoto,
                  'receiverUid': controller.receiverUid,
                  'receiverFcm': controller.receiverfcm,
                  'isCaller': true,
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Obx(() {
                  if (controller.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101A4D).withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No messages yet",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Say hi to ${controller.receiverName} 👋",
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final realIndex = controller.messages.length - 1 - index;
                      final chats = controller.messages[realIndex];

                      bool showDate = false;
                      if (realIndex == 0) {
                        showDate = true;
                      } else {
                        final prev = controller.messages[realIndex - 1];
                        showDate = !_isSameDay(chats.time, prev.time);
                      }

                      Widget bubble;
                      if (chats.type == 'call') {
                        bubble = _buildCallBubble(context, chats);
                      } else if (chats.sender == controller.currentUid) {
                        bubble = isSend(context, chats);
                      } else {
                        bubble = isReceive(context, chats);
                      }

                      // Swipe right to reply
                      return Dismissible(
                        key: ValueKey('reply_${chats.key}'),
                        direction: DismissDirection.startToEnd,
                        confirmDismiss: (_) async {
                          controller.setReply(chats);
                          controller.focusNode.requestFocus();
                          return false; // don't actually dismiss
                        },
                        background: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8A4DFF).withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.reply_rounded,
                                color: Color(0xFF8A4DFF),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        child: Container(
                          key: controller.itemKeys.putIfAbsent(chats.key, () => GlobalKey()),
                          child: Column(
                            children: [
                              if (showDate) _buildDateSeparator(chats.time),
                              bubble,
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),

                // Scroll to Bottom Floating Button
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Obx(
                    () => controller.showScrollToBottom.value
                        ? GestureDetector(
                            onTap: controller.animateToBottom,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2D77),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),

          // Uploading Banner
          Obx(
            () => controller.isUploading.value
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101A4D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E2D77)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF8A4DFF),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Uploading photo...",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Reply bar (above input)
          Obx(() {
            final reply = controller.replyingTo.value;
            if (reply == null) return const SizedBox.shrink();
            final isMe = reply.sender == controller.currentUid;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1744),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Color(0xFF8A4DFF), width: 3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isMe ? "You" : controller.receiverName,
                          style: const TextStyle(
                            color: Color(0xFF8A4DFF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reply.type == 'image' ? '📷 Photo' : reply.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                    onPressed: controller.clearReply,
                  ),
                ],
              ),
            );
          }),

          // Bottom Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF030B33),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1744),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFF1E2D77)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            controller: controller.messageController,
                            focusNode: controller.focusNode,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Obx(
                          () => controller.isUploading.value
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white70,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.attach_file_rounded,
                                    color: Colors.white70,
                                    size: 24,
                                  ),
                                  onPressed: () => _showAttachmentOptions(context),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => controller.isTyping.value
                      ? Container(
                          height: 46,
                          width: 46,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFEC4DFF),
                                Color(0xFF8A4DFF),
                                Color(0xFF3D8BFF),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              String messageBody =
                                  controller.messageController.text;
                              String token = controller.receiverfcm;
                              String? currentUser = await getPreferences(
                                "username",
                              );
                              String? currentUserPhoto = await getPreferences(
                                "photo",
                              );
                              String? currentUid = await getPreferences("UID");
                              log("Sending to photo $currentUserPhoto");
                              log("Sending to currentUser: $currentUser");
                              controller.sendMessage();

                              if (token.isNotEmpty) {
                                await FCMService.sendNotification(
                                  fcmToken: token,
                                  title: currentUser ?? "New Message",
                                  body: messageBody,
                                  senderImage: currentUserPhoto ?? "",
                                  username: currentUser ?? "",
                                  senderUid: currentUid ?? "",
                                );
                              } else {
                                log("Error: Receiver FCM token is empty!");
                              }
                            },
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget isSend(BuildContext context, ReceiveDataModel data) {
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.65;
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, data),
      child: Align(
        alignment: Alignment.centerRight,
        child: Obx(() => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          margin: const EdgeInsets.only(top: 4, bottom: 4, left: 60),
          padding: data.type == "image"
              ? const EdgeInsets.all(6)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: controller.highlightedMessageKey.value == data.key 
                ? const Color(0xFF00E676).withValues(alpha: 0.3) 
                : null,
            border: controller.highlightedMessageKey.value == data.key
                ? Border.all(color: const Color(0xFF00E676), width: 2)
                : null,
            gradient: controller.highlightedMessageKey.value == data.key 
                ? null 
                : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8A4DFF),
                Color(0xFF3D8BFF),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A4DFF).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reply quote
              if (data.replyMessage != null && data.replyMessage!.isNotEmpty)
                _buildReplyQuote(
                  replyMessage: data.replyMessage!,
                  replyType: data.replyType ?? 'text',
                  replyToMe: data.replyTo == controller.currentUid,
                  isSender: true,
                  replyKey: data.replyKey,
                ),
              data.type == "image"
                  ? GestureDetector(
                      onTap: () => _showImagePreview(context, data.message),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          data.message,
                          width: maxBubbleWidth,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: maxBubbleWidth,
                              height: 150,
                              color: Colors.black26,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: maxBubbleWidth,
                            height: 100,
                            color: Colors.black26,
                            child: const Icon(Icons.broken_image,
                                color: Colors.white54),
                          ),
                        ),
                      ),
                    )
                  : Text(
                      data.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(data.time),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    data.isSee ? Icons.done_all : Icons.done,
                    size: 15,
                    color: data.isSee ? const Color(0xFF00E676) : Colors.white70,
                  ),
                ],
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget isReceive(BuildContext context, ReceiveDataModel data) {
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.65;
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, data),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4, right: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF1A265A),
                backgroundImage:
                    (controller.receiverPhoto != null &&
                        controller.receiverPhoto!.isNotEmpty)
                    ? NetworkImage(controller.receiverPhoto!)
                    : null,
                child:
                    (controller.receiverPhoto == null ||
                        controller.receiverPhoto!.isEmpty)
                    ? const Icon(Icons.person, size: 16, color: Colors.white60)
                    : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Obx(() => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: data.type == "image"
                      ? const EdgeInsets.all(6)
                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: controller.highlightedMessageKey.value == data.key 
                        ? const Color(0xFF00E676).withValues(alpha: 0.3) 
                        : const Color(0xFF131D4F),
                    border: controller.highlightedMessageKey.value == data.key
                        ? Border.all(color: const Color(0xFF00E676), width: 2)
                        : Border.all(color: const Color(0xFF1E2D77).withValues(alpha: 0.6)),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reply quote
                      if (data.replyMessage != null && data.replyMessage!.isNotEmpty)
                        _buildReplyQuote(
                          replyMessage: data.replyMessage!,
                          replyType: data.replyType ?? 'text',
                          replyToMe: data.replyTo == controller.currentUid,
                          isSender: false,
                          replyKey: data.replyKey,
                        ),
                      data.type == "image"
                          ? GestureDetector(
                              onTap: () => _showImagePreview(context, data.message),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  data.message,
                                  width: maxBubbleWidth,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: maxBubbleWidth,
                                      height: 150,
                                      color: Colors.black26,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: maxBubbleWidth,
                                    height: 100,
                                    color: Colors.black26,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.white54),
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              data.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.3,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(data.time),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    try {
      final milliseconds = int.parse(time);
      final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
      return DateFormat("hh:mm a").format(dateTime);
    } catch (e) {
      return "";
    }
  }

  bool _isSameDay(String t1, String t2) {
    try {
      final d1 = DateTime.fromMillisecondsSinceEpoch(int.parse(t1));
      final d2 = DateTime.fromMillisecondsSinceEpoch(int.parse(t2));
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    } catch (_) {
      return true;
    }
  }

  String _formatDate(String time) {
    try {
      final ms = int.parse(time);
      final date = DateTime.fromMillisecondsSinceEpoch(ms);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDay = DateTime(date.year, date.month, date.day);

      if (msgDay == today) return 'Today';
      if (msgDay == yesterday) return 'Yesterday';
      // Same year: "Mon, 3 Jul"
      if (date.year == now.year) return DateFormat('EEE, d MMM').format(date);
      // Older: "3 Jul 2024"
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  Widget _buildDateSeparator(String time) {
    final label = _formatDate(time);
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFF1E2D77), thickness: 0.8)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1744),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E2D77)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: Color(0xFF1E2D77), thickness: 0.8)),
        ],
      ),
    );
  }

  Widget _buildCallBubble(BuildContext context, ReceiveDataModel data) {
    final isMine = data.sender == controller.currentUid;
    final isMissed = data.message.contains('Missed') || data.message.contains('No Answer');

    // Direction-aware label and icon
    final String label;
    final IconData dirIcon;
    final Color color;

    if (isMissed) {
      color = Colors.redAccent;
      if (isMine) {
        label = '📵 No Answer';          // Maine call ki, usne nahi uthaya
        dirIcon = Icons.call_made_rounded;
      } else {
        label = '📵 Missed Call';        // Usne call ki, maine nahi uthaya
        dirIcon = Icons.call_missed_rounded;
      }
    } else {
      color = const Color(0xFF00C853);
      if (isMine) {
        label = '📹 Outgoing Call';      // Maine call ki
        dirIcon = Icons.call_made_rounded;
      } else {
        label = '📹 Incoming Call';      // Usne call ki
        dirIcon = Icons.call_received_rounded;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isMine ? 60 : 0,
            right: isMine ? 0 : 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMine
                ? const Color(0xFF1A0A3D)
                : const Color(0xFF0F1744),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Direction arrow icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(dirIcon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              // Label + duration
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (data.duration != null && data.duration!.isNotEmpty)
                    Text(
                      data.duration!,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Time
              Text(
                _formatTime(data.time),
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyQuote({
    required String replyMessage,
    required String replyType,
    required bool replyToMe,
    required bool isSender,
    String? replyKey,
  }) {
    return GestureDetector(
      onTap: () {
        if (replyKey != null && replyKey.isNotEmpty) {
          controller.scrollToMessage(replyKey);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isSender ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: replyToMe
                ? const Color(0xFF00E676)
                : const Color(0xFF8A4DFF),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            replyToMe ? "You" : controller.receiverName,
            style: TextStyle(
              color: replyToMe
                  ? const Color(0xFF00E676)
                  : const Color(0xFF8A4DFF),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyType == 'image' ? '📷 Photo' : replyMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ));
  }
}
