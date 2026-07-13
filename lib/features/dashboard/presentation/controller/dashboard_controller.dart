import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  RxInt currentIndex = 0.obs;

  final PageController pageController = PageController();

  void changePage(int index) {
    currentIndex.value = index;

    pageController.jumpToPage(index);
    // ya animateToPage use kar sakte ho
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}