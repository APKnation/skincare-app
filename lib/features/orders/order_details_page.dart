import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../widgets/customer_support_icon.dart';
import '../../widgets/interactive_button.dart';
import '../../widgets/magnetic_button.dart';
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
        final me = store.currentUser;
        final canPay = me?.role == UserRole.customer &&
            o.paymentMethod.isMobileMoney &&
            o.paymentStatus != PaymentStatus.paid &&
            o.status != OrderStatus.cancelled &&
            o.status != OrderStatus.delivered;
        final canCancel = (me?.role == UserRole.customer) &&
            (o.status == OrderStatus.placed ||
                o.status == OrderStatus.confirmed);
        final isSeller = me?.role == UserRole.seller;
        final isAdmin = me?.role == UserRole.admin;
        return Scaffold(
          appBar: AppBar(title: Text('Order ${o.id}')),
          floatingActionButton: const CustomerSupportIcon(),
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
                MagneticButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => PaymentSheet(
                      store: store,
                      order: o,
                      onFinished: (_) {},
                    ),
                  ),
                  child: InteractiveButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => PaymentSheet(
                        store: store,
                        order: o,
                        onFinished: (_) {},
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: null,
                        child: Text(
                            'Pay ${formatTZS(o.totalTZS)} with ${o.paymentMethod.label}'),
                      ),
                    ),
                  ),
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
              if (isSeller || isAdmin) ..._sellerActions(context, o, isAdmin),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _sellerActions(
      BuildContext context, Order o, bool isAdmin) {
    final actions = <Widget>[];
    const next = {
      OrderStatus.placed: OrderStatus.confirmed,
      OrderStatus.confirmed: OrderStatus.onTheWay,
      OrderStatus.onTheWay: OrderStatus.delivered,
    };
    if (next.containsKey(o.status)) {
      actions.add(FilledButton.tonal(
        onPressed: () async {
          final target = next[o.status]!;
          final error = await store.updateOrderStatus(o.id, target.name,
              note: 'Status updated');
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error ?? 'Order marked ${target.label}')));
        },
        child: Text('Mark ${next[o.status]!.label}'),
      ));
      actions.add(const SizedBox(height: 8));
    }
    if (isAdmin &&
        (o.status == OrderStatus.placed ||
            o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.onTheWay)) {
      actions.add(OutlinedButton(
        onPressed: () async {
          final error = await store.updateOrderStatus(o.id, 'cancelled',
              note: 'Cancelled by marketplace');
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error ?? 'Order cancelled')));
        },
        child: const Text('Cancel order'),
      ));
    }
    return actions;
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
