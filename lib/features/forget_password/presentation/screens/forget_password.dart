import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibe_chat/features/custom_appBar/custom_app_bar.dart';
import '../controller/forget_password_controller.dart';

class ForgetPassword extends GetView<ForgetPasswordController> {
 const  ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030B33),
      appBar: CustomAppBar(title1: "Forget Password"),
      body: Padding(
        padding:  EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Obx(
                () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 SizedBox(height: 10),
          
                 Text(
                  "Reset Password",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
          
                 SizedBox(height: 6),
          
                Text(
                  "Enter your email to find account",
                  style: TextStyle(color: Colors.white60),
                ),
          
                 SizedBox(height: 30),
          
                /// EMAIL FIELD
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient:  LinearGradient(
                      colors: [
                        Color(0xFFEC4DFF), // Pink
                        Color(0xFF8A4DFF), // Purple
                        Color(0xFF35D6FF), // Cyan
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow:  [
                      BoxShadow(
                        color: Color(0x338A4DFF),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding:  EdgeInsets.all(2),
                  child: TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    style:  TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      // labelText: "Email",
                      hintText: "Enter your email",
                      labelStyle:  TextStyle(color: Colors.white70),
                      hintStyle:  TextStyle(color: Colors.white38),
                      prefixIcon:  Icon(
                        Icons.email_outlined,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor:  Color(0xFF030B33),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
          
                 SizedBox(height: 15),
          
                /// CHECK BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient:  LinearGradient(
                        colors: [
                          Color(0xFFEC4DFF),
                          Color(0xFF8A4DFF),
                          Color(0xFF35D6FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow:  [
                        BoxShadow(
                          color: Color(0x558A4DFF),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: controller.checkUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: controller.isLoading.value
                          ?  SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          :  Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Check User",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          
                 SizedBox(height: 25),
          
                /// PASSWORD FIELD (ONLY IF USER FOUND)
                if (controller.userFound.value) ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient:  LinearGradient(
                        colors: [
                          Color(0xFFEC4DFF),
                          Color(0xFF8A4DFF),
                          Color(0xFF35D6FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow:  [
                        BoxShadow(
                          color: Color(0x338A4DFF),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding:  EdgeInsets.all(2),
                    child: TextField(
                      
                      controller: controller.passwordController,
                      onChanged: (value) {
                        controller.password.value = value;
                      },
                      obscureText: true,
                      style:  TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter new password",
                        labelStyle:  TextStyle(color: Colors.white70),
                        hintStyle:  TextStyle(color: Colors.white38),
                        prefixIcon:  Icon(
                          Icons.lock_outline,
                          color: Colors.white70,
                        ),

                        filled: true,
                        fillColor: Color(0xFF030B33),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

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
                          const Text("Minimum 8 characters",style: TextStyle(
                            color: Colors.white
                          ),),
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
                          const Text("1 uppercase letter",style: TextStyle(
                              color: Colors.white
                          ),),
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
                          const Text("1 number",style: TextStyle(
                              color: Colors.white
                          ),),
                        ],
                      ),
                    ],
                  ),


                  SizedBox(height: 15),
          
                  /// UPDATE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient:  LinearGradient(
                          colors: [
                            Color(0xFFEC4DFF),
                            Color(0xFF8A4DFF),
                            Color(0xFF35D6FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow:  [
                          BoxShadow(
                            color: Color(0x558A4DFF),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: controller.updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: controller.isLoading.value
                            ?  SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            :  Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_reset,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Update Password",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}