import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/transitions.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../../widgets/advanced_card.dart';
import '../../widgets/customer_support_icon.dart';
import 'order_details_page.dart';

class OrdersPage extends StatelessWidget {
  final Store store;

  const OrdersPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _view(context),
    );
  }

  Widget _view(BuildContext context) {
    final orders = store.myOrders;
    final scheme = Theme.of(context).colorScheme;

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
      floatingActionButton: const CustomerSupportIcon(),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.receipt_long_outlined,
                        size: 56, color: scheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('No orders yet',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Orders you place will appear here with live tracking.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => store.refreshOrders(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final o = orders[i];
                  return AdvancedCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => Navigator.of(context).push(SmoothPageRoute(
                        page: OrderDetailsPage(store: store, orderId: o.id))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Order ID & Status Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order #${o.id.substring(0, o.id.length > 8 ? 8 : o.id.length)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  Text(
                                    formatDateTime(o.timeline.first.at),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _statusBadge(o),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Middle Info: Items & Delivery destination
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shopping_bag_outlined,
                                  size: 14, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${o.totalItems} item(s)',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.location_on_outlined,
                                  size: 14, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  o.city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Text(
                                o.paymentStatus.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: o.paymentStatus == PaymentStatus.paid
                                      ? Colors.green.shade700
                                      : Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Footer: Total Price & Track Action
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  formatTZS(o.totalTZS),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            FilledButton.tonalIcon(
                              onPressed: () => Navigator.of(context).push(
                                  SmoothPageRoute(
                                      page: OrderDetailsPage(
                                          store: store, orderId: o.id))),
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              label: const Text('Track Order',
                                  style: TextStyle(fontSize: 12)),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _statusBadge(Order o) {
    final (label, icon, color, bg) = switch (o.status) {
      OrderStatus.delivered => (
          'Delivered',
          Icons.check_circle_rounded,
          Colors.green.shade800,
          Colors.green.shade50
        ),
      OrderStatus.cancelled => (
          'Cancelled',
          Icons.cancel_rounded,
          Colors.red.shade800,
          Colors.red.shade50
        ),
      OrderStatus.onTheWay => (
          'On The Way',
          Icons.local_shipping_rounded,
          Colors.blue.shade800,
          Colors.blue.shade50
        ),
      OrderStatus.confirmed => (
          'Confirmed',
          Icons.thumb_up_alt_rounded,
          Colors.indigo.shade800,
          Colors.indigo.shade50
        ),
      _ => (
          'Processing',
          Icons.schedule_rounded,
          Colors.amber.shade900,
          Colors.amber.shade50
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
