import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/product.dart';
import '../../widgets/product_image.dart';

class ProductDetailsPage extends StatelessWidget {
  final Store store;
  final Product product;

  const ProductDetailsPage({
    super.key,
    required this.store,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final live = store.productById(product.id) ?? product;
    return Scaffold(
      appBar: AppBar(title: Text(live.name, maxLines: 1)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ProductImage(product: live, height: 220),
          ),
          const SizedBox(height: 12),
          Text(live.name, style: Theme.of(context).textTheme.titleLarge),
          Text('${live.brand} · sold by ${live.shopName} · ${live.shopLocation}'),
          const SizedBox(height: 4),
          Text(formatTZS(live.priceTZS),
              style: Theme.of(context).textTheme.titleLarge),
          Text(live.stock > 0 ? '${live.stock} in stock' : 'Out of stock',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          _section(context, 'Description', Text(live.description)),
          _section(context, 'Ingredients',
              Text(live.ingredients.join(', '))),
          _section(
            context,
            'How to use',
            Text(live.usageInstructions),
          ),
          if (live.sideEffects.isNotEmpty)
            _section(
                context,
                'Possible side effects',
                _bullets(context, live.sideEffects)),
          if (live.warnings.isNotEmpty)
            _section(
              context,
              'Warnings — read before use',
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _bullets(context, live.warnings),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(live.stock > 0
                ? 'Add to cart — ${formatTZS(live.priceTZS)}'
                : 'Out of stock'),
            onPressed: live.stock > 0
                ? () {
                    final error = store.addToCart(live.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(error ?? '${live.name} added to cart'),
                    ));
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget body) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
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
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      );
}
