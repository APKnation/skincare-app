import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/enums.dart';
import '../models/product.dart';

class ProductImage extends StatelessWidget {
  final Product product;
  final double height;

  const ProductImage({super.key, required this.product, this.height = 140});

  IconData get _icon => switch (product.category) {
        ProductCategory.facialOil => Icons.water_drop_outlined,
        ProductCategory.bodyOil => Icons.spa_outlined,
        ProductCategory.serum => Icons.science_outlined,
        ProductCategory.moisturizer => Icons.bubble_chart_outlined,
        ProductCategory.cleanser => Icons.cleaning_services_outlined,
        ProductCategory.sunscreen => Icons.wb_sunny_outlined,
        ProductCategory.lipCare => Icons.favorite_outline,
        ProductCategory.hairCare => Icons.self_improvement,
        ProductCategory.makeup => Icons.brush_outlined,
        ProductCategory.other => Icons.local_offer_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final color =
        AppTheme.categoryColors[product.name.codeUnits.fold(0, (a, b) => a + b) % AppTheme.categoryColors.length];
    if (product.imageUrl != null) {
      return Image.network(
        product.imageUrl!,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(color),
      );
    }
    return _placeholder(color);
  }

  Widget _placeholder(Color color) => Container(
        height: height,
        color: color.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: Icon(_icon, size: height * 0.45, color: Colors.black54),
      );
}
