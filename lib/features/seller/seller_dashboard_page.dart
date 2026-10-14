import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/product.dart';
import '../../models/user.dart';
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
      builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(me.shopName ?? 'My shop')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductFormPage(store: widget.store))),
        icon: const Icon(Icons.add),
        label: const Text('New product'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final p in products)
            Card(
              child: ListTile(
                title: Text(p.name),
                subtitle:
                    Text('${formatTZS(p.priceTZS)} · stock ${p.stock}'),
                trailing: _approvalChip(p.approval),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProductFormPage(
                        store: widget.store, existing: p))),
              ),
            ),
        ],
      ),
      ),
    );
  }

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
