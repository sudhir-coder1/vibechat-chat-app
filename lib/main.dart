import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'core/notification/notification_optional.dart';
import 'firebase_options.dart';
import 'core/route/page_route.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,

    );
  } catch (e) {
    log("❌ Firebase Error: $e");
  }
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: Get.key,
      onInit: () async {
        await FirebaseNotificationService.instance.initialize();
      },
      getPages: AppRoute.page,
      debugShowCheckedModeBanner: false,
    );
  }
}
