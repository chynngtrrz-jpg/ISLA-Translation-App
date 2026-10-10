import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation;

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/ocr_service.dart';

/// Camera preview and still-image OCR controls for Camera mode.
class CameraInputPanel extends StatelessWidget {
  const CameraInputPanel({
    required this.controller,
    required this.loading,
    required this.processing,
    required this.errorText,
    required this.permissionPermanentlyDenied,
    required this.imagePath,
    required this.imageSize,
    required this.lines,
    required this.selectedLineIds,
    required this.onSelectLine,
    required this.onCapture,
    required this.onGallery,
    required this.onRetake,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onOpenSettings,
    super.key,
  });

  final CameraController? controller;
  final bool loading;
  final bool processing;
  final String? errorText;
  final bool permissionPermanentlyDenied;
  final String? imagePath;
  final Size? imageSize;
  final List<CameraOcrLine> lines;
  final Set<String> selectedLineIds;
  final ValueChanged<CameraOcrLine> onSelectLine;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onRetake;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final ready = controller?.value.isInitialized == true;
    final showingImage = imagePath != null;
    final hasText = lines.isNotEmpty;
    return Column(
      children: [
        SizedBox(height: Responsive.space(context, 12)),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
            child: showingImage
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final size = imageSize ?? Size.zero;
                      final resizeWidth = size.width > size.height &&
                              size.width > 2048
                          ? 2048
                          : null;
                      final resizeHeight = size.height >= size.width &&
                              size.height > 2048
                          ? 2048
                          : null;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: Colors.black,
                            child: imageSize != null &&
                                    (resizeWidth != null ||
                                        resizeHeight != null)
                                ? Image(
                                    image: ResizeImage(
                                      FileImage(File(imagePath!)),
                                      width: resizeWidth,
                                      height: resizeHeight,
                                    ),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildPlaceholder(context),
                                  )
                                : Image(
                                    image: FileImage(File(imagePath!)),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildPlaceholder(context),
                                  ),
                          ),
                          if (!processing && hasText && imageSize != null)
                            LayoutBuilder(
                              builder: (context, overlayConstraints) {
                                final canvasSize = overlayConstraints.biggest;
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CustomPaint(
                                      painter: _TextLinePainter(
                                        lines: lines,
                                        selectedIds: selectedLineIds,
                                        imageSize: size,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapUp: (details) {
                                          final candidates = lines
                                              .map(
                                                (line) => (
                                                  line: line,
                                                  bounds: _mapLineBounds(
                                                    line,
                                                    size,
                                                    canvasSize,
                                                  ),
                                                ),
                                              )
                                              .where(
                                                (candidate) =>
                                                    _hitBounds(candidate.bounds)
                                                        .contains(details
                                                            .localPosition),
                                              )
                                              .toList()
                                            ..sort((a, b) =>
                                                (a.bounds.center -
                                                        details.localPosition)
                                                    .distance
                                                    .compareTo(
                                                  (b.bounds.center -
                                                          details
                                                              .localPosition)
                                                      .distance,
                                                ));
                                          if (candidates.isNotEmpty) {
                                            onSelectLine(candidates.first.line);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          if (processing)
                            ColoredBox(
                              color: Colors.black45,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    SizedBox(
                                      height: Responsive.space(context, 10),
                                    ),
                                    Text(
                                      app.cameraReading,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: Responsive.sp(context, 15),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                : ready
                    ? ValueListenableBuilder<CameraValue>(
                        valueListenable: controller!,
                        builder: (context, value, child) {
                          final previewSize = value.previewSize;
                          if (!value.isInitialized || previewSize == null) {
                            return _buildPlaceholder(context);
                          }
                          final isPortrait =
                              value.deviceOrientation ==
                                      DeviceOrientation.portraitUp ||
                                  value.deviceOrientation ==
                                      DeviceOrientation.portraitDown;
                          return FittedBox(
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: isPortrait
                                  ? previewSize.height
                                  : previewSize.width,
                              height: isPortrait
                                  ? previewSize.width
                                  : previewSize.height,
                              child: CameraPreview(controller!),
                            ),
                          );
                        },
                      )
                    : _buildPlaceholder(context),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.space(context, 10),
          ),
          child: Text(
            showingImage ? app.cameraSelectHint : app.cameraLiveHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.espresso,
              fontSize: Responsive.sp(context, 13),
            ),
          ),
        ),
        if (showingImage && !processing && !hasText)
          Padding(
            padding: EdgeInsets.only(bottom: Responsive.space(context, 8)),
            child: Text(
              app.cameraNoText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.espresso,
                fontSize: Responsive.sp(context, 14),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (errorText != null && !showingImage)
          Padding(
            padding: EdgeInsets.only(bottom: Responsive.space(context, 8)),
            child: Column(
              children: [
                Text(
                  errorText!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.espresso,
                    fontSize: Responsive.sp(context, 14),
                  ),
                ),
                if (permissionPermanentlyDenied)
                  TextButton(
                    onPressed: onOpenSettings,
                    child: Text(app.permissionOpenSettings),
                  ),
              ],
            ),
          ),
        if (showingImage)
          LayoutBuilder(
            builder: (context, constraints) {
              final buttons = [
                _CameraButton(
                  label: app.cameraRetake,
                  color: AppColors.glacier,
                  onPressed: processing ? null : onRetake,
                ),
                _CameraButton(
                  label: app.cameraSelectAll,
                  color: AppColors.chambray,
                  onPressed:
                      processing || !hasText ? null : onSelectAll,
                ),
                _CameraButton(
                  label: app.cameraClearSelection,
                  color: AppColors.glacier,
                  onPressed: processing || selectedLineIds.isEmpty
                      ? null
                      : onClearSelection,
                ),
              ];
              return _buttonLayout(constraints.maxWidth, buttons);
            },
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final buttons = [
                _CameraButton(
                  label: app.cameraCapture,
                  color: AppColors.chambray,
                  onPressed: ready && !loading ? onCapture : null,
                ),
                _CameraButton(
                  label: app.cameraGallery,
                  color: AppColors.glacier,
                  onPressed: loading ? null : onGallery,
                ),
              ];
              return _buttonLayout(constraints.maxWidth, buttons);
            },
          ),
      ],
    );
  }

  Widget _buttonLayout(double width, List<Widget> buttons) {
    final gap = _spaceForWidth(width, 8);
    if (width < 360 || buttons.length == 3) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: gap,
        runSpacing: gap,
        children: buttons
            .map(
              (button) => SizedBox(
                width: (width - gap * (buttons.length - 1)) / buttons.length,
                child: button,
              ),
            )
            .toList(),
      );
    }
    return Row(
      children: [
        Expanded(child: buttons[0]),
        SizedBox(width: gap),
        Expanded(child: buttons[1]),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) => CustomPaint(
        painter: _DashedPlaceholderPainter(
          scale: Responsive.scale(context),
        ),
        child: Container(
          color: AppColors.bisque,
          alignment: Alignment.center,
          child: Icon(
            loading ? Icons.hourglass_top : Icons.photo_camera,
            size: Responsive.sp(context, 36),
            color: AppColors.clay,
          ),
        ),
      );
}

double _spaceForWidth(double width, double value) =>
    (width / Responsive.referenceWidth).clamp(0.85, 1.6) * value;

Rect _mapLineBounds(CameraOcrLine line, Size imageSize, Size canvasSize) {
  final points = _linePoints(line);
  final mapped = points.map((point) => _mapPoint(point, imageSize, canvasSize));
  return mapped.fold<Rect>(
    Rect.fromPoints(mapped.first, mapped.first),
    (bounds, point) => bounds.expandToInclude(point & Size.zero),
  );
}

List<Offset> _linePoints(CameraOcrLine line) {
  if (line.cornerPoints.length >= 4) return line.cornerPoints;
  final rect = line.boundingBox;
  return [
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ];
}

Offset _mapPoint(Offset point, Size imageSize, Size canvasSize) {
  final scale = math.min(
    canvasSize.width / imageSize.width,
    canvasSize.height / imageSize.height,
  );
  final offset = Offset(
    (canvasSize.width - imageSize.width * scale) / 2,
    (canvasSize.height - imageSize.height * scale) / 2,
  );
  return point * scale + offset;
}

Rect _hitBounds(Rect bounds) {
  final hitBounds = Rect.fromCenter(
    center: bounds.center,
    width: math.max(bounds.width, 24),
    height: math.max(bounds.height, 24),
  );
  return hitBounds.inflate(8);
}

class _TextLinePainter extends CustomPainter {
  const _TextLinePainter({
    required this.lines,
    required this.selectedIds,
    required this.imageSize,
  });

  final List<CameraOcrLine> lines;
  final Set<String> selectedIds;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final points = _linePoints(line)
          .map((point) => _mapPoint(point, imageSize, size))
          .toList(growable: false);
      final bounds = points.fold<Rect>(
        Rect.fromPoints(points.first, points.first),
        (rect, point) => rect.expandToInclude(point & Size.zero),
      );
      final isRotated = points.length >= 4 &&
          ((points[0].dy - points[1].dy).abs() > 2 ||
              (points[0].dx - points[3].dx).abs() > 2);
      final path = isRotated
          ? (Path()..addPolygon(points, true))
          : (Path()
            ..addRRect(
              RRect.fromRectAndRadius(bounds, const Radius.circular(4)),
            ));
      final selected = selectedIds.contains(line.id);
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.chambray.withValues(
            alpha: selected ? 0.35 : 0.12,
          ),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.chambray
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 3 : 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TextLinePainter oldDelegate) =>
      oldDelegate.lines != lines ||
      oldDelegate.selectedIds != selectedIds ||
      oldDelegate.imageSize != imageSize;
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: Responsive.space(context, 48),
        child: Material(
          color: onPressed == null
              ? color.withValues(alpha: 0.45)
              : color,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, 4),
                ),
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.espresso,
                    fontSize: Responsive.sp(context, 13),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _DashedPlaceholderPainter extends CustomPainter {
  _DashedPlaceholderPainter({required this.scale});

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.clay
      ..strokeWidth = 2 * scale
      ..style = PaintingStyle.stroke;
    final dash = 8 * scale;
    final gap = 5 * scale;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(20 * scale),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPlaceholderPainter oldDelegate) =>
      oldDelegate.scale != scale;
}
