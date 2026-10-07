import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract interface class OcrService {
  Future<String> recognizeFile(String path);
  Future<void> close();
}

OcrService createOcrService() =>
    kIsWeb ? const WebUnavailableOcrService() : LatinOcrService();

class WebUnavailableOcrService implements OcrService {
  const WebUnavailableOcrService();

  @override
  Future<String> recognizeFile(String path) {
    throw UnsupportedError('OCR is available in the Android app only.');
  }

  @override
  Future<void> close() async {}
}

class LatinOcrService implements OcrService {
  LatinOcrService({TextRecognizer? recognizer})
      : _recognizer = recognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<String> recognizeFile(String path) async {
    final image = InputImage.fromFilePath(path);
    final result = await _recognizer.processImage(image);
    return result.text;
  }

  @override
  Future<void> close() => _recognizer.close();
}
