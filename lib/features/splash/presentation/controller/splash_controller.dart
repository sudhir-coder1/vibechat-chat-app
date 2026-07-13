import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:vibe_chat/features/custom_Preferences/preferences.dart';

import '../../../../core/route/page_route.dart';

class SplashController extends GetxController {
  final photo = "".obs;
  final username = "".obs;
  Future<void> showProfile() async {
    String? uid = await getPreferences("UID");
    FirebaseDatabase.instance.ref("user/$uid").onValue.listen((event) async {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        photo.value = data["photo"] ?? "";
        username.value = data["username"] ?? "";
        await setPreferences("username",username.value);
        await setPreferences("photo",photo.value);

      }
    });
  }
  @override
  void onClose() {
    showProfile();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    checkForAppUpdate();
    showProfile();
    loginCheck();
  }
  Future<void> loginCheck() async {
    await Future.delayed(const Duration(seconds: 1));
    String? uid = await getPreferences("UID");
    log("uid Edgar hai$uid");
    
    if (uid != null && uid.isNotEmpty) {
      try {
        // Verify if the user has completed their profile (created a username)
        final snapshot = await FirebaseDatabase.instance.ref("user/$uid/username").get();
        if (!snapshot.exists || snapshot.value == null || snapshot.value.toString().trim().isEmpty) {
          Get.offAllNamed(AppRoute.username);
          return;
        }
      } catch (e) {
        log("Error checking username: $e");
      }
      
      Get.offAllNamed(AppRoute.dashboard);
    } else {
      Get.offAllNamed(AppRoute.login);
    }
  }

  Future<void> checkForAppUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      log("updateInfo $updateInfo");

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        log("updateAvailable");

        await InAppUpdate.performImmediateUpdate();
      } else {
      }
    } catch (e) {
      log("error $e");
    }
  }

}