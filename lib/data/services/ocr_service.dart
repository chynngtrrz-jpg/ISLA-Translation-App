import 'dart:io';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as image;

abstract interface class OcrService {
  Future<CameraOcrResult> recognizeImage(
    String path, {
    required ValueChanged<NormalizedCameraImage> onImageNormalized,
  });
  Future<void> close();
}

class NormalizedCameraImage {
  const NormalizedCameraImage({
    required this.path,
    required this.size,
  });

  final String path;
  final Size size;
}

class CameraOcrLine {
  const CameraOcrLine({
    required this.id,
    required this.text,
    required this.blockIndex,
    required this.boundingBox,
    required this.cornerPoints,
  });

  final String id;
  final String text;
  final int blockIndex;
  final Rect boundingBox;
  final List<Offset> cornerPoints;
}

class CameraOcrResult {
  const CameraOcrResult({
    required this.lines,
  });

  final List<CameraOcrLine> lines;
}

String assembleSelectedCameraText(
  List<CameraOcrLine> lines,
  Set<String> selectedIds,
) {
  final blocks = <int, List<CameraOcrLine>>{};
  for (final line in lines) {
    if (selectedIds.contains(line.id)) {
      blocks.putIfAbsent(line.blockIndex, () => []).add(line);
    }
  }
  final orderedBlocks = blocks.values.toList();
  for (final block in orderedBlocks) {
    block.sort((a, b) {
      final topOrder = a.boundingBox.top.compareTo(b.boundingBox.top);
      return topOrder != 0
          ? topOrder
          : a.boundingBox.left.compareTo(b.boundingBox.left);
    });
  }
  orderedBlocks.sort((a, b) {
    final topOrder = a.first.boundingBox.top.compareTo(b.first.boundingBox.top);
    return topOrder != 0
        ? topOrder
        : a.first.boundingBox.left.compareTo(b.first.boundingBox.left);
  });
  return orderedBlocks
      .map((block) => block.map((line) => line.text.trim()).join(' '))
      .join('\n');
}

OcrService createOcrService() =>
    kIsWeb ? const WebUnavailableOcrService() : LatinOcrService();

class WebUnavailableOcrService implements OcrService {
  const WebUnavailableOcrService();

  @override
  Future<CameraOcrResult> recognizeImage(
    String path, {
    required ValueChanged<NormalizedCameraImage> onImageNormalized,
  }) {
    throw UnsupportedError('OCR is available in the Android app only.');
  }

  @override
  Future<void> close() async {}
}

class LatinOcrService implements OcrService {
  LatinOcrService({TextRecognizer? recognizer})
      : _recognizer =
            recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<CameraOcrResult> recognizeImage(
    String path, {
    required ValueChanged<NormalizedCameraImage> onImageNormalized,
  }) async {
    final normalized = await compute(
      _normalizeImageBytes,
      await File(path).readAsBytes(),
    );
    final normalizedBytes = normalized['bytes']! as Uint8List;
    final normalizedPath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'isla-camera-${DateTime.now().microsecondsSinceEpoch}.jpg';
    final normalizedFile = File(normalizedPath);
    await normalizedFile.writeAsBytes(normalizedBytes);
    final imageSize = Size(
      (normalized['width']! as int).toDouble(),
      (normalized['height']! as int).toDouble(),
    );
    onImageNormalized(
      NormalizedCameraImage(
        path: normalizedPath,
        size: imageSize,
      ),
    );
    final recognized = await _recognizer.processImage(
      InputImage.fromFilePath(normalizedPath),
    );
    final lines = <CameraOcrLine>[];
    for (var blockIndex = 0;
        blockIndex < recognized.blocks.length;
        blockIndex++) {
      final block = recognized.blocks[blockIndex];
      for (var lineIndex = 0; lineIndex < block.lines.length; lineIndex++) {
        final line = block.lines[lineIndex];
        lines.add(
          CameraOcrLine(
            id: '$blockIndex-$lineIndex',
            text: line.text,
            blockIndex: blockIndex,
            boundingBox: line.boundingBox,
            cornerPoints: line.cornerPoints
                .map((point) => Offset(point.x.toDouble(), point.y.toDouble()))
                .toList(growable: false),
          ),
        );
      }
    }
    return CameraOcrResult(lines: lines);
  }

  @override
  Future<void> close() => _recognizer.close();
}

Map<String, Object> _normalizeImageBytes(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image.');
  final oriented = image.bakeOrientation(decoded);
  return {
    'bytes': image.encodeJpg(oriented),
    'width': oriented.width,
    'height': oriented.height,
  };
}
