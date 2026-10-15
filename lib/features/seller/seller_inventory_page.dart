import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/product.dart';
import '../../widgets/advanced_card.dart';
import '../../widgets/product_image.dart';
import 'product_form_page.dart';

class SellerInventoryPage extends StatefulWidget {
  final Store store;

  const SellerInventoryPage({super.key, required this.store});

  @override
  State<SellerInventoryPage> createState() => _SellerInventoryPageState();
}

class _SellerInventoryPageState extends State<SellerInventoryPage> {
  String _filter = 'all'; // all, live, pending, low_stock
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allProducts = widget.store.myProducts;

    final filtered = allProducts.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q);
        if (!match) return false;
      }
      return switch (_filter) {
        'live' => p.approval == ProductApproval.approved,
        'pending' => p.approval == ProductApproval.pending,
        'rejected' => p.approval == ProductApproval.rejected,
        'low_stock' => p.stock <= 3,
        _ => true,
      };
    }).toList();

    final liveCount =
        allProducts.where((p) => p.approval == ProductApproval.approved).length;
    final pendingCount =
        allProducts.where((p) => p.approval == ProductApproval.pending).length;
    final lowStockCount = allProducts.where((p) => p.stock <= 3).length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Inventory'),
            Text('Manage listings, stock levels & review status',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => widget.store.refreshMyProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ProductFormPage(store: widget.store)),
        ),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add Product'),
      ),
      body: RefreshIndicator(
        onRefresh: () => widget.store.refreshMyProducts(),
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search my products...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  _chip('All (${allProducts.length})', 'all'),
                  const SizedBox(width: 6),
                  _chip('Live ($liveCount)', 'live',
                      color: Colors.green.shade700),
                  const SizedBox(width: 6),
                  _chip('In Review ($pendingCount)', 'pending',
                      color: Colors.amber.shade800),
                  const SizedBox(width: 6),
                  _chip('Low Stock ($lowStockCount)', 'low_stock',
                      color: Colors.orange.shade800),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Products list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 56,
                              color: scheme.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No products match your search'
                                : 'No products in this category',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "Add Product" to create a new cosmetic listing.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        return _buildProductCard(context, p);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String key, {Color? color}) {
    final selected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = key),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? Colors.white : color,
      ),
      selectedColor: color ?? Theme.of(context).colorScheme.primary,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildProductCard(BuildContext context, Product p) {
    final scheme = Theme.of(context).colorScheme;

    return AdvancedCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProductFormPage(store: widget.store, existing: p)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: ProductImage(product: p, height: 72),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _approvalBadge(p.approval),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.brand} · ${p.category.name}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      formatTZS(p.priceTZS),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: scheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: p.stock <= 3
                            ? Colors.red.shade50
                            : scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Stock: ${p.stock}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: p.stock <= 3
                              ? Colors.red.shade800
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (v) async {
                        if (v == 'edit') {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ProductFormPage(
                                  store: widget.store, existing: p)));
                        } else if (v == 'delete') {
                          final yes = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete product?'),
                              content: Text('Remove "${p.name}" from your shop?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel')),
                                FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(ctx).colorScheme.error),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (yes == true) {
                            final err =
                                await widget.store.deleteProduct(p.id);
                            if (err != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(err)));
                            }
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _approvalBadge(ProductApproval a) {
    final (label, color, bg) = switch (a) {
      ProductApproval.approved => (
          'Live',
          Colors.green.shade800,
          Colors.green.shade50
        ),
      ProductApproval.rejected => (
          'Rejected',
          Colors.red.shade800,
          Colors.red.shade50
        ),
      ProductApproval.pending => (
          'In Review',
          Colors.amber.shade900,
          Colors.amber.shade50
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
