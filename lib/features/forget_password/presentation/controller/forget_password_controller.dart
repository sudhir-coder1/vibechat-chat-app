import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPasswordController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final userFound = false.obs;
  final password="".obs;

  String? uid;

  /// CHECK USER BY EMAIL
  Future<void> checkUser() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar("Error", "Enter email");
      return;
    }

    isLoading.value = true;

    try {
      final snapshot =
      await FirebaseDatabase.instance.ref("user").get();

      if (!snapshot.exists) {
        Get.snackbar("Error", "No users found");
        isLoading.value = false;
        return;
      }

      final users =
      Map<String, dynamic>.from(snapshot.value as Map);

      bool found = false;

      users.forEach((key, value) {
        final data = Map<String, dynamic>.from(value);

        if (data["email"] == email) {
          uid = key;
          found = true;
        }
      });

      userFound.value = found;

      if (found) {
        Get.snackbar("Success", "User found");
      } else {
        Get.snackbar("Error", "User not found");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// UPDATE PASSWORD
  Future<void> updatePassword() async {
    final newPassword = passwordController.text.trim();

    if (uid == null) {
      Get.snackbar("Error", "No user selected");
      return;
    }

    if (newPassword.isEmpty) {
      Get.snackbar("Error", "Enter new password");
      return;
    }

    isLoading.value = true;

    try {
      await FirebaseDatabase.instance
          .ref("user/$uid")
          .update({
        "password": newPassword,
      });

      Get.snackbar("Success", "Password updated");

      // reset
      emailController.clear();
      passwordController.clear();
      userFound.value = false;
      uid = null;

      Get.back();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}