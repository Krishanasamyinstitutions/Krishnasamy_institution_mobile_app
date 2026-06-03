import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Circular icon button with full state handling.
///
/// Used for the 44×44 header buttons (back arrow, cart, notification bell) on
/// drill-down pages. Mirrors [AppActionButton] state semantics so the whole
/// app reacts the same way:
///
/// * **default**  — idle (no interaction)
/// * **hovered**  — mouse over (web/desktop) — slight scale-up + darker amber
/// * **focused**  — keyboard focus — white focus ring
/// * **pressed**  — finger/mouse down — scale 0.94 + darker amber
/// * **disabled** — `onPressed: null` — gray fill + forbidden cursor
///
/// Mobile devices won't fire `hovered`/`focused`, so the widget degrades to
/// default → pressed → default.
class AppIconCircleButton extends StatefulWidget {
  /// Tap callback. Pass `null` to render the disabled state.
  final VoidCallback? onPressed;

  /// Icon widget (typically an [AppIcon] or [SvgPicture.asset] with a white
  /// `colorFilter`). Sized 18–22 to look right inside the 44px circle.
  final Widget icon;

  /// Optional badge to overlay top-right (e.g. unread count). `0` hides it.
  final int badgeCount;

  /// Diameter of the circle. Defaults to 44.
  final double size;

  /// Idle background color. Defaults to `AppColors.buttonPrimary` (amber).
  final Color? backgroundColor;

  /// Color when hovered / pressed / focused. Defaults to
  /// `AppColors.buttonPrimaryHover` (darker amber).
  final Color? activeColor;

  /// Whether to render the drop-shadow underneath. Default `true`.
  final bool showShadow;

  const AppIconCircleButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.badgeCount = 0,
    this.size = 44,
    this.backgroundColor,
    this.activeColor,
    this.showShadow = true,
  });

  @override
  State<AppIconCircleButton> createState() => _AppIconCircleButtonState();
}

class _AppIconCircleButtonState extends State<AppIconCircleButton> {
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

  Color get _baseColor =>
      widget.backgroundColor ?? AppColors.buttonPrimary;

  Color get _activeColor =>
      widget.activeColor ?? AppColors.buttonPrimaryHover;

  Color _resolveFill() {
    if (!_enabled) return AppColors.gray300;
    if (_pressed || _hovered || _focused) return _activeColor;
    return _baseColor;
  }

  MouseCursor get _cursor =>
      _enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden;

  @override
  Widget build(BuildContext context) {
    final fill = _resolveFill();

    final Widget core = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: _focused && _enabled
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 2,
              )
            : null,
        // Shadow on idle/hover/focus; removed entirely when pressed
        // (shrinks + flattens for tactile "press into surface" feel).
        boxShadow: (widget.showShadow && _enabled && !_pressed)
            ? [
                BoxShadow(
                  color: const Color(0x26000000),
                  blurRadius: _hovered ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Center(child: widget.icon),
          if (widget.badgeCount > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(3),
                constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return MouseRegion(
      cursor: _cursor,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (v) => setState(() => _focused = v),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              _enabled ? () => setState(() => _pressed = false) : null,
          onTap: _enabled
              ? () {
                  // OS-native click sound + light haptic (mobile only)
                  SystemSound.play(SystemSoundType.click);
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                }
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : (_hovered ? 1.04 : 1.0),
            duration: const Duration(milliseconds: 120),
            child: core,
          ),
        ),
      ),
    );
  }
}
