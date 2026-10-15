import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../../widgets/advanced_card.dart';

class SellerFinancePage extends StatelessWidget {
  final Store store;

  const SellerFinancePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _view(context),
    );
  }

  Widget _view(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final products = store.myProducts;
    final sales = store.salesOrders;

    // Revenue calculations
    final paidOrders =
        sales.where((o) => o.paymentStatus == PaymentStatus.paid).toList();
    final unpaidOrders =
        sales.where((o) => o.paymentStatus != PaymentStatus.paid).toList();
    final totalRevenue =
        paidOrders.fold<int>(0, (sum, o) => sum + o.subtotalTZS);
    final pendingRevenue =
        unpaidOrders.fold<int>(0, (sum, o) => sum + o.subtotalTZS);
    final deliveredRevenue = paidOrders
        .where((o) => o.status == OrderStatus.delivered)
        .fold<int>(0, (sum, o) => sum + o.subtotalTZS);

    // Order stats
    final totalOrders = sales.length;
    final deliveredOrders =
        sales.where((o) => o.status == OrderStatus.delivered).length;
    final cancelledOrders =
        sales.where((o) => o.status == OrderStatus.cancelled).length;
    final activeOrders = totalOrders - deliveredOrders - cancelledOrders;

    // Estimated costs (mock: platform fee 5%, delivery avg 5000/order)
    const platformFeePercent = 0.05;
    final platformFee = (totalRevenue * platformFeePercent).round();
    final estimatedDeliveryCost = deliveredOrders * 5000;
    final netProfit = totalRevenue - platformFee - estimatedDeliveryCost;

    // Product performance
    final liveProducts =
        products.where((p) => p.approval.name == 'approved').length;
    final totalStock = products.fold<int>(0, (a, p) => a + p.stock);

    // Month-over-month (split by current calendar month vs previous)
    final now = DateTime.now();
    final thisMonthOrders = paidOrders
        .where((o) =>
            o.timeline.isNotEmpty &&
            o.timeline.first.at.month == now.month &&
            o.timeline.first.at.year == now.year)
        .toList();
    final lastMonthOrders = paidOrders
        .where((o) =>
            o.timeline.isNotEmpty &&
            o.timeline.first.at.month == (now.month == 1 ? 12 : now.month - 1))
        .toList();
    final thisMonthRevenue =
        thisMonthOrders.fold<int>(0, (sum, o) => sum + o.subtotalTZS);
    final lastMonthRevenue =
        lastMonthOrders.fold<int>(0, (sum, o) => sum + o.subtotalTZS);
    final monthGrowth = lastMonthRevenue == 0
        ? (thisMonthRevenue > 0 ? 100.0 : 0.0)
        : ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue * 100);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finance & Reports'),
            Text('Profit, loss & revenue summary',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh data',
            onPressed: () => store.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => store.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 90),
          children: [
            // ─── Net Profit Hero ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: netProfit >= 0
                      ? [const Color(0xFF0D5C3A), const Color(0xFF2E9E6B)]
                      : [const Color(0xFF7B1C1C), const Color(0xFFB71C1C)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (netProfit >= 0
                            ? const Color(0xFF0D5C3A)
                            : Colors.red.shade900)
                        .withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        netProfit >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Estimated Net Profit',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          monthGrowth >= 0
                              ? '+${monthGrowth.toStringAsFixed(1)}% MoM'
                              : '${monthGrowth.toStringAsFixed(1)}% MoM',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatTZS(netProfit),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _heroStat('Revenue', formatTZS(totalRevenue)),
                      _divider(),
                      _heroStat('Platform Fee', '−${formatTZS(platformFee)}'),
                      _divider(),
                      _heroStat(
                          'Delivery Est.', '−${formatTZS(estimatedDeliveryCost)}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Revenue Breakdown ────────────────────────────────────────
            Text('Revenue Breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: [
                _kpiCard(context, 'Total Revenue', formatTZS(totalRevenue),
                    Icons.payments_outlined, Colors.green.shade700),
                const SizedBox(width: 8),
                _kpiCard(context, 'Settled', formatTZS(deliveredRevenue),
                    Icons.check_circle_outline, Colors.teal.shade700),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _kpiCard(context, 'Pending Collection', formatTZS(pendingRevenue),
                    Icons.pending_outlined, Colors.amber.shade800),
                const SizedBox(width: 8),
                _kpiCard(context, 'This Month', formatTZS(thisMonthRevenue),
                    Icons.calendar_month_outlined, Colors.blue.shade700),
              ],
            ),
            const SizedBox(height: 18),

            // ─── Cost Summary ─────────────────────────────────────────────
            Text('Cost Summary',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            AdvancedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _costRow(context, 'Platform Fee (5%)', formatTZS(platformFee),
                      Colors.orange.shade700, scheme),
                  const Divider(height: 20),
                  _costRow(
                      context,
                      'Est. Delivery Cost ($deliveredOrders fulfilled × TSh 5,000)',
                      formatTZS(estimatedDeliveryCost),
                      Colors.purple.shade700,
                      scheme),
                  const Divider(height: 20),
                  _costRow(
                    context,
                    'Total Estimated Costs',
                    formatTZS(platformFee + estimatedDeliveryCost),
                    Colors.red.shade700,
                    scheme,
                    bold: true,
                  ),
                  const Divider(height: 20),
                  _costRow(
                    context,
                    'Net Profit',
                    formatTZS(netProfit),
                    netProfit >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    scheme,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ─── Orders Performance ────────────────────────────────────────
            Text('Orders Performance',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: [
                _kpiCard(context, 'Total Orders', '$totalOrders',
                    Icons.local_shipping_outlined, Colors.indigo.shade700),
                const SizedBox(width: 8),
                _kpiCard(context, 'Delivered', '$deliveredOrders',
                    Icons.check_circle_outline, Colors.green.shade700),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _kpiCard(context, 'Active / In Progress', '$activeOrders',
                    Icons.autorenew_outlined, Colors.blue.shade700),
                const SizedBox(width: 8),
                _kpiCard(context, 'Cancelled', '$cancelledOrders',
                    Icons.cancel_outlined, Colors.red.shade700),
              ],
            ),
            const SizedBox(height: 18),

            // ─── Inventory Summary ─────────────────────────────────────────
            Text('Inventory Summary',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: [
                _kpiCard(context, 'Total Products', '${products.length}',
                    Icons.inventory_2_outlined, Colors.blue.shade800),
                const SizedBox(width: 8),
                _kpiCard(context, 'Live in Shop', '$liveProducts',
                    Icons.storefront_outlined, Colors.green.shade700),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _kpiCard(context, 'Total Stock Units', '$totalStock',
                    Icons.warehouse_outlined, Colors.teal.shade700),
                const SizedBox(width: 8),
                _kpiCard(
                    context,
                    'Avg Price',
                    products.isEmpty
                        ? 'N/A'
                        : formatTZS(products.fold<int>(
                                0, (a, p) => a + p.priceTZS) ~/
                            products.length),
                    Icons.price_change_outlined,
                    Colors.amber.shade800),
              ],
            ),
            const SizedBox(height: 18),

            // ─── Disclaimer ────────────────────────────────────────────────
            AdvancedCard(
              backgroundColor:
                  scheme.surfaceContainerLow,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cost figures are estimates. Platform fee (5%) and delivery costs '
                      'may vary. Final settlement values are determined by Sura Yangu '
                      'administration at payout time.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Colors.white24,
      );

  Widget _kpiCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Expanded(
      child: AdvancedCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _costRow(BuildContext context, String label, String value, Color color,
      ColorScheme scheme,
      {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold
                  ? Theme.of(context).colorScheme.onSurface
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 14 : 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
