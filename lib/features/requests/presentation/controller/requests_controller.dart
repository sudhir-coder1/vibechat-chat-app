import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import '../../../../core/route/page_route.dart';
import '../../../custom_Preferences/preferences.dart';

class RequestsController extends GetxController {
  final requestsList = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    final currentUid = await getPreferences("UID");
    if (currentUid == null) return;

    FirebaseDatabase.instance
        .ref("chat_requests/$currentUid/received")
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        List<Map<String, dynamic>> temp = [];
        
        for (var entry in data.entries) {
          final request = Map<String, dynamic>.from(entry.value);
          if (request["status"] == "pending") {
            temp.add({
              "uid": entry.key,
              ...request,
            });
          }
        }
        
        // Sort by time descending
        temp.sort((a, b) => (b["time"] ?? 0).compareTo(a["time"] ?? 0));
        requestsList.value = temp;
      } else {
        requestsList.clear();
      }
      isLoading.value = false;
    });
  }

  Future<void> acceptRequest(Map<String, dynamic> request) async {
    final currentUid = await getPreferences("UID");
    if (currentUid == null) return;
    
    final senderUid = request["uid"];
    
    // 1. Delete the request from received and sent nodes
    await FirebaseDatabase.instance.ref("chat_requests/$currentUid/received/$senderUid").remove();
    await FirebaseDatabase.instance.ref("chat_requests/$senderUid/sent/$currentUid").remove();
    
    // 2. Initialize a chat by adding an introductory 'lastMessage' node
    List<String> ids = [currentUid, senderUid];
    ids.sort();
    String roomId = ids.join("_");
    
    final time = ServerValue.timestamp;
    
    // This allows them to show up on each other's HomePage
    await FirebaseDatabase.instance.ref("user/$currentUid/lastMessage/$roomId").set({
      "message": "Chat request accepted",
      "receiverUid": senderUid,
      "time": time,
      "unreadCount": 0
    });
    
    await FirebaseDatabase.instance.ref("user/$senderUid/lastMessage/$roomId").set({
      "message": "Chat request accepted",
      "receiverUid": currentUid,
      "time": time,
      "unreadCount": 0
    });
    
    Get.snackbar("Success", "Request accepted!");
    
    // Navigate to Chat
    Get.toNamed(
      AppRoute.chat,
      arguments: {
        "receiverUid": senderUid,
        "receiverName": request["senderName"],
        "receiverPhoto": request["senderPhoto"],
        "receiverfcm": request["senderFcm"],
      },
    );
  }

  Future<void> rejectRequest(String senderUid) async {
    final currentUid = await getPreferences("UID");
    if (currentUid == null) return;
    
    // Delete from both sides
    await FirebaseDatabase.instance.ref("chat_requests/$currentUid/received/$senderUid").remove();
    await FirebaseDatabase.instance.ref("chat_requests/$senderUid/sent/$currentUid").remove();
    
    Get.snackbar("Declined", "Request removed.");
  }
}
