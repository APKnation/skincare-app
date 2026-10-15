import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/transitions.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../../widgets/advanced_card.dart';
import '../orders/order_details_page.dart';

class SellerOrdersPage extends StatefulWidget {
  final Store store;

  const SellerOrdersPage({super.key, required this.store});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allSales = widget.store.salesOrders;

    final filtered = allSales.where((o) {
      if (_statusFilter == 'all') return true;
      return o.status.name == _statusFilter;
    }).toList();

    final pendingCount = allSales
        .where((o) =>
            o.status == OrderStatus.placed || o.status == OrderStatus.confirmed)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sales & Orders'),
            Text('Orders containing items from your shop',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh orders',
            onPressed: () => widget.store.refreshSalesOrders(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => widget.store.refreshSalesOrders(),
        child: Column(
          children: [
            // Status Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  _chip('All (${allSales.length})', 'all'),
                  const SizedBox(width: 6),
                  _chip('Pending Action ($pendingCount)', 'placed',
                      color: Colors.amber.shade900),
                  const SizedBox(width: 6),
                  _chip('Confirmed', 'confirmed',
                      color: Colors.blue.shade800),
                  const SizedBox(width: 6),
                  _chip('In Transit', 'onTheWay',
                      color: Colors.purple.shade800),
                  const SizedBox(width: 6),
                  _chip('Delivered', 'delivered',
                      color: Colors.green.shade800),
                ],
              ),
            ),

            // Orders list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 56,
                              color: scheme.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            allSales.isEmpty
                                ? 'No customer orders yet'
                                : 'No orders in this status',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'When customers order your live items, they appear here.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final o = filtered[i];
                        return _buildOrderCard(context, o);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String key, {Color? color}) {
    final selected = _statusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = key),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? Colors.white : color,
      ),
      selectedColor: color ?? Theme.of(context).colorScheme.primary,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildOrderCard(BuildContext context, Order o) {
    final scheme = Theme.of(context).colorScheme;

    return AdvancedCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(SmoothPageRoute(
          page: OrderDetailsPage(store: widget.store, orderId: o.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
                child: Icon(Icons.person_outline,
                    size: 20, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.recipientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${o.recipientPhone} · ${o.city}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(o.status),
            ],
          ),
          const SizedBox(height: 12),

          // Details row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${o.totalItems} item(s)',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(
                  o.paymentStatus == PaymentStatus.paid
                      ? Icons.check_circle_outline
                      : Icons.pending_outlined,
                  size: 14,
                  color: o.paymentStatus == PaymentStatus.paid
                      ? Colors.green.shade700
                      : Colors.amber.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  '${o.paymentMethod.name.toUpperCase()} · ${o.paymentStatus.label}',
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

          // Footer
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Value',
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
                onPressed: () => Navigator.of(context).push(SmoothPageRoute(
                    page: OrderDetailsPage(store: widget.store, orderId: o.id))),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('Fulfill Order',
                    style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(OrderStatus s) {
    final (label, color, bg) = switch (s) {
      OrderStatus.delivered => (
          'Delivered',
          Colors.green.shade800,
          Colors.green.shade50
        ),
      OrderStatus.cancelled => (
          'Cancelled',
          Colors.red.shade800,
          Colors.red.shade50
        ),
      OrderStatus.onTheWay => (
          'In Transit',
          Colors.purple.shade800,
          Colors.purple.shade50
        ),
      OrderStatus.confirmed => (
          'Confirmed',
          Colors.blue.shade800,
          Colors.blue.shade50
        ),
      _ => (
          'Pending',
          Colors.amber.shade900,
          Colors.amber.shade50
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
