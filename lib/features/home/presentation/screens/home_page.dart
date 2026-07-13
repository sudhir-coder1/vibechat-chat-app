import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibe_chat/core/route/page_route.dart';
import 'package:vibe_chat/features/home/presentation/controller/home_controller.dart';

import '../../../custom_appBar/custom_app_bar.dart';


class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  // ✅ Proper Time Formatter
  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) {
      return "";
    }
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat("hh:mm a").format(dateTime); // e.g., 02:45 PM
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: const Color(0xFF030B33),

      floatingActionButton: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFEC4DFF), // Pink
              Color(0xFF8A4DFF), // Purple
              Color(0xFF3D8BFF), // Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x668A4DFF),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            Get.toNamed(AppRoute.searchUser);
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),

      appBar: CustomAppBar(
        title1: "VibeChat",
        name: "Connect with Friends",
        actionicon: Icons.notifications_active,
        onTap: () => Get.toNamed(AppRoute.requests),
        badgeCount: controller.pendingRequestsCount.value,
      ),
      body: Builder(builder: (context) {
        if (controller.isLoading.value) {
          return Shimmer.fromColors(
            baseColor: const Color(0xFF1A2460),
            highlightColor: const Color(0xFF2A3880),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 8,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Avatar circle
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name + last message lines
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Time placeholder
                    Container(
                      height: 11,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (controller.users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 90,
                    color: Color(0xFF93EDC7),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "No chats yet",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start a conversation with friends",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: controller.users.length,
          itemBuilder: (context, index) {
            final user = controller.users[index];
            return Material(
              color: Color(0xFF101A4D),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () {
                  controller.resetUnreadCount(user.uid);
                  Get.toNamed(
                    AppRoute.chat,
                    arguments: {
                      "receiverUid": user.uid,
                      "receiverName": user.username,
                      "receiverPhoto": user.photo,
                      "receiverfcm": user.fcm,
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFEC4DFF),
                                  Color(0xFF8A4DFF),
                                  Color(0xFF3D8BFF),
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  (user.photo != null && user.photo!.isNotEmpty)
                                  ? NetworkImage(user.photo!)
                                  : null,
                              backgroundColor: const Color(0xFF101A4D),
                              child: (user.photo == null || user.photo!.isEmpty)
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 28,
                                      color: Colors.white70,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: user.isOnline == true
                                    ? Colors.green
                                    : Colors.grey.shade400,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 14),

                      // Chat Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.lastMessage.isNotEmpty
                                  ? user.lastMessage
                                  : "Say hello 👋",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Time + Unread Badge
                      Obx(() {
                        final int unreadCount = controller.unreadCounts[user.uid] ?? 0;
                        final bool hasUnread = unreadCount > 0;

                        return Column(

                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(user.lastMessageTime),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasUnread)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  constraints: const BoxConstraints(minWidth: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? "99+" : "$unreadCount",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],

                        );
                      })                    ],
                  ),
                ),
              ),
            ).paddingSymmetric(vertical: 5);
          },
        );
      }),
    ));
  }
}
