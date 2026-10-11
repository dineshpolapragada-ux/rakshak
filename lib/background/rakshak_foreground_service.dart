import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(
    RakshakTaskHandler(),
  );
}

class RakshakTaskHandler extends TaskHandler {
  int heartbeatCount = 0;

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechInitialized = false;
  bool _listening = false;
  bool _voiceCommandHandled = false;

  @override
  Future<void> onStart(
    DateTime timestamp,
    TaskStarter starter,
  ) async {
    debugPrint(
      '🛡️ RAKSHAK SERVICE: started at ${timestamp.toIso8601String()}',
    );

    await FlutterForegroundTask.updateService(
      notificationTitle: 'Rakshak — VOICE TEST MODE',
      notificationText: 'Rakshak background voice test is active',
    );

    await _startVoiceListening();
  }

  Future<void> _startVoiceListening() async {
    if (_listening) {
      return;
    }

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint(
            '🎙️ RAKSHAK SERVICE VOICE STATUS: $status',
          );

          if (status == 'notListening' && !_voiceCommandHandled) {
            _listening = false;
          }
        },
        onError: (error) {
          debugPrint(
            '⚠️ RAKSHAK SERVICE VOICE ERROR: $error',
          );

          _listening = false;
        },
      );

      _speechInitialized = available;

      if (!available) {
        debugPrint(
          '❌ RAKSHAK SERVICE: Speech recognition unavailable',
        );
        return;
      }

      _voiceCommandHandled = false;
      _listening = true;

      debugPrint(
        '🎙️ RAKSHAK SERVICE: Listening for "Rakshak SOS"',
      );

      await _speech.listen(
        listenMode: stt.ListenMode.dictation,
        onResult: (result) {
          final words =
              result.recognizedWords.toLowerCase().trim();

          if (words.isEmpty) {
            return;
          }

          debugPrint(
            '🎙️ RAKSHAK SERVICE HEARD: ${result.recognizedWords}',
          );

          if (words.contains('rakshak sos') &&
              !_voiceCommandHandled) {
            _voiceCommandHandled = true;

            debugPrint(
              '🚨 RAKSHAK SERVICE: VOICE SOS DETECTED',
            );

            FlutterForegroundTask.sendDataToMain({
              'type': 'sos_trigger',
              'message': 'SOS activated by background voice command',
              'time': DateTime.now().toIso8601String(),
              'source': 'foreground_voice',
            });

            _speech.stop();
            _listening = false;
          }
        },
      );
    } catch (e) {
      debugPrint(
        '❌ RAKSHAK SERVICE VOICE START ERROR: $e',
      );

      _listening = false;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    heartbeatCount++;

    debugPrint(
      'RAKSHAK SERVICE: heartbeat #$heartbeatCount '
      '${timestamp.toIso8601String()}',
    );

    FlutterForegroundTask.updateService(
      notificationText:
          'Background voice service active • heartbeat #$heartbeatCount',
    );

    FlutterForegroundTask.sendDataToMain({
      'type': 'heartbeat',
      'time': timestamp.toIso8601String(),
      'source': 'foreground_service',
      'count': heartbeatCount,
    });

    // Restart the listener if Android/speech recognition
    // stopped listening and no command has been detected.
    if (_speechInitialized &&
        !_listening &&
        !_voiceCommandHandled) {
      _startVoiceListening();
    }
  }

  @override
  Future<void> onDestroy(
    DateTime timestamp,
    bool isTimeout,
  ) async {
    debugPrint(
      '🛑 RAKSHAK SERVICE: destroyed',
    );

    await _speech.stop();
    _listening = false;
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationDismissed() {}
}