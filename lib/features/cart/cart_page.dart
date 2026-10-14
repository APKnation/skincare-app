import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../product/product_details_page.dart';
import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  final Store store;

  const CartPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final items = store.cart;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Cart'),
            Text(
              items.isEmpty
                  ? 'No items yet'
                  : '${items.length} item(s) · ${formatTZS(store.cartSubtotal)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primaryContainer),
                  const SizedBox(height: 12),
                  Text('Your cart is empty',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Browse the Shop tab and tap a product to add it.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = items[i];
                final p = store.productInCart(item);
                if (p == null) return const SizedBox.shrink();
                return ListTile(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailsPage(store: store, product: p))),
                  title: Text(p.name, maxLines: 2),
                  subtitle: Text(formatTZS(p.priceTZS)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () =>
                            store.setCartQuantity(p.id, item.quantity - 1),
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () =>
                            store.setCartQuantity(p.id, item.quantity + 1),
                      ),                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Subtotal',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(formatTZS(store.cartSubtotal),
                              style:
                                  Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  CheckoutPage(store: store))),
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
