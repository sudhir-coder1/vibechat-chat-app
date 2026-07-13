import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../custom_Preferences/preferences.dart';

class UserNameController extends GetxController {
  //show profile start
  final name = "".obs;
  final email = "".obs;
  final photo = "".obs;
  final password = ''.obs;

  Future<void> showProfile() async {
    String? uid = await getPreferences("UID");
    FirebaseDatabase.instance.ref("user/$uid").onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        name.value = data["name"] ?? "";
        email.value = data["email"] ?? "";
        photo.value = data["photo"] ?? "";
      }
    });
  }

  //show profile end;

  //createUserNamePassword start

  final userIdController = TextEditingController();
  final passwordController = TextEditingController();
  final isChecking = false.obs;
  final isUsernameAvailable = RxnBool();

  Future<void> checkUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      isUsernameAvailable.value = null;
      return;
    }

    isChecking.value = true;

    try {
      final uid = await getPreferences("UID");
      final snapshot = await FirebaseDatabase.instance.ref("user").get();

      bool exists = false;
      if (snapshot.exists && snapshot.value is Map) {
        final users = snapshot.value as Map;
        for (var key in users.keys) {
          // If the username exists but belongs to the current user, it's fine.
          if (key.toString() == uid) continue;
          
          final userMap = users[key];
          if (userMap is Map) {
            final existingUsername = userMap["username"]?.toString();
            if (existingUsername == trimmed) {
              exists = true;
              break;
            }
          }
        }
      }

      // Check if we are still checking for the current text
      if (userIdController.text.trim() == trimmed) {
        isUsernameAvailable.value = !exists;
      }
    } catch (e) {
      if (userIdController.text.trim() == trimmed) {
        isUsernameAvailable.value = false;
      }
    } finally {
      if (userIdController.text.trim() == trimmed) {
        isChecking.value = false;
      }
    }
  }

  Future<bool> createUserNamePassword() async {
    try {
      if (isUsernameAvailable.value==false ) {
        Get.snackbar(
          "Error",
          "Username already taken",
        );
        return false;
      }

      String? uid = await getPreferences("UID");

      if (uid == null) return false;

      await FirebaseDatabase.instance.ref("user/$uid").update({
        "username": userIdController.text.trim(),
        "password": passwordController.text.trim(),
      });

      return true;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    checkUsername(userIdController.text);
    showProfile();
  }
}
