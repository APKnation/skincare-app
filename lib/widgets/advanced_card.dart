import 'package:flutter/material.dart';

/// An ultra-modern card container featuring smooth micro-scale touch feedback,
/// soft elevation shadows, optional glassmorphism, and gradient border highlights.
class AdvancedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? customShadow;
  final bool hasGlass;
  final Gradient? borderGradient;

  const AdvancedCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor,
    this.customShadow,
    this.hasGlass = false,
    this.borderGradient,
  });

  @override
  State<AdvancedCard> createState() => _AdvancedCardState();
}

class _AdvancedCardState extends State<AdvancedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isInteractive = widget.onTap != null || widget.onLongPress != null;

    final bgColor = widget.backgroundColor ??
        (widget.hasGlass
            ? scheme.surface.withValues(alpha: 0.85)
            : scheme.surface);

    final defaultBorderColor =
        widget.borderColor ?? scheme.outlineVariant.withValues(alpha: 0.55);

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.borderGradient == null
                ? Border.all(color: defaultBorderColor, width: 1.0)
                : null,
            gradient: widget.borderGradient,
            boxShadow: widget.customShadow ??
                [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onHighlightChanged: (pressed) {
                  if (isInteractive && mounted) {
                    setState(() => _isPressed = pressed);
                  }
                },
                splashColor: scheme.primary.withValues(alpha: 0.08),
                highlightColor: scheme.primary.withValues(alpha: 0.04),
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
