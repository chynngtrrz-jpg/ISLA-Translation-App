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
    final avatarDiameter = Responsive.space(context, 48);
    final avatarImageSize = avatarDiameter * 0.82;
    final avatarCacheSize =
        (avatarDiameter * MediaQuery.devicePixelRatioOf(context)).round();
    final wordmarkHeight = Responsive.space(context, 28);
    final wordmarkCacheHeight =
        (wordmarkHeight * MediaQuery.devicePixelRatioOf(context)).round();
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
                  CircleAvatar(
                    radius: avatarDiameter / 2,
                    backgroundColor: AppColors.bisque,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/isla_icon.png',
                        width: avatarImageSize,
                        height: avatarImageSize,
                        cacheWidth: avatarCacheSize,
                        cacheHeight: avatarCacheSize,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        semanticLabel: 'ISLA mascot',
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, 12)),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            'assets/images/isla_wordmark.png',
                            height: wordmarkHeight,
                            cacheHeight: wordmarkCacheHeight,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            filterQuality: FilterQuality.medium,
                            semanticLabel: 'ISLA',
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: Responsive.space(context, 4)),
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
