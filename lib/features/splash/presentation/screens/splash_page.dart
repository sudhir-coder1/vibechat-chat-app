import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibe_chat/features/splash/presentation/controller/splash_controller.dart';


class SplashPage extends GetWidget<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/vibechat.png"),
            SizedBox(height: 20),

            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}