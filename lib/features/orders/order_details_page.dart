import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../cart/payment_sheet.dart';

class OrderDetailsPage extends StatelessWidget {
  final Store store;
  final String orderId;

  const OrderDetailsPage({
    super.key,
    required this.store,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final o = store.orderById(orderId);
        if (o == null) {
          return const Scaffold(body: Center(child: Text('Order not found.')));
        }
        final canPay = o.paymentMethod.isMobileMoney &&
            o.paymentStatus != PaymentStatus.paid &&
            o.status != OrderStatus.cancelled &&
            o.status != OrderStatus.delivered;
        final canCancel = o.status == OrderStatus.placed ||
            o.status == OrderStatus.confirmed;
        return Scaffold(
          appBar: AppBar(title: Text('Order ${o.id}')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Chip(label: Text(o.status.label)),
                  const SizedBox(width: 8),
                  Chip(label: Text(o.paymentStatus.label)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              for (final l in o.lines)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.name),
                  subtitle: Text('${l.quantity} × ${formatTZS(l.unitPriceTZS)}'),
                  trailing: Text(formatTZS(l.total)),
                ),
              const Divider(),
              _row(context, 'Subtotal', formatTZS(o.subtotalTZS)),
              _row(context, 'Delivery', formatTZS(o.deliveryFeeTZS)),
              _row(context, 'Total', formatTZS(o.totalTZS), bold: true),
              const SizedBox(height: 16),
              Text('Delivery', style: Theme.of(context).textTheme.titleMedium),
              Text('${o.recipientName} · ${o.recipientPhone}'),
              Text('${o.address}, ${o.city}'),
              if (o.deliveryNotes.isNotEmpty) Text('Notes: ${o.deliveryNotes}'),
              const SizedBox(height: 16),
              Text('Payment', style: Theme.of(context).textTheme.titleMedium),
              Text(o.paymentMethod.label),
              if (o.paymentRef != null)
                Text('Ref: ${o.paymentRef}',
                    style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
              for (final e in o.timeline)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.circle, size: 12),
                  title: Text(e.note),
                  subtitle: Text(formatDateTime(e.at)),
                ),
              const SizedBox(height: 12),
              if (canPay)
                FilledButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => PaymentSheet(
                      store: store,
                      order: o,
                      onFinished: (_) {},
                    ),
                  ),
                  child: Text(
                      'Pay ${formatTZS(o.totalTZS)} with ${o.paymentMethod.label}'),
                ),
              if (canCancel)
                OutlinedButton(
                  onPressed: () async {
                    final error = await store.cancelOrder(o.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(error ?? 'Order cancelled.')));
                  },
                  child: const Text('Cancel order'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, String a, String b, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a,
                style: bold
                    ? Theme.of(context).textTheme.titleMedium
                    : null),
            Text(b,
                style: bold
                    ? Theme.of(context).textTheme.titleMedium
                    : null),
          ],
        ),
      );
}
