import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class RakshakVoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _initialized = false;
  bool _listening = false;

  bool get isListening => _listening;

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('🎙️ RAKSHAK VOICE STATUS: $status');
      },
      onError: (error) {
        debugPrint('⚠️ RAKSHAK VOICE ERROR: $error');
        _listening = false;
      },
    );

    _initialized = available;

    debugPrint(
      '🎙️ RAKSHAK VOICE INITIALIZED: $_initialized',
    );

    return available;
  }

  Future<void> startListening({
    required void Function(String words) onWords,
  }) async {
    final available = await initialize();

    if (!available) {
      debugPrint(
        '❌ RAKSHAK VOICE: Speech recognition unavailable',
      );
      return;
    }

    if (_listening) {
      return;
    }

    _listening = true;

    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();

        if (words.isEmpty) {
          return;
        }

        debugPrint(
          '🎙️ RAKSHAK VOICE WORDS: $words',
        );

        onWords(words);
      },
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<void> stopListening() async {
    if (!_listening) {
      return;
    }

    await _speech.stop();
    _listening = false;

    debugPrint('🛑 RAKSHAK VOICE: Listening stopped');
  }

  Future<void> dispose() async {
    await stopListening();
  }
}