import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../widgets/product_image.dart';
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
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            children: [
              _shopCard(me),
              const SizedBox(height: 10),
              Row(
                children: [
                  _stat(context, 'Listings', '${products.length}'),
                  _stat(context, 'Live', '$live'),
                  _stat(context, 'In review', '$inReview'),
                  _stat(context, 'Stock units', '$stockUnits'),
                ],
              ),
              const SizedBox(height: 14),
              Text('Your products',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              if (products.isEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: const Text('No products yet'),
                    subtitle: const Text(
                        'Tap “New product” to list your first item — add a '
                        'photo, ingredients and usage so review passes '
                        'quickly.'),
                  ),
                ),
              for (final p in products)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: ProductImage(product: p, height: 52),
                      ),
                    ),
                    title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                              '${formatTZS(p.priceTZS)} · stock ${p.stock}'),
                        ),
                        _approvalChip(p.approval),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
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
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel')),
                                FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(ctx).colorScheme.error),
                                    onPressed: () => Navigator.of(ctx).pop(true),
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
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProductFormPage(
                            store: widget.store, existing: p))),
                  ),
                ),
            ],
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

  Widget _stat(BuildContext context, String label, String value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );

  Widget _shopCard(User me) => Card(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: 0.45),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.storefront,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.shopName ?? 'My shop',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          [
                            me.shopLocation,
                            me.contactInfo,
                          ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: const Text('Approved',
                        style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.green.shade100,
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
          ),
        );

  Widget _approvalChip(ProductApproval approval) =>
      switch (approval) {
        ProductApproval.approved => Chip(
            label: const Text('Live', style: TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.green.shade100),
        ProductApproval.rejected => Chip(
            label: const Text('Rejected', style: TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.red.shade100),
        ProductApproval.pending => Chip(
            label: const Text('In review', style: TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.amber.shade100),
      };

  Widget _statusBanner(SellerStatus status) => switch (status) {
        SellerStatus.pending => const Card(
            child: ListTile(
                leading: Icon(Icons.hourglass_top),
                title: Text('Application under review'),
                subtitle: Text('You will be able to list products once an administrator approves your shop.'))),
        SellerStatus.rejected => const Card(
            child: ListTile(
                leading: Icon(Icons.block),
                title: Text('Application rejected'),
                subtitle: Text('Contact support for reasons and resubmit with complete information.'))),
        _ => const SizedBox.shrink(),
      };
}
