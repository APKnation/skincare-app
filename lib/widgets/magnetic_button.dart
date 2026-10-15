import 'package:flutter/material.dart';

class MagneticButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double strength;
  final Duration duration;

  const MagneticButton({
    super.key,
    required this.child,
    this.onPressed,
    this.strength = 0.1,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<MagneticButton> createState() => _MagneticButtonState();
}

class _MagneticButtonState extends State<MagneticButton> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {},
      onHover: (event) {
        final size = context.size ?? Size.zero;
        if (size.isEmpty) return;
        final local = event.localPosition;
        final dx = (local.dx - size.width / 2) * widget.strength;
        final dy = (local.dy - size.height / 2) * widget.strength;
        setState(() => _offset = Offset(dx, dy));
      },
      onExit: (_) => setState(() => _offset = Offset.zero),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _offset = Offset.zero),
        onTapCancel: () => setState(() => _offset = Offset.zero),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
          child: widget.child,
        ),
      ),
    );
  }
}
