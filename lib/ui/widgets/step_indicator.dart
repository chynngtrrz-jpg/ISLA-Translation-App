import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Non-interactive, accessible progress indicator for the three app steps.
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    required this.currentStep,
    this.hasTranslationResult = false,
    super.key,
  });

  final int currentStep;
  final bool hasTranslationResult;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final labels = [
      app.stepChooseLanguages,
      app.stepInputTranslate,
      app.stepViewResult,
    ];
    final lastStep = labels.length;
    Widget buildStep(int index) {
      final step = index + 1;
      final completed = step < currentStep ||
          (step == lastStep && hasTranslationResult);
      final current = step == currentStep && !completed;
      return Expanded(
        child: Semantics(
          container: true,
          label: completed
              ? app.stepSemanticsCompleted(
                  '$step',
                  '$lastStep',
                  labels[index],
                )
              : current
                  ? app.stepSemanticsCurrent(
                      '$step',
                      '$lastStep',
                      labels[index],
                    )
                  : app.stepSemanticsUpcoming(
                      '$step',
                      '$lastStep',
                      labels[index],
                    ),
          child: Column(
            children: [
              Container(
                key: ValueKey('step-circle-$step'),
                width: Responsive.space(context, 32),
                height: Responsive.space(context, 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: completed
                      ? AppColors.chambray
                      : current
                          ? AppColors.espresso
                          : AppColors.glacier,
                  shape: BoxShape.circle,
                  border: completed || current
                      ? null
                      : Border.all(
                          color: AppColors.clay,
                          width: Responsive.space(context, 2),
                        ),
                ),
                child: completed
                    ? Icon(
                        Icons.check,
                        color: AppColors.espresso,
                        size: Responsive.sp(context, 20),
                      )
                    : Text(
                        '$step',
                        style: TextStyle(
                          color:
                              current ? AppColors.glacier : AppColors.espresso,
                          fontSize: Responsive.sp(context, 14),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              SizedBox(height: Responsive.space(context, 8)),
              AnimatedDefaultTextStyle(
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.espresso,
                  fontSize: Responsive.sp(context, 14),
                  fontWeight: FontWeight.w600,
                ),
                child: Text(labels[index]),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              for (var index = 0; index < labels.length - 1; index++)
                Positioned(
                  left: constraints.maxWidth * (index + 0.5) / labels.length,
                  width: constraints.maxWidth / labels.length,
                  top: Responsive.space(context, 15),
                  child: Container(
                    key: ValueKey('step-connector-${index + 1}'),
                    height: Responsive.space(context, 2),
                    color: index + 1 < currentStep
                        ? AppColors.chambray
                        : AppColors.clay,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < labels.length; index++)
                    buildStep(index),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
