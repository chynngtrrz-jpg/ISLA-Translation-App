import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';

enum ModelStatusChipState { loading, offlineReady }

class ModelStatusChip extends StatelessWidget {
  const ModelStatusChip({required this.status, super.key});

  final ModelStatusChipState status;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final (label, icon) = switch (status) {
      ModelStatusChipState.loading => (
          app.statusModelLoading,
          Icons.hourglass_empty
        ),
      ModelStatusChipState.offlineReady => (
          app.statusOfflineReady,
          Icons.offline_bolt
        ),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        label: label,
        child: ExcludeSemantics(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Responsive.space(context, 6),
            children: [
              Icon(
                icon,
                color: AppColors.clay,
                size: Responsive.sp(context, 16),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.clay,
                  fontSize: Responsive.sp(context, 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
