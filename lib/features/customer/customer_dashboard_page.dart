import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/transitions.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../../widgets/advanced_card.dart';
import '../orders/order_details_page.dart';

class CustomerDashboardPage extends StatelessWidget {
  final Store store;
  final VoidCallback? onGoToShop;
  final VoidCallback? onGoToOrders;
  final VoidCallback? onGoToCart;

  const CustomerDashboardPage({
    super.key,
    required this.store,
    this.onGoToShop,
    this.onGoToOrders,
    this.onGoToCart,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _view(context),
    );
  }

  Widget _view(BuildContext context) {
    final me = store.currentUser!;
    final orders = store.myOrders;
    final cartCount = store.cartCount;
    final cartSubtotal = store.cartSubtotal;
    final scheme = Theme.of(context).colorScheme;

    final totalOrders = orders.length;
    final delivered =
        orders.where((o) => o.status == OrderStatus.delivered).length;
    final inProgress = orders
        .where((o) =>
            o.status == OrderStatus.placed ||
            o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.onTheWay)
        .length;
    final totalSpent = orders
        .where((o) => o.paymentStatus == PaymentStatus.paid)
        .fold<int>(0, (sum, o) => sum + o.totalTZS);

    final recentOrders = orders.take(3).toList();
    final greeting = _greeting();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => store.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D5C3A),
                        Color(0xFF1B7A52),
                        Color(0xFF2E9E6B),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  me.name.isNotEmpty
                                      ? me.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      greeting,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    Text(
                                      me.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (cartCount > 0)
                                GestureDetector(
                                  onTap: onGoToCart,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white30, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.shopping_bag_outlined,
                                            color: Colors.white,
                                            size: 15),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$cartCount item${cartCount > 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your skincare journey at a glance',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                'Dashboard',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 90),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (cartCount > 0) ...[
                    _cartBanner(context, cartCount, cartSubtotal, scheme),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      _statCard(context, 'Orders', '$totalOrders',
                          Icons.receipt_long_outlined, const Color(0xFF1565C0)),
                      const SizedBox(width: 8),
                      _statCard(context, 'Delivered', '$delivered',
                          Icons.check_circle_outline, const Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      _statCard(context, 'In Progress', '$inProgress',
                          Icons.local_shipping_outlined, const Color(0xFF6A1B9A)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AdvancedCard(
                    backgroundColor:
                        scheme.primaryContainer.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.payments_outlined,
                              color: scheme.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Spent on Orders',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                formatTZS(totalSpent),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _quickAction(context, Icons.storefront_outlined, 'Shop',
                          'Browse products', const Color(0xFF0D5C3A), onGoToShop),
                      const SizedBox(width: 8),
                      _quickAction(
                          context,
                          Icons.receipt_long_outlined,
                          'Orders',
                          'Track deliveries',
                          const Color(0xFF1565C0),
                          onGoToOrders),
                      const SizedBox(width: 8),
                      _quickAction(
                          context,
                          Icons.shopping_bag_outlined,
                          'Cart',
                          '$cartCount item${cartCount != 1 ? 's' : ''}',
                          const Color(0xFF6A1B9A),
                          onGoToCart),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Recent Orders',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      if (orders.length > 3)
                        TextButton(
                          onPressed: onGoToOrders,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('See all',
                              style: TextStyle(fontSize: 12.5)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (recentOrders.isEmpty)
                    AdvancedCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 44,
                              color: scheme.primary.withValues(alpha: 0.35)),
                          const SizedBox(height: 10),
                          const Text('No orders yet',
                              style:
                                  TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          const Text(
                            'Explore the shop to place your first order.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: onGoToShop,
                            icon: const Icon(Icons.storefront_outlined,
                                size: 16),
                            label: const Text('Browse Shop'),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final o in recentOrders) ...[
                      _recentOrderCard(context, o, scheme),
                      const SizedBox(height: 8),
                    ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartBanner(
      BuildContext context, int count, int subtotal, ColorScheme scheme) {
    return GestureDetector(
      onTap: onGoToCart,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0D5C3A), Color(0xFF2E9E6B)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D5C3A).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count item${count > 1 ? 's' : ''} in your cart',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14),
                  ),
                  Text(
                    'Subtotal: ${formatTZS(subtotal)} — Tap to checkout',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Expanded(
      child: AdvancedCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context,
    IconData icon,
    String label,
    String sub,
    Color color,
    VoidCallback? onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AdvancedCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 2),
              Text(sub,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentOrderCard(
      BuildContext context, Order o, ColorScheme scheme) {
    final (statusLabel, statusColor, statusBg) = switch (o.status) {
      OrderStatus.delivered => (
          'Delivered',
          Colors.green.shade800,
          Colors.green.shade50
        ),
      OrderStatus.onTheWay => (
          'On The Way',
          Colors.blue.shade800,
          Colors.blue.shade50
        ),
      OrderStatus.confirmed => (
          'Confirmed',
          Colors.indigo.shade800,
          Colors.indigo.shade50
        ),
      OrderStatus.cancelled => (
          'Cancelled',
          Colors.red.shade800,
          Colors.red.shade50
        ),
      _ => (
          'Processing',
          Colors.amber.shade900,
          Colors.amber.shade50
        ),
    };

    return AdvancedCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(SmoothPageRoute(
          page: OrderDetailsPage(store: store, orderId: o.id))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 20, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${o.id.substring(0, o.id.length > 8 ? 8 : o.id.length)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${o.totalItems} item(s) · ${formatTZS(o.totalTZS)}',
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}
