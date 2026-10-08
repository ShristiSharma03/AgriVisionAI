// ignore_for_file: unused_field

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceLanguage {
  final String code; // 'en' | 'hi' | 'mr'
  final String label;
  final String sttLocale; // speech_to_text locale id format
  final String ttsLocale; // flutter_tts BCP-47 format

  const VoiceLanguage({
    required this.code,
    required this.label,
    required this.sttLocale,
    required this.ttsLocale,
  });
}

const List<VoiceLanguage> kVoiceLanguages = [
  VoiceLanguage(code: 'en', label: 'English', sttLocale: 'en_IN', ttsLocale: 'en-IN'),
  VoiceLanguage(code: 'hi', label: 'हिंदी', sttLocale: 'hi_IN', ttsLocale: 'hi-IN'),
  VoiceLanguage(code: 'mr', label: 'मराठी', sttLocale: 'mr_IN', ttsLocale: 'mr-IN'),
];

/// Handles speech-to-text (voice input) and text-to-speech (voice
/// output) for AgriVision AI. Separate from the app's broader
/// Settings > Language picker, which currently only controls display
/// text and isn't wired to any stored preference yet — this service
/// has its own lightweight, independently-selected language for voice
/// features specifically, since speech recognition needs an explicit
/// locale and can't "auto-detect" the way a typed-text LLM chat can.
class VoiceService {
  static const String _prefKey = 'voice_language_code';

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttInitialized = false;
  bool _ttsConfigured = false;

  VoiceLanguage languageFromCode(String code) =>
      kVoiceLanguages.firstWhere((l) => l.code == code, orElse: () => kVoiceLanguages.first);

  Future<String> getSavedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? 'en';
  }

  Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }

  bool get isListening => _speech.isListening;

  /// Starts listening. [onResult] fires repeatedly with the
  /// in-progress transcript (so the UI can show live text); [onDone]
  /// fires once when listening stops (either the farmer paused, hit
  /// the time limit, or manually stopped). [onError] fires with a
  /// human-readable reason if recognition fails to start or errors
  /// out mid-session.
  ///
  /// Returns false if the microphone permission was denied or speech
  /// recognition isn't available on this device — the caller should
  /// show an appropriate message in that case.
  Future<bool> startListening({
    required String languageCode,
    required void Function(String text) onResult,
    required void Function() onDone,
    void Function(String error)? onError,
  }) async {
    bool initSucceeded = false;
    try {
      initSucceeded = await _speech.initialize(
        onError: (error) {
          onError?.call('${error.errorMsg} (permanent: ${error.permanent})');
        },
        onStatus: (status) {},
      );
    } catch (e) {
      onError?.call('Failed to initialize speech recognition: $e');
      return false;
    }

    if (!initSucceeded) {
      onError?.call('Speech recognition is not available on this device, or permission was denied.');
      return false;
    }
    _sttInitialized = true;

    final lang = languageFromCode(languageCode);
    try {
      await _speech.listen(
        onResult: (result) {
          // Ignore empty final results — these typically mean the
          // engine errored out or heard nothing, not that the farmer
          // actually said nothing.
          if (result.finalResult && result.recognizedWords.trim().isEmpty) {
            onDone();
            return;
          }
          onResult(result.recognizedWords);
          if (result.finalResult) onDone();
        },
        localeId: lang.sttLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
      );
    } catch (e) {
      onError?.call('Could not start listening: $e');
      return false;
    }
    return true;
  }

  Future<void> stopListening() => _speech.stop();
  Future<void> cancelListening() => _speech.cancel();

  Future<void> _ensureTtsConfigured() async {
    if (_ttsConfigured) return;
    // CRITICAL: without this, tts.speak() returns almost immediately
    // instead of waiting for the audio to actually finish playing.
    // That meant the app's "is speaking" state flipped back to false
    // while the voice was still audibly talking — so tapping the
    // speaker button again, or starting to type, had no effect,
    // because the app already (wrongly) believed nothing was playing.
    // With this set, speak() now genuinely blocks until either the
    // audio finishes naturally OR stop() is called, keeping the
    // app's state accurate the whole time.
    await _tts.awaitSpeakCompletion(true);
    _ttsConfigured = true;
  }

  Future<void> speak(String text, {required String languageCode}) async {
    if (text.trim().isEmpty) return;
    await _ensureTtsConfigured();

    final lang = languageFromCode(languageCode);
    try {
      await _tts.setLanguage(lang.ttsLocale);
    } catch (e) {
      // Falls back to whatever language the TTS engine defaults to —
      // some devices don't have every language's voice pack installed.
    }
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text); // now correctly awaits until done or stopped
  }

  Future<void> stopSpeaking() => _tts.stop();

  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}