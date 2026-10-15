import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../widgets/advanced_card.dart';
import '../../widgets/product_image.dart';
import '../orders/order_details_page.dart';
import 'product_form_page.dart';

class SellerDashboardPage extends StatefulWidget {
  final Store store;

  const SellerDashboardPage({super.key, required this.store});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  final _shopName = TextEditingController();
  final _shopLocation = TextEditingController();
  final _shopDescription = TextEditingController();
  final _contact = TextEditingController();

  @override
  void initState() {
    super.initState();
    final me = widget.store.currentUser!;
    _shopName.text = me.shopName ?? '';
    _shopLocation.text = me.shopLocation ?? '';
    _shopDescription.text = me.shopDescription ?? '';
    _contact.text = me.contactInfo ?? '';
  }

  @override
  void dispose() {
    for (final c in [_shopName, _shopLocation, _shopDescription, _contact]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _apply() async {
    final error = await widget.store.applyForSeller(
      shopName: _shopName.text,
      shopLocation: _shopLocation.text,
      shopDescription: _shopDescription.text,
      contactInfo: _contact.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ??
          'Application submitted. An administrator will review your shop.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.store.currentUser!;
    if (me.sellerStatus != SellerStatus.approved) {
      return Scaffold(
        appBar: AppBar(title: const Text('Become a seller')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusBanner(me.sellerStatus),
            const SizedBox(height: 12),
            TextField(
                controller: _shopName,
                decoration: const InputDecoration(labelText: 'Shop name')),
            const SizedBox(height: 12),
            TextField(
                controller: _shopLocation,
                decoration: const InputDecoration(
                    labelText: 'Shop location (city – area/street)')),
            const SizedBox(height: 12),
            TextField(
                controller: _shopDescription,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'What do you sell?')),
            const SizedBox(height: 12),
            TextField(
                controller: _contact,
                decoration: const InputDecoration(
                    labelText: 'Customer contact (phone/WhatsApp/social)')),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: _apply, child: const Text('Submit application')),
            const SizedBox(height: 12),
            Text(
              'Approved sellers can list products. Every listing is reviewed '
              'by an administrator before customers see it, and product '
              'claims must include ingredients, usage and safety information.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    final products = widget.store.myProducts;
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final live = products
            .where((p) => p.approval == ProductApproval.approved)
            .length;
        final inReview = products
            .where((p) => p.approval == ProductApproval.pending)
            .length;
        final stockUnits =
            products.fold<int>(0, (a, p) => a + p.stock);
        final sales = widget.store.salesOrders;
        final totalSalesRevenue = sales.fold<int>(0, (a, o) => a + o.totalTZS);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(me.shopName ?? 'My shop'),
                const Text('Seller workspace — manage your listings',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.storefront_outlined),
                tooltip: 'Edit shop profile',
                onPressed: _editShopProfile,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProductFormPage(store: widget.store))),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('New product'),
          ),
          body: RefreshIndicator(
            onRefresh: () => widget.store.refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
              children: [
                _shopCard(me),
                const SizedBox(height: 14),

                // KPI Stat Cards Grid
                Row(
                  children: [
                    _kpiStat(
                      context,
                      'Total Listings',
                      '${products.length}',
                      Icons.inventory_2_outlined,
                      Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    _kpiStat(
                      context,
                      'Live in Shop',
                      '$live',
                      Icons.check_circle_outline,
                      Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    _kpiStat(
                      context,
                      'In Review',
                      '$inReview',
                      Icons.hourglass_top,
                      Colors.amber.shade800,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _kpiStat(
                      context,
                      'Stock Units',
                      '$stockUnits',
                      Icons.warehouse_outlined,
                      Colors.indigo.shade700,
                    ),
                    const SizedBox(width: 8),
                    _kpiStat(
                      context,
                      'Total Orders',
                      '${sales.length}',
                      Icons.local_shipping_outlined,
                      Colors.purple.shade700,
                    ),
                    const SizedBox(width: 8),
                    _kpiStat(
                      context,
                      'Revenue',
                      formatTZS(totalSalesRevenue),
                      Icons.payments_outlined,
                      Colors.teal.shade700,
                      isSmallText: true,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Recent Products Header
                Row(
                  children: [
                    Text('Your Products',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${products.length} total',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                if (products.isEmpty)
                  AdvancedCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No products yet',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                  'Tap "New product" to list your first item with photos and safety claims.',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final p in products.take(4))
                  AdvancedCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProductFormPage(
                            store: widget.store, existing: p))),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: ProductImage(product: p, height: 52),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5)),
                              Text(
                                '${formatTZS(p.priceTZS)} · stock ${p.stock}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        _approvalChip(p.approval),
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
                                  content: Text(
                                      '"${p.name}" will be removed from your shop '
                                      'and the marketplace.'),
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
                                final error =
                                    await widget.store.deleteProduct(p.id);
                                if (error != null && mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(content: Text(error)));
                                }
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                    dense: true,
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Edit'))),
                            PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                    dense: true,
                                    leading: Icon(Icons.delete_outline),
                                    title: Text('Delete'))),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),
                Row(
                  children: [
                    Text('Customer Orders',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${sales.length} orders',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                if (sales.isEmpty)
                  AdvancedCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('No orders yet',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                live == 0
                                    ? 'Get a product approved and live, and customer orders will appear here.'
                                    : 'Orders containing your live products will appear here for fulfilment.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final o in sales.take(5))
                  AdvancedCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => OrderDetailsPage(
                            store: widget.store, orderId: o.id))),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Icon(Icons.shopping_bag_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatTZS(o.totalTZS),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              Text(
                                '${o.totalItems} item(s) · ${o.recipientName} (${o.city})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(o.status.label,
                              style: const TextStyle(fontSize: 10.5)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editShopProfile() async {
    final me = widget.store.currentUser!;
    final shopName = TextEditingController(text: me.shopName ?? '');
    final location = TextEditingController(text: me.shopLocation ?? '');
    final description =
        TextEditingController(text: me.shopDescription ?? '');
    final contact = TextEditingController(text: me.contactInfo ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shop profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: shopName,
                  decoration: const InputDecoration(labelText: 'Shop name')),
              const SizedBox(height: 10),
              TextField(
                  controller: location,
                  decoration: const InputDecoration(
                      labelText: 'Location (city – area/street)')),
              const SizedBox(height: 10),
              TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'About your shop')),
              const SizedBox(height: 10),
              TextField(
                  controller: contact,
                  decoration: const InputDecoration(
                      labelText: 'Customer contact (phone/WhatsApp)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save')),
        ],
      ),
    );
    if (save != true) return;
    final error = await widget.store.updateShopProfile(
      shopName: shopName.text,
      shopLocation: location.text,
      shopDescription: description.text,
      contactInfo: contact.text,
    );
    for (final c in [shopName, location, description, contact]) {
      c.dispose();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Shop profile updated.')));
  }

  Widget _kpiStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isSmallText = false,
  }) =>
      Expanded(
        child: AdvancedCard(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSmallText ? 12.5 : 17,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _shopCard(User me) => AdvancedCard(
        backgroundColor: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.35),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.storefront,
                      size: 22,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              me.shopName ?? 'My shop',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        [
                          me.shopLocation,
                          me.contactInfo,
                        ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if ((me.shopDescription ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(me.shopDescription!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      );

  Widget _approvalChip(ProductApproval approval) =>
      switch (approval) {
        ProductApproval.approved => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Text('Live',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800))),
        ProductApproval.rejected => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Text('Rejected',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade800))),
        ProductApproval.pending => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Text('In review',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900))),
      };

  Widget _statusBanner(SellerStatus status) => switch (status) {
        SellerStatus.pending => const AdvancedCard(
            child: Row(
              children: [
                Icon(Icons.hourglass_top, color: Colors.amber),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Application under review',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          'You will be able to list products once an administrator approves your shop.',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        SellerStatus.rejected => const AdvancedCard(
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Application rejected',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          'Contact support for reasons and resubmit with complete information.',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        _ => const SizedBox.shrink(),
      };
}
