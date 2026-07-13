import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibe_chat/features/profile/presentation/screens/profile_page.dart';

import '../../../home/presentation/screens/home_page.dart';
import '../controller/dashboard_controller.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030B33),
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        children: [HomePage(), ProfilePage()],
      ),

      bottomNavigationBar: Obx(
        () => Container(
          height: 60,
          margin: EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: MediaQuery.of(context).padding.bottom + 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF101A4D),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buttonBar(
                icon: CupertinoIcons.chat_bubble_fill,
                name: "Chat",
                index: 0,
              ),
              _buttonBar(icon: Icons.person, name: "Profile", index: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttonBar({
    required IconData icon,
    required String name,
    required int index,
  }) {
    return InkWell(
      onTap: () => controller.changePage(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: controller.currentIndex.value == index
              ? const LinearGradient(
                  colors: [
                    Color(0xFFEC4DFF),
                    Color(0xFF8A4DFF),
                    Color(0xFF3D8BFF),
                  ],
                )
              : null,
          color: controller.currentIndex.value == index
              ? null
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 30,
              color: controller.currentIndex.value == index
                  ? Colors.white
                  : Colors.grey.shade200,
            ),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: controller.currentIndex.value == index
                    ? Colors.white
                    : Colors.grey.shade200,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
