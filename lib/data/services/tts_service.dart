import 'package:flutter_tts/flutter_tts.dart';

abstract interface class TtsService {
  Future<bool> isLanguageAvailable(String locale);
  Future<void> speak(String text, String locale);
  Future<void> stop();
}

class DeviceTtsService implements TtsService {
  DeviceTtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<bool> isLanguageAvailable(String locale) async =>
      await _tts.isLanguageAvailable(locale) == true;

  @override
  Future<void> speak(String text, String locale) async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
