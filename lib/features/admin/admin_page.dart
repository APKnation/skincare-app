import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../seller/product_form_page.dart';

Future<void> _run(BuildContext context, Future<String?> action) async {
  final error = await action;
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error)));
  }
}

Future<bool> _confirm(
    BuildContext context, String title, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete')),
      ],
    ),
  );
  return ok ?? false;
}

class AdminPage extends StatelessWidget {
  final Store store;

  const AdminPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    if (store.currentUser?.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administration')),
        body: const Center(
          child: Text('Restricted area — administrators only.'),
        ),
      );
    }
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.shield, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Administration'),
                    Text('Approve, manage and moderate the marketplace',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
            ),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Sellers'),
                Tab(text: 'Products'),
                Tab(text: 'Orders'),
                Tab(text: 'Users'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _SellersTab(store: store),
              _ProductsTab(store: store),
              _OrdersTab(store: store),
              _UsersTab(store: store),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellersTab extends StatelessWidget {
  final Store store;

  const _SellersTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final sellers = store.sellers;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final s in sellers)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.shopName ?? s.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('${s.name} · ${s.phone}'),
                  if (s.shopLocation != null) Text(s.shopLocation!),
                  if (s.shopDescription != null)
                    Text(s.shopDescription!,
                        style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(_sellerStatusLabel(s.sellerStatus)),
                      const Spacer(),
                      if (s.sellerStatus == SellerStatus.pending) ...[
                        FilledButton.tonal(
                          onPressed: () => _run(context,
                              store.setSellerStatus(s.id, 'approved')),
                          child: const Text('Approve'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _run(context,
                              store.setSellerStatus(s.id, 'rejected')),
                          child: const Text('Reject'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _sellerStatusLabel(SellerStatus s) => switch (s) {
        SellerStatus.none => 'Not applied',
        SellerStatus.pending => 'Pending review',
        SellerStatus.approved => 'Approved',
        SellerStatus.rejected => 'Rejected',
      };
}

class _ProductsTab extends StatelessWidget {
  final Store store;

  const _ProductsTab({required this.store});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Pending review'),
              Tab(text: 'All products'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PendingProductsList(store: store),
                _AllProductsList(store: store),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingProductsList extends StatelessWidget {
  final Store store;

  const _PendingProductsList({required this.store});

  @override
  Widget build(BuildContext context) {
    final pending = store.pendingProducts;
    if (pending.isEmpty) {
      return const Center(child: Text('No products awaiting review.'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final p in pending)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                  Text('${p.shopName} · ${formatTZS(p.priceTZS)}'),
                  Text('Ingredients: ${p.ingredients.join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text('Usage: ${p.usageInstructions}',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (p.warnings.isNotEmpty)
                    Text('Warnings: ${p.warnings.join(' ')}',
                        style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: () =>
                            _run(context, store.reviewProduct(p.id, 'approved')),
                        child: const Text('Approve'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () =>
                            _run(context, store.reviewProduct(p.id, 'rejected')),
                        child: const Text('Reject'),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  ProductFormPage(store: store, existing: p)),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final yes = await _confirm(context, 'Delete product',
                              'Remove "${p.name}" from the marketplace?');
                          if (!yes || !context.mounted) return;
                          await _run(context, store.deleteProduct(p.id));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AllProductsList extends StatelessWidget {
  final Store store;

  const _AllProductsList({required this.store});

  @override
  Widget build(BuildContext context) {
    final products = store.allProducts;
    if (products.isEmpty) {
      return const Center(child: Text('No products yet.'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final p in products)
          ListTile(
            contentPadding: const EdgeInsets.only(right: 8),
            title: Text(p.name),
            subtitle: Text(
                '${p.shopName} · ${formatTZS(p.priceTZS)} · stock ${p.stock}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _approvalChip(context, p.approval),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            ProductFormPage(store: store, existing: p)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: () async {
                    final yes = await _confirm(context, 'Delete product',
                        'Remove "${p.name}" from the marketplace?');
                    if (!yes || !context.mounted) return;
                    await _run(context, store.deleteProduct(p.id));
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _approvalChip(BuildContext context, ProductApproval approval) =>
      switch (approval) {
        ProductApproval.approved =>
          const Chip(label: Text('Live'), visualDensity: VisualDensity.compact),
        ProductApproval.pending =>
          const Chip(label: Text('Pending'), visualDensity: VisualDensity.compact),
        ProductApproval.rejected => Chip(
            label: const Text('Rejected'),
            visualDensity: VisualDensity.compact,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
      };
}

class _OrdersTab extends StatelessWidget {
  final Store store;

  const _OrdersTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final orders = store.allOrders;
    if (orders.isEmpty) {
      return const Center(child: Text('No orders yet.'));
    }
    const next = {
      OrderStatus.placed: OrderStatus.confirmed,
      OrderStatus.confirmed: OrderStatus.onTheWay,
      OrderStatus.onTheWay: OrderStatus.delivered,
    };
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final o in orders)
          Card(
            child: ExpansionTile(
              title: Text('Order ${o.id} · ${formatTZS(o.totalTZS)}'),
              subtitle: Text(
                  '${o.recipientName} — ${o.city} · ${o.status.label} · ${o.paymentStatus.label}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete order',
                onPressed: () async {
                  final yes = await _confirm(
                      context,
                      'Delete order',
                      'Permanently remove order ${o.id}? '
                          'This erases its history.');
                  if (!yes || !context.mounted) return;
                  await _run(context, store.adminDeleteOrder(o.id));
                },
              ),
              children: [
                for (final l in o.lines)
                  ListTile(
                      dense: true,
                      title: Text('${l.quantity} × ${l.name}'),
                      trailing: Text(formatTZS(l.total))),
                ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text('${o.address}, ${o.city}')),
                ListTile(
                    dense: true,
                    leading: const Icon(Icons.phone_outlined),
                    title: Text(o.recipientPhone)),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      if (next.containsKey(o.status))
                        FilledButton.tonal(
                          onPressed: () => _run(
                              context,
                              store.advanceOrder(o.id, next[o.status]!.name,
                                  'Status updated by marketplace')),
                          child: Text('Mark ${next[o.status]!.label}'),
                        ),
                      const Spacer(),
                      if (o.status == OrderStatus.placed ||
                          o.status == OrderStatus.confirmed)
                        OutlinedButton(
                          onPressed: () => _run(
                              context,
                              store.advanceOrder(o.id, 'cancelled',
                                  'Cancelled by marketplace')),
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _UsersTab extends StatelessWidget {
  final Store store;

  const _UsersTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final users = [...store.managedUsers]
      ..sort((a, b) => a.name.compareTo(b.name));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add user'),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _UserFormDialog(store: store),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final u in users)
                ListTile(
                  title: Text(u.name),
                  subtitle: Text(
                      '${u.email} · ${u.phone} · ${u.role.name}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(u.deactivated ? 'Blocked' : 'Active',
                          style: TextStyle(
                              color: u.deactivated
                                  ? Theme.of(context).colorScheme.error
                                  : null)),
                      IconButton(
                        icon: Icon(u.deactivated
                            ? Icons.lock_open
                            : Icons.block_outlined),
                        onPressed: () => _run(
                            context,
                            store.setUserActive(u.id, u.deactivated)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) =>
                              _UserFormDialog(store: store, existing: u),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () async {
                          final yes = await _confirm(
                              context,
                              'Delete user',
                              'Delete ${u.name} (${u.email})? Their products '
                                  'and order history are removed too.');
                          if (!yes || !context.mounted) return;
                          await _run(
                              context, store.adminDeleteUser(u.id));
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final Store store;
  final User? existing;

  const _UserFormDialog({required this.store, this.existing});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  late final _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _email =
      TextEditingController(text: widget.existing?.email ?? '');
  late final _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  final _password = TextEditingController();
  late String _role = widget.existing?.role.name ?? 'customer';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final error = widget.existing == null
        ? await widget.store.adminCreateUser(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            password: _password.text,
            role: _role,
          )
        : await widget.store.adminUpdateUser(
            widget.existing!.id,
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            role: _role,
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add user' : 'Edit user'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name')),
            TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone')),
            if (widget.existing == null)
              TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Temporary password')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                DropdownMenuItem(value: 'seller', child: Text('Seller')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'customer'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
