import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import 'desktop_left_panel.dart';

/// Wraps auth screen content with a desktop split-screen layout.
///
/// On desktop (>=1024px): Dark left panel with branding/headline +
///   right panel with the form content (scrollable, 560px max-width).
/// On mobile / narrow screens: Renders child directly.
class AuthDesktopWrapper extends StatelessWidget {
  final Widget child;
  final String headline;
  final String subtitle;
  final Widget? centerContent;
  final VoidCallback? onBack;

  const AuthDesktopWrapper({
    super.key,
    required this.child,
    this.headline = 'Welcome Back',
    this.subtitle = 'Secure & easy school fee payments',
    this.centerContent,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final showSplitScreen = context.isDesktop;

    if (!showSplitScreen) {
      // Mobile or narrow screen — render child directly
      return child;
    }

    return Row(
      children: [
        // Left panel — dark branding
        Expanded(
          flex: 5,
          child: DesktopLeftPanel(
            headline: headline,
            subtitle: subtitle,
            centerContent: centerContent,
          ),
        ),

        // Right panel — form content
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: child,
                ),
              ),
              // Back button at top-left
              if (onBack != null)
                Positioned(
                  top: 24,
                  left: 32,
                  child: TextButton.icon(
                    onPressed: onBack,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.textSecondaryC(context),
                    ),
                    label: Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryC(context),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
