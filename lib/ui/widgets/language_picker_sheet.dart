import 'package:flutter/material.dart';

import '../../core/constants/languages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Accessible modal picker for a source or target language.
class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({
    required this.title,
    required this.selectedId,
    required this.otherId,
    required this.isPairSupported,
    required this.onSelected,
    super.key,
  });

  final String title;
  final String selectedId;
  final String otherId;
  final bool Function(String, String) isPairSupported;
  final ValueChanged<String> onSelected;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String selectedId,
    required String otherId,
    required bool isSource,
    required bool Function(String, String) isPairSupported,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.space(context, 24)),
        ),
      ),
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SizedBox(
            width: double.infinity,
            child: LanguagePickerSheet(
              title: title,
              selectedId: selectedId,
              otherId: otherId,
              isPairSupported: (source, target) => isSource
                  ? isPairSupported(source, target)
                  : isPairSupported(target, source),
              onSelected: onSelected,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    return IconTheme.merge(
      data: IconThemeData(size: Responsive.sp(context, 24)),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        scopesRoute: true,
        namesRoute: true,
        label: 'dialog',
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.space(context, 20),
              Responsive.space(context, 4),
              Responsive.space(context, 20),
              Responsive.space(context, 20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.espresso,
                    fontSize: Responsive.sp(context, 22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: Responsive.space(context, 12)),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      final isSelected = language.id == selectedId;
                      final isSameAsOther = language.id == otherId;
                      final isSupported = isPairSupported(
                        language.id,
                        otherId,
                      );
                      final isDisabled = isSameAsOther || !isSupported;
                      final reason = isSameAsOther
                          ? 'Already selected'
                          : isDisabled
                              ? 'Not available'
                              : null;

                      return Semantics(
                        enabled: !isDisabled,
                        selected: isSelected,
                        child: ListTile(
                          enabled: !isDisabled,
                          minVerticalPadding: Responsive.space(context, 8),
                          title: Text(
                            language.name,
                            style: TextStyle(
                              color: isDisabled
                                  ? AppColors.clay
                                  : AppColors.espresso,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: reason == null
                              ? null
                              : Text(
                                  reason,
                                  style: const TextStyle(color: AppColors.clay),
                                ),
                          trailing: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isDisabled
                                ? AppColors.clay
                                : AppColors.chambray,
                          ),
                          onTap: isDisabled
                              ? null
                              : () {
                                  onSelected(language.id);
                                  Navigator.pop(context);
                                },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
