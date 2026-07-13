import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../custom_Preferences/preferences.dart';

class SearchUserController extends GetxController {
  final searchController = TextEditingController();

  final searchUser = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;
  
  // Status: "none", "sent", "received", "friends"
  final requestStatus = "none".obs;
  final isActionLoading = false.obs;

  Future<void> searchByUsername(String username) async {
    if (username.trim().isEmpty) {
      searchUser.value = null;
      return;
    }

    isLoading.value = true;

    final snapshot =
    await FirebaseDatabase.instance.ref("user").get();

    if (!snapshot.exists) {
      isLoading.value = false;
      return;
    }

    final users =
    Map<String, dynamic>.from(snapshot.value as Map);

    bool found = false;

    for (var entry in users.entries) {
      final user =
      Map<String, dynamic>.from(entry.value);

      if ((user["username"] ?? "")
          .toString()
          .toLowerCase()
          .contains(username.toLowerCase())) {

        searchUser.value = {
          "uid": entry.key,
          ...user,
        };
        
        await _checkRelationshipStatus(entry.key);

        found = true;
        break;
      }
    }

    if (!found) {
      searchUser.value = null;
    }

    isLoading.value = false;
  }

  Future<void> _checkRelationshipStatus(String receiverUid) async {
    final currentUid = await getPreferences("UID");
    if (currentUid == null) return;
    
    if (currentUid == receiverUid) {
      requestStatus.value = "self";
      return;
    }

    // 1. Check if they are already friends (have a chat)
    List<String> ids = [currentUid, receiverUid];
    ids.sort();
    String roomId = ids.join("_");
    
    final chatSnapshot = await FirebaseDatabase.instance
        .ref("user/$currentUid/lastMessage/$roomId")
        .get();
        
    if (chatSnapshot.exists) {
      requestStatus.value = "friends";
      return;
    }

    // 2. Check if request sent
    final sentSnapshot = await FirebaseDatabase.instance
        .ref("chat_requests/$currentUid/sent/$receiverUid")
        .get();
        
    if (sentSnapshot.exists) {
      requestStatus.value = "sent";
      return;
    }

    // 3. Check if request received
    final receivedSnapshot = await FirebaseDatabase.instance
        .ref("chat_requests/$currentUid/received/$receiverUid")
        .get();
        
    if (receivedSnapshot.exists) {
      requestStatus.value = "received";
      return;
    }

    requestStatus.value = "none";
  }

  Future<void> sendChatRequest() async {
    final user = searchUser.value;
    if (user == null) return;
    
    final currentUid = await getPreferences("UID");
    if (currentUid == null) return;
    
    final receiverUid = user["uid"];
    isActionLoading.value = true;
    
    try {
      final timestamp = ServerValue.timestamp;
      
      // Save in sender's sent box
      await FirebaseDatabase.instance
          .ref("chat_requests/$currentUid/sent/$receiverUid")
          .set({
            "status": "pending",
            "time": timestamp,
          });
          
      // Fetch sender info to save in receiver's box
      final senderSnapshot = await FirebaseDatabase.instance.ref("user/$currentUid").get();
      Map<String, dynamic> senderData = {};
      if (senderSnapshot.exists) {
        senderData = Map<String, dynamic>.from(senderSnapshot.value as Map);
      }
      
      // Save in receiver's received box
      await FirebaseDatabase.instance
          .ref("chat_requests/$receiverUid/received/$currentUid")
          .set({
            "status": "pending",
            "time": timestamp,
            "senderUid": currentUid,
            "senderName": senderData["name"] ?? "",
            "senderUsername": senderData["username"] ?? "",
            "senderPhoto": senderData["photo"] ?? "",
            "senderFcm": senderData["fcm"] ?? "",
          });
          
      requestStatus.value = "sent";
      Get.snackbar("Success", "Chat request sent!");
    } catch (e) {
      Get.snackbar("Error", "Failed to send request: $e");
    } finally {
      isActionLoading.value = false;
    }
  }
}