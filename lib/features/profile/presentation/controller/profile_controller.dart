import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/route/page_route.dart';
import '../../../custom_Preferences/preferences.dart';

class ProfileController extends GetxController {
  //show profile start
  final name = "".obs;
  final email = "".obs;
  final photo = "".obs;
  final username = "".obs;
  final password = "".obs;

  Future<void> showProfile() async {
    String? uid = await getPreferences("UID");
    FirebaseDatabase.instance.ref("user/$uid").onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        name.value = data["name"] ?? "";
        email.value = data["email"] ?? "";
        photo.value = data["photo"] ?? "";
        username.value = data["username"] ?? "";
        password.value = data["password"] ?? "";
      }
    });
  }
  @override
  void onInit() {
    showProfile();
    super.onInit();
  }

  Future<void> openPrivacyPolicy() async {
    final Uri url = Uri.parse(
      'https://sudhir-coder1.github.io/vibechat-website/privacy.html',
    );

    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        Get.snackbar("Error", "Could not open privacy policy link");
      }
    } catch (e) {
      Get.snackbar("Error", "Could not open link: $e");
    }
  }



  Future<void> deleteAccount() async {
    try {
      final uid = await getPreferences("UID");
      if (uid == null || uid.isEmpty) return;

      // 1. Delete user data from Realtime Database
      await FirebaseDatabase.instance.ref('user/$uid').remove();

      // 2. Safely attempt to delete Auth account (if logged in via Google/Firebase Auth)
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null) {
        try {
          await authUser.delete();
        } catch (e) {
          // If requires-recent-login or network error occurs, sign out instead of hanging
          await FirebaseAuth.instance.signOut();
        }
      }

      // 3. Clear all local preferences
      await removePreferences("UID");
      await removePreferences("username");
      await removePreferences("photo");
      
      // 4. Redirect to Login Page
      Get.offAllNamed(AppRoute.login);
      Get.snackbar("Success", "Account deleted successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete account: $e");
    }
  }

}