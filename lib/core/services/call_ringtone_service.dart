import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';

class CallRingtoneService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  /// Starts playing the ringtone sound in a loop until stopRingtone() is called.
  static Future<void> startRingtone() async {
    if (_isPlaying) return;
    try {
      _isPlaying = true;
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/receive.mp3'));
      log("🔔 Continuous call ringtone started.");
    } catch (e) {
      log("Error starting call ringtone: $e");
    }
  }

  /// Stops the ringing sound.
  static Future<void> stopRingtone() async {
    if (!_isPlaying) return;
    try {
      _isPlaying = false;
      await _player.stop();
      log("🔕 Continuous call ringtone stopped.");
    } catch (e) {
      log("Error stopping call ringtone: $e");
    }
  }
}
