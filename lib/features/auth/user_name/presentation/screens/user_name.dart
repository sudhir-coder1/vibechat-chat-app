import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:vibe_chat/features/auth/user_name/presentation/controller/user_name_controller.dart';

import '../../../../../core/route/page_route.dart';

class UserName extends GetWidget<UserNameController> {
   const UserName({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
      body: Obx(
        ()=> SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding:  EdgeInsets.all(20),
              child: Column(
                children: [
                   SizedBox(height: 20),
            
                   Text(
                    "Complete Your Profile",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            
                   SizedBox(height: 10),
            
                  Text(
                    "Create your username and password",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
            
                   SizedBox(height: 40),
            
                  Container(
                    padding:  EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      children: [
                         CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            controller.photo.value,
                          ),
                        ),
            
                         SizedBox(height: 15),
            
                         Text(
                          controller.name.value,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            
                         SizedBox(height: 5),
            
                        Text(
                          controller.email.value,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
            
                         SizedBox(height: 30),


                            TextFormField(
                              controller: controller.userIdController,
                              onChanged: controller.checkUsername,
                              decoration: InputDecoration(
                                labelText: "Username",
                                hintText: "e.g. sudhir_123",
                                prefixIcon: const Icon(Icons.alternate_email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                suffixIcon: controller.isChecking.value
                                    ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                                    : controller.isUsernameAvailable.value == null
                                    ? null
                                    : Icon(
                                  controller.isUsernameAvailable.value!
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: controller.isUsernameAvailable.value!
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),


            
                         SizedBox(height: 20),

                        TextFormField(
                          controller: controller.passwordController,
                          onChanged: (value) {
                            controller.password.value = value;
                          },
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  controller.password.value.length >= 8
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: controller.password.value.length >= 8
                                      ? Colors.green
                                      : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text("Minimum 8 characters"),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                Icon(
                                  RegExp(r'[A-Z]')
                                      .hasMatch(controller.password.value)
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: RegExp(r'[A-Z]')
                                      .hasMatch(controller.password.value)
                                      ? Colors.green
                                      : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text("1 uppercase letter"),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                Icon(
                                  RegExp(r'[0-9]')
                                      .hasMatch(controller.password.value)
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: RegExp(r'[0-9]')
                                      .hasMatch(controller.password.value)
                                      ? Colors.green
                                      : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text("1 number"),
                              ],
                            ),
                          ],
                        ),
            
                         SizedBox(height: 30),
            
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () async {
                              String username = controller.userIdController.text.trim();
                              String password = controller.passwordController.text.trim();

                              if (username.isEmpty) {
                                Get.snackbar("Error", "Please enter username");
                                return;
                              }

                              if (controller.isUsernameAvailable.value != true) {
                                Get.snackbar("Error", "Username is not available");
                                return;
                              }

                              if (password.isEmpty) {
                                Get.snackbar("Error", "Please enter password");
                                return;
                              }

                              if (password.length < 8) {
                                Get.snackbar(
                                  "Error",
                                  "Password must be at least 8 characters",
                                );
                                return;
                              }

                              if (!RegExp(r'[A-Z]').hasMatch(password)) {
                                Get.snackbar(
                                  "Error",
                                  "Password must contain at least 1 uppercase letter",
                                );
                                return;
                              }

                              if (!RegExp(r'[0-9]').hasMatch(password)) {
                                Get.snackbar(
                                  "Error",
                                  "Password must contain at least 1 number",
                                );
                                return;
                              }

                              bool success = await controller.createUserNamePassword();

                              if (success) {
                                Get.offAllNamed(AppRoute.dashboard);
                              }
                            },
                            child:  Text(
                              "Continue",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}