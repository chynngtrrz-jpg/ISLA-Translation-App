import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Shared editable field for typed text, voice transcription, and OCR.
class MessageField extends StatelessWidget {
  const MessageField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 3,
      maxLines: 6,
      maxLength: kMaxChars,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      autocorrect: true,
      enableSuggestions: true,
      inputFormatters: [LengthLimitingTextInputFormatter(kMaxChars)],
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: TextStyle(
        color: AppColors.espresso,
        fontSize: Responsive.sp(context, 18),
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: app.inputHint,
        hintStyle: const TextStyle(color: AppColors.clay),
        filled: true,
        fillColor: AppColors.canvas,
        counterText: '',
        contentPadding:
            EdgeInsets.symmetric(
              horizontal: Responsive.space(context, 16),
              vertical: Responsive.space(context, 14),
            ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
          borderSide: BorderSide(
            color: AppColors.chambray,
            width: Responsive.space(context, 2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.space(context, 20)),
          borderSide: BorderSide(
            color: AppColors.espresso,
            width: Responsive.space(context, 2),
          ),
        ),
      ),
    );
  }
}
