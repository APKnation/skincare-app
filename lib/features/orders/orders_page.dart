import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import 'order_details_page.dart';

class OrdersPage extends StatelessWidget {
  final Store store;

  const OrdersPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final orders = store.myOrders;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Orders'),
            Text('Track every purchase, start to delivery',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primaryContainer),
                  const SizedBox(height: 12),
                  Text('No orders yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Orders you place will appear here with live status.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final o = orders[i];
                return Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailsPage(store: store, orderId: o.id))),
                    title: Text('Order ${o.id}'),
                    subtitle: Text(
                        '${formatDateTime(o.timeline.first.at)} · ${o.totalItems} item(s)'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatTZS(o.totalTZS)),
                        const SizedBox(height: 4),
                        _statusChip(o),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _statusChip(Order o) => Chip(
        visualDensity: VisualDensity.compact,
        label: Text(o.status.label, style: const TextStyle(fontSize: 11)),
        backgroundColor: switch (o.status) {
          OrderStatus.delivered => Colors.green.shade100,
          OrderStatus.cancelled => Colors.red.shade100,
          _ => Colors.amber.shade100,
        },
      );
}
