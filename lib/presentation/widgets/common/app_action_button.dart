import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Reusable amber action button with full state handling.
///
/// Five interaction states are wired up so the same widget works across
/// mobile (touch) and web/desktop (mouse + keyboard):
///
/// * **default**  — idle (no interaction)
/// * **hovered**  — mouse pointer over the button (web / desktop)
/// * **focused**  — keyboard focus (Tab key) — visible focus ring
/// * **pressed**  — finger / mouse down — darker amber + scale-down
/// * **disabled** — `onPressed: null` — gray fill + forbidden cursor
///
/// Mobile devices won't fire `hovered` / `focused`, so the widget
/// gracefully degrades to default → pressed → default.
///
/// Use this in place of raw `GestureDetector + Container` for any custom
/// action button (Pay Now, Sign In, Switch, Continue, etc.) so the state
/// behavior stays consistent across the app.
///
/// Example:
/// ```dart
/// AppActionButton(
///   onPressed: _handleSubmit,
///   label: 'Sign In',
///   trailingIcon: 'arrow-right-1',
/// )
/// ```
enum AppActionButtonVariant {
  /// Solid amber fill + white text — for primary actions (Pay, Sign In, etc).
  filled,

  /// White fill + colored 1.5px border + colored label — for secondary
  /// actions (Create Account, Get Support, Sign Out).
  outlined,
}

class AppActionButton extends StatefulWidget {
  /// Tap callback. Pass `null` to render the disabled state.
  final VoidCallback? onPressed;

  /// Button text label.
  final String label;

  /// Optional leading widget (icon / loader) before [label].
  final Widget? leading;

  /// Optional trailing widget after [label].
  final Widget? trailing;

  /// Visual style. Default [AppActionButtonVariant.filled].
  final AppActionButtonVariant variant;

  /// Idle fill (filled) or border + label (outlined) color.
  /// Defaults to `AppColors.buttonPrimary` (amber).
  final Color? backgroundColor;

  /// Color when hovered / pressed / focused. Defaults to
  /// `AppColors.buttonPrimaryHover` (darker amber).
  final Color? activeColor;

  /// Foreground (text + icons) color. For filled, defaults to white. For
  /// outlined, defaults to [backgroundColor] (so border + label match).
  final Color? foregroundColor;

  /// Border radius. Defaults to 14.
  final double borderRadius;

  /// Vertical padding. Defaults to 16.
  final double verticalPadding;

  /// Horizontal padding. Defaults to 24.
  final double horizontalPadding;

  /// Whether the button should fill its parent's width. Default `true`.
  final bool fullWidth;

  /// Whether to render the amber drop-shadow glow underneath. Default `true`
  /// (only applies to the filled variant).
  final bool showShadow;

  /// Text style override for [label].
  final TextStyle? textStyle;

  const AppActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.leading,
    this.trailing,
    this.variant = AppActionButtonVariant.filled,
    this.backgroundColor,
    this.activeColor,
    this.foregroundColor,
    this.borderRadius = 14,
    this.verticalPadding = 16,
    this.horizontalPadding = 24,
    this.fullWidth = true,
    this.showShadow = true,
    this.textStyle,
  });

  @override
  State<AppActionButton> createState() => _AppActionButtonState();
}

class _AppActionButtonState extends State<AppActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null;

  bool get _isOutlined =>
      widget.variant == AppActionButtonVariant.outlined;

  Color get _baseColor =>
      widget.backgroundColor ?? AppColors.buttonPrimary;

  Color get _activeColor =>
      widget.activeColor ?? AppColors.buttonPrimaryHover;

  Color get _fg {
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    return _isOutlined ? _baseColor : Colors.white;
  }

  /// Filled background — resolved based on state.
  Color _resolveFilledBg() {
    if (!_enabled) return AppColors.gray300;
    if (_pressed || _hovered || _focused) return _activeColor;
    return _baseColor;
  }

  /// Outlined background — transparent by default, tinted on hover/press.
  Color _resolveOutlinedBg() {
    if (!_enabled) return Colors.transparent;
    if (_pressed) return _baseColor.withValues(alpha: 0.12);
    if (_hovered) return _baseColor.withValues(alpha: 0.08);
    if (_focused) return _baseColor.withValues(alpha: 0.06);
    return Colors.transparent;
  }

  /// Outlined border — colored at idle, darker amber on press, gray when disabled.
  Color _resolveOutlinedBorder() {
    if (!_enabled) return AppColors.gray300;
    if (_pressed) return _activeColor;
    if (_hovered) return _activeColor;
    return _baseColor;
  }

  MouseCursor get _cursor =>
      _enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden;

  void _setHover(bool v) {
    if (_hovered != v) setState(() => _hovered = v);
  }

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _setFocus(bool v) {
    if (_focused != v) setState(() => _focused = v);
  }

  @override
  Widget build(BuildContext context) {
    final Color fill =
        _isOutlined ? _resolveOutlinedBg() : _resolveFilledBg();
    // Outlined disabled keeps idle color but at lower opacity; filled disabled
    // uses white-on-gray.
    final Color fgColor;
    if (!_enabled) {
      fgColor =
          _isOutlined ? AppColors.gray400 : _fg.withValues(alpha: 0.7);
    } else if (_isOutlined && (_pressed || _hovered)) {
      fgColor = _activeColor;
    } else {
      fgColor = _fg;
    }

    final Border? border;
    if (_isOutlined) {
      border = Border.all(color: _resolveOutlinedBorder(), width: 1.5);
    } else if (_focused && _enabled) {
      border = Border.all(
        color: Colors.white.withValues(alpha: 0.6),
        width: 2,
      );
    } else {
      border = null;
    }

    return MouseRegion(
      cursor: _cursor,
      onEnter: (_) => _setHover(true),
      onExit: (_) {
        _setHover(false);
        _setPressed(false);
      },
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: _setFocus,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: _enabled
              ? () {
                  // OS-native click sound + light haptic (mobile only)
                  SystemSound.play(SystemSoundType.click);
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                }
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.fullWidth ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: widget.horizontalPadding,
                vertical: widget.verticalPadding,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: border,
                // Shadow only on FILLED amber buttons; outlined buttons stay
                // flat (no shadow). Removed entirely when pressed so the
                // shrink reads as "press into surface".
                boxShadow: (widget.showShadow &&
                        _enabled &&
                        !_isOutlined &&
                        !_pressed)
                    ? [
                        BoxShadow(
                          color: _baseColor
                              .withValues(alpha: _hovered ? 0.45 : 0.35),
                          blurRadius: _hovered ? 18 : 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (widget.leading != null) ...[
                    IconTheme(
                      data: IconThemeData(color: fgColor, size: 20),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: fgColor),
                        child: widget.leading!,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: (widget.textStyle ??
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ))
                        .copyWith(color: fgColor),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 10),
                    IconTheme(
                      data: IconThemeData(color: fgColor, size: 20),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: fgColor),
                        child: widget.trailing!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
