import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';

Future<void> _run(BuildContext context, Future<String?> action) async {
  final error = await action;
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error)));
  }
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
          title: const Text('Administration'),
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
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final u in users)
          if (u.role != UserRole.admin)
            ListTile(
              title: Text(u.name),
              subtitle: Text('${u.email} · ${u.phone}'),
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
                    onPressed: () =>
                        _run(context, store.setUserActive(u.id, u.deactivated)),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
