import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/product.dart';
import '../../widgets/customer_support_icon.dart';
import '../../widgets/zoomable_image.dart';
import '../cart/cart_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Store store;
  final Product product;

  const ProductDetailsPage({
    super.key,
    required this.store,
    required this.product,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isAdding = false;

  int _cartQty(Store store, String productId) {
    for (final item in store.cart) {
      if (item.productId == productId) {
        return item.quantity;
      }
    }
    return 0;
  }

  Future<void> _addToCart(Product live) async {
    if (live.stock <= 0 || _isAdding) return;

    setState(() => _isAdding = true);
    final error = await widget.store.addToCart(live.id);
    if (!mounted) return;
    setState(() => _isAdding = false);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
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
                error ?? '${live.name} added to cart',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: const Color(0xFF6EE7B7),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CartPage(store: widget.store),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final live = widget.store.productById(widget.product.id) ?? widget.product;
        final inCart = _cartQty(widget.store, live.id);
        final isOutOfStock = live.stock <= 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(live.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'View Cart',
                icon: Badge(
                  isLabelVisible: widget.store.cartCount > 0,
                  backgroundColor: scheme.error,
                  label: Text(
                    '${widget.store.cartCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CartPage(store: widget.store)),
                ),
              ),
            ],
          ),
          floatingActionButton: const CustomerSupportIcon(),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Hero(
                tag: 'product-${live.id}',
                child: ZoomableImage(imageUrl: live.imageUrl, height: 240),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          live.brand.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          live.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatTZS(live.priceTZS),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Shop & location tag
              Row(
                children: [
                  Icon(Icons.storefront_outlined,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${live.shopName} · ${live.shopLocation}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOutOfStock
                            ? Colors.red.shade300
                            : Colors.green.shade300,
                      ),
                    ),
                    child: Text(
                      isOutOfStock ? 'Out of stock' : '${live.stock} in stock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOutOfStock
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Description
              _section(context, 'Description', Text(live.description)),

              // Ingredients
              _section(
                context,
                'Ingredients',
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    live.ingredients.join(', '),
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ),

              // Usage
              _section(context, 'How to Use', Text(live.usageInstructions)),

              // Side effects
              if (live.sideEffects.isNotEmpty)
                _section(
                  context,
                  'Possible Side Effects',
                  _bullets(context, live.sideEffects),
                ),

              // Warnings
              if (live.warnings.isNotEmpty)
                _section(
                  context,
                  'Safety Warnings',
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: _bullets(context, live.warnings),
                  ),
                ),
            ],
          ),

          // High-visibility, prominent Bottom Add-to-Cart Bar
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Price and Cart Status
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatTZS(live.priceTZS),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                        if (inCart > 0)
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 13, color: Colors.green.shade700),
                              const SizedBox(width: 3),
                              Text(
                                '$inCart in your cart',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Tax & delivery calculated at checkout',
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Prominent Add to Cart Button
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: isOutOfStock
                              ? scheme.surfaceContainerHigh
                              : scheme.primary,
                          foregroundColor:
                              isOutOfStock ? scheme.onSurfaceVariant : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: isOutOfStock ? 0 : 2,
                        ),
                        onPressed: isOutOfStock || _isAdding
                            ? null
                            : () => _addToCart(live),
                        icon: _isAdding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                inCart > 0
                                    ? Icons.add_shopping_cart
                                    : Icons.shopping_bag_outlined,
                                size: 19,
                              ),
                        label: Text(
                          isOutOfStock
                              ? 'Out of Stock'
                              : (inCart > 0 ? 'Add Another ($inCart)' : 'Add to Cart'),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _section(BuildContext context, String title, Widget body) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            body,
          ],
        ),
      );

  Widget _bullets(BuildContext context, List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
        ],
      );
}
