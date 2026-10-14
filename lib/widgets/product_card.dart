import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/product.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool selectedForCompare;
  final VoidCallback? onToggleCompare;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.selectedForCompare = false,
    this.onToggleCompare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: selectedForCompare
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 2))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ProductImage(product: product),
              if (onToggleCompare != null)
                Positioned(
                  right: 4,
                  top: 4,
                  child: FilterChip(
                    label: const Text('Compare',
                        style: TextStyle(fontSize: 11)),
                    selected: selectedForCompare,
                    onSelected: (_) => onToggleCompare!(),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (product.stock == 0)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black38,
                    child: const Center(
                      child: Text('Out of stock',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(product.shopName,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(formatTZS(product.priceTZS),
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
