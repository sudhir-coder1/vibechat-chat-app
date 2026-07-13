class UserData {
  final String uid;
  final String email;
  final String fcm;
  final String name;
  final String? photo;
  final String lastMessage;
  final int? lastMessageTime;
  final bool isTyping;
   bool isOnline;
  final String username;
  int unreadCount;

  UserData({
    required this.email,
    required this.fcm,
    required this.name,
    required this.photo,
    required this.uid,
    required this.lastMessage,
    this.isTyping = false,
    this.isOnline = false,
    required this.username,
     required this.lastMessageTime,
    this.unreadCount = 0,
  });
}