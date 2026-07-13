class ReceiveDataModel {
  final String key;
  final String message;
  final String sender;
  final String receiver;
  final String time;
  final bool isSee;
  final String type;
  final String? duration; // for call type messages
  final String? replyMessage;   // quoted message text/url
  final String? replyTo;        // sender uid of quoted message
  final String? replyType;      // 'text' or 'image'
  final String? replyKey;       // original message key

  ReceiveDataModel({
    required this.key,
    required this.message,
    required this.sender,
    required this.receiver,
    required this.time,
    required this.isSee,
    required this.type,
    this.duration,
    this.replyMessage,
    this.replyTo,
    this.replyType,
    this.replyKey,
  });
}