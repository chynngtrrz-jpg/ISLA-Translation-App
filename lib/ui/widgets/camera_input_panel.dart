import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/localization/isla_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Camera preview and image capture/upload controls for OCR input.
class CameraInputPanel extends StatelessWidget {
  const CameraInputPanel({
    required this.controller,
    required this.loading,
    required this.errorText,
    required this.onCapture,
    required this.onGallery,
    super.key,
  });

  final CameraController? controller;
  final bool loading;
  final String? errorText;
  final VoidCallback onCapture;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final ready = controller?.value.isInitialized == true;
    return Column(
      children: [
        SizedBox(height: Responsive.space(context, 12)),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
            child: ready
                ? CameraPreview(controller!)
                : CustomPaint(
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
                  ),
          ),
        ),
        SizedBox(height: Responsive.space(context, 10)),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(bottom: Responsive.space(context, 8)),
            child: Text(
              errorText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.espresso,
                fontSize: Responsive.sp(context, 14),
              ),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final buttons = [
              _CameraButton(
                label: context.t(L10nKeys.cameraCapture),
                color: AppColors.chambray,
                onPressed: ready && !loading ? onCapture : null,
              ),
              _CameraButton(
                label: context.t(L10nKeys.cameraGallery),
                color: AppColors.glacier,
                onPressed: loading ? null : onGallery,
              ),
            ];
            if (constraints.maxWidth < 320) {
              return Column(
                children: [
                  buttons[0],
                  SizedBox(height: Responsive.space(context, 8)),
                  buttons[1],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: buttons[0]),
                SizedBox(width: Responsive.space(context, 8)),
                Expanded(child: buttons[1]),
              ],
            );
          },
        ),
      ],
    );
  }
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
          color: color,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.espresso,
                  fontSize: Responsive.sp(context, 14),
                  fontWeight: FontWeight.w700,
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
