import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/localization/isla_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Non-interactive, accessible progress indicator for the three app steps.
class StepIndicator extends StatelessWidget {
  const StepIndicator({required this.currentStep, super.key});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final labels = [
      context.t(L10nKeys.stepChooseLanguages),
      context.t(L10nKeys.stepInputTranslate),
      context.t(L10nKeys.stepViewResult),
    ];
    Widget buildStep(int index) {
      final step = index + 1;
      final completed = step < currentStep;
      final current = step == currentStep;
      final semanticKey = completed
          ? L10nKeys.stepSemanticsCompleted
          : current
              ? L10nKeys.stepSemanticsCurrent
              : L10nKeys.stepSemanticsUpcoming;
      return Expanded(
        child: Semantics(
          container: true,
          label: context.t(
            semanticKey,
            args: {
              'n': '$step',
              'total': '${translationStepLabels.length}',
              'label': labels[index],
            },
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
                          color: current
                              ? AppColors.glacier
                              : AppColors.espresso,
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
              Positioned(
                left: constraints.maxWidth / 6,
                right: constraints.maxWidth / 6,
                top: Responsive.space(context, 15),
                child: Container(
                  height: Responsive.space(context, 2),
                  color: AppColors.clay,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0;
                      index < translationStepLabels.length;
                      index++)
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
