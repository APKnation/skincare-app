import 'package:flutter/material.dart';

class ZoomableImage extends StatefulWidget {
  final String? imageUrl;
  final Widget? placeholder;
  final double height;
  final BoxFit fit;

  const ZoomableImage({
    super.key,
    this.imageUrl,
    this.placeholder,
    this.height = 220,
    this.fit = BoxFit.cover,
  });

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _tapDownDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
    } else {
      final position = _tapDownDetails!.localPosition;
      _controller.value = Matrix4.identity()
        ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0, 1)
        ..scaleByDouble(2.0, 2.0, 2.0, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.imageUrl != null
        ? Image.network(
            widget.imageUrl!,
            height: widget.height,
            fit: widget.fit,
        errorBuilder: (_, _, _) =>
            widget.placeholder ?? const SizedBox.shrink(),
          )
        : (widget.placeholder ?? const SizedBox.shrink());

    return GestureDetector(
      onDoubleTapDown: (details) => _tapDownDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1.0,
        maxScale: 4.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: child,
        ),
      ),
    );
  }
}
