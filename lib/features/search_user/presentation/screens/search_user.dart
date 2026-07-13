import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibe_chat/features/custom_appBar/custom_app_bar.dart';
import 'package:vibe_chat/features/search_user/presentation/controller/search_user_controller.dart';

import '../../../../core/route/page_route.dart';

class SearchUser extends GetWidget<SearchUserController> {
   const SearchUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030B33),

      appBar:CustomAppBar(title1: "NewChat",name: "Connect with New Friends",),
      body: Padding(
        padding:  EdgeInsets.all(16),
        child: Column(
          children: [
            /// Search Field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEC4DFF), // Pink
                    Color(0xFF8A4DFF), // Purple
                    Color(0xFF35D6FF), // Cyan
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(2), // Border thickness
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.searchByUsername,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search by username...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF030B33), // Dark background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

             SizedBox(height: 20),

            /// Search Result Header
            Row(
              children: [
                Text(
                  "Users",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20
                  ),

                ),
              ],
            ),

             SizedBox(height: 10),

            /// User List
            Obx(() {
              if (controller.isLoading.value) {
                return  Center(
                  child: CircularProgressIndicator(),
                );
              }

              final user = controller.searchUser.value;

              if (user == null) {
                return  Text("No user found",style: TextStyle(
                  color: Colors.white
                ),);
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEC4DFF),
                      Color(0xFF8A4DFF),
                      Color(0xFF3D8BFF),
                    ],
                  )
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(
                        user["photo"] ?? "",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user["name"] ?? "",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "@${user["username"] ?? ""}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Action Button based on status
                    Obx(() {
                      final status = controller.requestStatus.value;
                      final isLoading = controller.isActionLoading.value;
                      
                      if (status == "self") {
                        return const SizedBox.shrink(); // Can't chat with self
                      }
                      
                      if (status == "friends") {
                        return ElevatedButton(
                          onPressed: () {
                            Get.toNamed(
                              AppRoute.chat,
                              arguments: {
                                "receiverUid": user["uid"],
                                "receiverName": user["name"],
                                "receiverPhoto": user["photo"],
                                "receiverfcm": user["fcm"],
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF101A4D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text("Message"),
                        );
                      }
                      
                      if (status == "sent") {
                        return ElevatedButton(
                          onPressed: null, // Disabled
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text("Requested"),
                        );
                      }
                      
                      if (status == "received") {
                        return ElevatedButton(
                          onPressed: () {
                            // Can't accept from here yet, go to requests tab
                            Get.snackbar("Notice", "Check your requests tab to accept.");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text("Respond"),
                        );
                      }
                      
                      // "none" status
                      return ElevatedButton(
                        onPressed: isLoading ? null : controller.sendChatRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF8A4DFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: isLoading 
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("Connect"),
                      );
                    }),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}