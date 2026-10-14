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
      appBar: AppBar(title: const Text('My orders')),
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet.'))
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
