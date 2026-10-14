import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/enums.dart';
import '../../models/product.dart';
import '../../widgets/product_image.dart';
import 'product_details_page.dart';

class ComparePage extends StatelessWidget {
  final Store store;
  final List<Product> products;

  const ComparePage({super.key, required this.store, required this.products});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String Function(Product))>[
      ('Price', (p) => formatTZS(p.priceTZS)),
      ('Category', (p) => p.category.label),
      ('Shop', (p) => p.shopName),
      ('Location', (p) => p.shopLocation),
      ('Good for', (p) => p.suitableSkinTypes.map((t) => t.label).join(', ')),
      ('Targets', (p) => p.targetsConcerns.isEmpty
          ? '—'
          : p.targetsConcerns.map((c) => c.label).join(', ')),
      ('Ingredients', (p) => p.ingredients.join(', ')),
      ('Usage', (p) => p.usageInstructions),
      ('Warnings', (p) => p.warnings.join(' ')),
      ('Stock', (p) => '${p.stock}'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text('Compare (${products.length})')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('')),
            for (final p in products)
              DataColumn(
                label: SizedBox(
                  width: 150,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailsPage(store: store, product: p)),
                    ),
                    child: Column(
                      children: [
                        ProductImage(product: p, height: 80),
                        const SizedBox(height: 4),
                        Text(p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          rows: [
            for (final (label, getter) in rows)
              DataRow(cells: [
                DataCell(SizedBox(
                    width: 110,
                    child: Text(label,
                        style: const TextStyle(fontWeight: FontWeight.bold)))),
                for (final p in products)
                  DataCell(SizedBox(
                      width: 150, child: Text(getter(p), maxLines: 6, overflow: TextOverflow.ellipsis))),
              ]),
          ],
        ),
      ),
    );
  }
}
