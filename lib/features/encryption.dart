import 'dart:convert';

class CustomEncryption {
  static const String _key = "MySuperSecretChatKey123";

  static String encrypt(String text) {
    List<int> textBytes = utf8.encode(text);
    List<int> keyBytes = utf8.encode(_key);
    String hexResult = "";

    for (int i = 0; i < textBytes.length; i++) {
      int xorByte = textBytes[i] ^ keyBytes[i % keyBytes.length];

      hexResult += xorByte.toRadixString(16).padLeft(2, '0');
    }
    return hexResult;
  }

  static String decrypt(String hexText) {
    List<int> keyBytes = utf8.encode(_key);
    List<int> decryptedBytes = [];

    for (int i = 0; i < hexText.length; i += 2) {
      String hexByte = hexText.substring(i, i + 2);
      int byte = int.parse(hexByte, radix: 16);

      int originalByte = byte ^ keyBytes[(i ~/ 2) % keyBytes.length];
      decryptedBytes.add(originalByte);
    }

    return utf8.decode(decryptedBytes, allowMalformed: true);
  }
}