import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vibe_chat/core/route/page_route.dart';
import '../../../../custom_Preferences/preferences.dart';
import '../../../../fcm_token.dart';

class LoginController extends GetxController {
  final _googleSignIn = GoogleSignIn.instance;

  final NotificationServices notificationServices = NotificationServices();

  @override
  void onInit() {
    _initGoogleLogin();
    super.onInit();
  }

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  Future<bool> loginUser() async {
    try {
      String username = usernameController.text.trim();
      String password = passwordController.text.trim();

      if (username.isEmpty) {
        Get.snackbar("Error", "Enter username");
        return false;
      }

      if (password.isEmpty) {
        Get.snackbar("Error", "Enter password");
        return false;
      }

      final snapshot = await FirebaseDatabase.instance.ref("user").get();

      if (!snapshot.exists) {
        Get.snackbar("Error", "No users found");
        return false;
      }

      final users = Map<String, dynamic>.from(snapshot.value as Map);

      for (var entry in users.entries) {
        final user = Map<String, dynamic>.from(entry.value);

        if (user["username"] == username && user["password"] == password) {
          await setPreferences("UID", entry.key);
          String? fcmToken = await notificationServices.fcmToken();

          // Realtime Database update
          await FirebaseDatabase.instance
              .ref("user")
              .child(entry.key)
              .update({
            "fcm": fcmToken,
          });

          Get.snackbar("Success", "Login successful");

          return true;
        }
      }

      Get.snackbar("Error", "Invalid username or password");

      return false;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false;
    }
  }

  String generateChatRoom(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join(' & ');
  }

  Future<void> googleLogin() async {
    final user = await signInWithGoogle();
    final data = user.user;

    if (data == null) return;

    final ref = FirebaseDatabase.instance.ref("user/${data.uid}");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final userData =
      Map<String, dynamic>.from(snapshot.value as Map);

      if ((userData["username"] ?? "").toString().isNotEmpty &&
          (userData["password"] ?? "").toString().isNotEmpty) {


        Get.snackbar(
          "Account Exists",
          "Email already registered. Please login with your username and password.",
        );

        return;
      }
    }

    String? fcmToken = await notificationServices.fcmToken();

    await ref.set({
      "name": data.displayName,
      "email": data.email,
      "photo": data.photoURL,
      "fcm": fcmToken,
    });

    log("current token$fcmToken");

    await setPreferences("UID", data.uid);

    Get.offAllNamed(AppRoute.username);
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final googleUser = await _googleSignIn.authenticate(scopeHint: ['email']);

    // Obtain the auth details from the request
    final googleAuth = googleUser.authentication;

    log("signInWithGoogle ID TOKEN :: ${googleAuth.idToken}");

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  GoogleSignInAuthentication getAuthTokens(GoogleSignInAccount account) {
    return account.authentication;
  }

  Future<void> _initGoogleLogin() async {
    await _googleSignIn.initialize();
  }
}
