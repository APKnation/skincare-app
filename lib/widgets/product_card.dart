import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../data/store.dart';
import '../models/enums.dart';
import '../models/product.dart';
import 'product_image.dart';

/// An advanced, luxury e-commerce product card featuring micro-animations,
/// verified quality badges, skin concern tags, and quick-add action.
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final bool selectedForCompare;
  final VoidCallback? onToggleCompare;
  final Store? store;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.selectedForCompare = false,
    this.onToggleCompare,
    this.store,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isPressed = false;
  bool _isAdding = false;

  int _cartQty(Store? store) {
    if (store == null) return 0;
    for (final item in store.cart) {
      if (item.productId == widget.product.id) {
        return item.quantity;
      }
    }
    return 0;
  }

  Future<void> _handleQuickAdd(BuildContext context) async {
    final store = widget.store;
    if (store == null || widget.product.stock <= 0 || _isAdding) return;

    setState(() => _isAdding = true);
    final error = await store.addToCart(widget.product.id);
    if (!context.mounted) return;
    setState(() => _isAdding = false);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(
              error == null ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error ?? '${widget.product.name} added to cart',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inCart = _cartQty(widget.store);
    final isOutOfStock = widget.product.stock <= 0;
    final isLowStock = widget.product.stock > 0 && widget.product.stock <= 3;

    // Pick first concern or skin type tag
    final concernTag = widget.product.targetsConcerns.isNotEmpty
        ? widget.product.targetsConcerns.first.label
        : (widget.product.suitableSkinTypes.isNotEmpty
            ? widget.product.suitableSkinTypes.first.label
            : null);

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.selectedForCompare
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.5),
            width: widget.selectedForCompare ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.selectedForCompare
                  ? scheme.primary.withValues(alpha: 0.15)
                  : scheme.shadow.withValues(alpha: 0.05),
              blurRadius: widget.selectedForCompare ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) {
                if (mounted) setState(() => _isPressed = v);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image & Badges
                  Expanded(
                    flex: 11,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'product-${widget.product.id}',
                          child: ProductImage(product: widget.product),
                        ),

                        // Top Gradient Overlay for badges contrast
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.35),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // TBS/TFDA Safe badge
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 11,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'TBS Safe',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Floating Compare button
                        if (widget.onToggleCompare != null)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.onToggleCompare,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: widget.selectedForCompare
                                        ? scheme.primary
                                        : scheme.surface.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.selectedForCompare
                                            ? Icons.check
                                            : Icons.compare_arrows_rounded,
                                        size: 12,
                                        color: widget.selectedForCompare
                                            ? scheme.onPrimary
                                            : scheme.onSurface,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Compare',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: widget.selectedForCompare
                                              ? scheme.onPrimary
                                              : scheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Low stock warning pill
                        if (isLowStock)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Only ${widget.product.stock} left',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        // Out of stock overlay
                        if (isOutOfStock)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.white24, width: 1),
                                  ),
                                  child: const Text(
                                    'Out of stock',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Details Body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand and Skin Concern Row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.product.brand.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                            if (concernTag != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  concernTag,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Product Name
                        Text(
                          widget.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),

                        // Shop name & city
                        Row(
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 12, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                widget.product.shopName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Price and Quick Add Button Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatTZS(widget.product.priceTZS),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.primary,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quick Add Button
                            if (widget.store != null)
                              SizedBox(
                                width: 34,
                                height: 34,
                                child: IconButton.filled(
                                  padding: EdgeInsets.zero,
                                  style: IconButton.styleFrom(
                                    backgroundColor: inCart > 0
                                        ? scheme.primary
                                        : scheme.primaryContainer,
                                    foregroundColor: inCart > 0
                                        ? scheme.onPrimary
                                        : scheme.onPrimaryContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: _isAdding
                                      ? SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: inCart > 0
                                                ? scheme.onPrimary
                                                : scheme.primary,
                                          ),
                                        )
                                      : inCart > 0
                                          ? Text(
                                              '$inCart',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            )
                                          : const Icon(Icons.add, size: 18),
                                  tooltip: inCart > 0
                                      ? '$inCart in cart — add more'
                                      : 'Add to cart',
                                  onPressed: isOutOfStock
                                      ? null
                                      : () => _handleQuickAdd(context),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
