import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// ISLA brand bar with status-bar inset, logo placeholder, and wordmark.
class IslaAppBar extends StatelessWidget {
  const IslaAppBar({this.subtitle, this.trailing, super.key});

  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final statusBarInset = MediaQuery.paddingOf(context).top;
    final headerHeight = Responsive.space(context, subtitle == null ? 64 : 96);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.espresso,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        constraints: BoxConstraints(
          minHeight: headerHeight + statusBarInset,
        ),
        color: AppColors.espresso,
        padding: EdgeInsets.only(
          top: statusBarInset,
          left: Responsive.space(context, 20),
          right: Responsive.space(context, 20),
        ),
        child: IconTheme.merge(
          data: IconThemeData(size: Responsive.sp(context, 24)),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/img/logo.png',
                      width: Responsive.space(context, 40),
                      height: Responsive.space(context, 40),
                      fit: BoxFit.cover,
                      // TODO: replace logo
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: Responsive.space(context, 40),
                        height: Responsive.space(context, 40),
                        alignment: Alignment.center,
                        color: AppColors.bisque,
                        child: Text(
                          'I',
                          style: TextStyle(
                            color: AppColors.espresso,
                            fontSize: Responsive.sp(context, 24),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, 12)),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ISLA',
                          style: TextStyle(
                            color: AppColors.bisque,
                            fontSize: Responsive.sp(context, 26),
                            fontWeight: FontWeight.w800,
                            letterSpacing: Responsive.space(context, 4),
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.glacier,
                              fontSize: Responsive.sp(context, 13),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (trailing != null)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailing!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
