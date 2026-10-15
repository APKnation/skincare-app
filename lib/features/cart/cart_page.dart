import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../widgets/advanced_card.dart';
import '../../widgets/customer_support_icon.dart';
import '../../widgets/product_image.dart';
import '../product/product_details_page.dart';
import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  final Store store;

  const CartPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _view(context),
    );
  }

  Widget _view(BuildContext context) {
    final items = store.cart;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Cart'),
            Text(
              items.isEmpty
                  ? 'No items yet'
                  : '${items.length} product(s) · ${store.cartCount} unit(s)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Cart',
            onPressed: () => store.refreshCart(),
          ),
        ],
      ),
      floatingActionButton: const CustomerSupportIcon(),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_bag_outlined,
                          size: 56, color: scheme.primary),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Your cart is empty',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add certified skincare & beauty products from the Shop tab.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        // Pop or return to root
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Continue Shopping'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => store.refreshCart(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final p = store.productInCart(item);
                  if (p == null) return const SizedBox.shrink();

                  final itemSubtotal = p.priceTZS * item.quantity;

                  return AdvancedCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsPage(store: store, product: p),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 68,
                            height: 68,
                            child: ProductImage(product: p, height: 68),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.brand.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${formatTZS(p.priceTZS)} each',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Subtotal and Stepper Row
                              Row(
                                children: [
                                  Text(
                                    formatTZS(itemSubtotal),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const Spacer(),

                                  // Stepper controls
                                  Container(
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          iconSize: 18,
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                              minWidth: 32, minHeight: 32),
                                          icon: Icon(
                                            item.quantity == 1
                                                ? Icons.delete_outline
                                                : Icons.remove,
                                            color: item.quantity == 1
                                                ? scheme.error
                                                : scheme.onSurface,
                                          ),
                                          tooltip: 'Decrease quantity',
                                          onPressed: () => store.setCartQuantity(
                                              p.id, item.quantity - 1),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          iconSize: 18,
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                              minWidth: 32, minHeight: 32),
                                          icon: const Icon(Icons.add),
                                          tooltip: 'Increase quantity',
                                          onPressed: () => store.setCartQuantity(
                                              p.id, item.quantity + 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

      // Bottom Checkout Bar
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
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
                    // Subtotal
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cart Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            formatTZS(store.cartSubtotal),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Direct Checkout Button
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CheckoutPage(store: store),
                            ),
                          ),
                          icon: const Icon(Icons.lock_outline, size: 18),
                          label: const Text(
                            'Checkout',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
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
  }
}
