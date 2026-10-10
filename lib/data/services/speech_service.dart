import 'package:speech_to_text/speech_to_text.dart';

abstract interface class SpeechService {
  Future<bool> initialize({
    void Function(String error)? onError,
    void Function(String status)? onStatus,
  });
  Future<void> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String error) onError,
  });
  Future<void> stop();
}

class DeviceSpeechService implements SpeechService {
  DeviceSpeechService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  void Function(String error)? _onError;
  void Function(String status)? _onStatus;

  @override
  Future<bool> initialize({
    void Function(String error)? onError,
    void Function(String status)? onStatus,
  }) async {
    if (onError != null) _onError = onError;
    if (onStatus != null) _onStatus = onStatus;
    if (_initialized) return _speech.isAvailable;
    _initialized = await _speech.initialize(
      onError: (error) => _onError?.call(error.errorMsg),
      onStatus: (status) => _onStatus?.call(status),
    );
    return _initialized;
  }

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String error) onError,
  }) async {
    _onError = onError;
    final available = await initialize();
    if (!available) {
      onError('unavailable');
      return;
    }
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: localeId, onDevice: false),
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
    );
  }

  @override
  Future<void> stop() => _speech.stop();
}
