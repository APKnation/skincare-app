import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/store.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../widgets/advanced_card.dart';
import '../../widgets/product_image.dart';
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

/// Admin Overview / Command Center
class AdminOverviewPage extends StatelessWidget {
  final Store store;

  const AdminOverviewPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final pendingSellers =
            store.sellers.where((s) => s.sellerStatus == SellerStatus.pending).length;
        final pendingProducts = store.pendingProducts.length;
        final allOrders = store.allOrders;
        final totalGmv = allOrders.fold<int>(0, (a, o) => a + o.totalTZS);
        final users = store.managedUsers;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.shield, color: scheme.primary),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Platform Console'),
                    Text('Executive overview & system approvals',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh platform data',
                onPressed: () => store.refreshAdmin(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => store.refreshAdmin(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
              children: [
                // Top Executive Banner
                AdvancedCard(
                  backgroundColor: scheme.primaryContainer.withValues(alpha: 0.35),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: scheme.primary,
                        child: const Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sura Yangu Operations',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            Text(
                              'Marketplace compliance, KYC & cosmetic safety',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Urgent Action Cards
                Row(
                  children: [
                    Expanded(
                      child: AdvancedCard(
                        backgroundColor: pendingSellers > 0
                            ? Colors.amber.shade50
                            : scheme.surface,
                        borderColor: pendingSellers > 0
                            ? Colors.amber.shade400
                            : null,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.verified_user_outlined,
                                    size: 18, color: Colors.amber.shade900),
                                const Spacer(),
                                if (pendingSellers > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade800,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$pendingSellers',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$pendingSellers',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: pendingSellers > 0
                                    ? Colors.amber.shade900
                                    : scheme.onSurface,
                              ),
                            ),
                            const Text(
                              'Pending Sellers',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AdvancedCard(
                        backgroundColor: pendingProducts > 0
                            ? Colors.orange.shade50
                            : scheme.surface,
                        borderColor: pendingProducts > 0
                            ? Colors.orange.shade400
                            : null,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.fact_check_outlined,
                                    size: 18, color: Colors.orange.shade900),
                                const Spacer(),
                                if (pendingProducts > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade800,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$pendingProducts',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$pendingProducts',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: pendingProducts > 0
                                    ? Colors.orange.shade900
                                    : scheme.onSurface,
                              ),
                            ),
                            const Text(
                              'Pending Products',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Platform Stats Row
                Row(
                  children: [
                    Expanded(
                      child: AdvancedCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.payments_outlined,
                                size: 18, color: scheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              formatTZS(totalGmv),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            const Text(
                              'Platform GMV',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AdvancedCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.people_outline,
                                size: 18, color: Colors.indigo.shade700),
                            const SizedBox(height: 8),
                            Text(
                              '${users.length}',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            const Text(
                              'Total Users',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Quick Action Bar
                Text('Quick Management',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => _UserFormDialog(store: store),
                        ),
                        icon: const Icon(Icons.person_add_alt, size: 16),
                        label: const Text('Add User',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ProductFormPage(store: store)),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_outlined,
                            size: 16),
                        label: const Text('Add Product',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Pending Seller Verification Previews
                if (pendingSellers > 0) ...[
                  Row(
                    children: [
                      Text('Sellers Awaiting Approval',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$pendingSellers pending',
                          style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final s in store.sellers
                      .where((s) => s.sellerStatus == SellerStatus.pending)
                      .take(3))
                    AdvancedCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.amber.shade100,
                                child: Icon(Icons.storefront,
                                    size: 16, color: Colors.amber.shade900),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.shopName ?? s.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5),
                                    ),
                                    Text(
                                      '${s.name} · ${s.phone}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (s.shopLocation != null) ...[
                            const SizedBox(height: 4),
                            Text('📍 ${s.shopLocation!}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant)),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _run(context,
                                    store.setSellerStatus(s.id, 'approved')),
                                child: const Text('Approve Shop',
                                    style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _run(context,
                                    store.setSellerStatus(s.id, 'rejected')),
                                child: const Text('Reject',
                                    style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Admin Sellers KYC & Verification Page
class AdminSellersPage extends StatefulWidget {
  final Store store;

  const AdminSellersPage({super.key, required this.store});

  @override
  State<AdminSellersPage> createState() => _AdminSellersPageState();
}

class _AdminSellersPageState extends State<AdminSellersPage> {
  String _filter = 'pending'; // pending, approved, rejected, all
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sellers = widget.store.sellers;

    final filtered = sellers.where((s) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = (s.shopName ?? '').toLowerCase().contains(q) ||
            s.name.toLowerCase().contains(q) ||
            s.phone.toLowerCase().contains(q);
        if (!match) return false;
      }
      return switch (_filter) {
        'pending' => s.sellerStatus == SellerStatus.pending,
        'approved' => s.sellerStatus == SellerStatus.approved,
        'rejected' => s.sellerStatus == SellerStatus.rejected,
        _ => true,
      };
    }).toList();

    final pendingCount =
        sellers.where((s) => s.sellerStatus == SellerStatus.pending).length;
    final approvedCount =
        sellers.where((s) => s.sellerStatus == SellerStatus.approved).length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seller Applications'),
            Text('Verify business legitimacy & approve merchant shops',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh sellers',
            onPressed: () => widget.store.refreshAdmin(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => widget.store.refreshAdmin(),
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search seller or shop name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  _chip('Pending Review ($pendingCount)', 'pending',
                      color: Colors.amber.shade900),
                  const SizedBox(width: 6),
                  _chip('Approved ($approvedCount)', 'approved',
                      color: Colors.green.shade800),
                  const SizedBox(width: 6),
                  _chip('Rejected', 'rejected', color: Colors.red.shade800),
                  const SizedBox(width: 6),
                  _chip('All Sellers (${sellers.length})', 'all'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Sellers List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_outlined,
                              size: 56,
                              color: scheme.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'pending'
                                ? 'No pending seller applications!'
                                : 'No sellers match this filter',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text('All seller KYC reviews are up to date.',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = filtered[i];
                        return _buildSellerCard(context, s);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String key, {Color? color}) {
    final selected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = key),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? Colors.white : color,
      ),
      selectedColor: color ?? Theme.of(context).colorScheme.primary,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSellerCard(BuildContext context, User s) {
    final scheme = Theme.of(context).colorScheme;

    return AdvancedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    s.sellerStatus == SellerStatus.approved
                        ? Colors.green.shade50
                        : Colors.amber.shade50,
                child: Icon(
                  Icons.storefront,
                  size: 20,
                  color: s.sellerStatus == SellerStatus.approved
                      ? Colors.green.shade800
                      : Colors.amber.shade900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.shopName ?? s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      '${s.name} · ${s.phone}',
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _sellerStatusChip(s.sellerStatus),
            ],
          ),
          if (s.shopLocation != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    s.shopLocation!,
                    style: TextStyle(
                        fontSize: 11.5, color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
          if (s.shopDescription != null && s.shopDescription!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.shopDescription!,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (s.sellerStatus == SellerStatus.pending) ...[
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade900,
                  ),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Approve', style: TextStyle(fontSize: 11.5)),
                  onPressed: () => _run(
                      context, widget.store.setSellerStatus(s.id, 'approved')),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.red.shade800,
                  ),
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Reject', style: TextStyle(fontSize: 11.5)),
                  onPressed: () => _run(
                      context, widget.store.setSellerStatus(s.id, 'rejected')),
                ),
              ] else if (s.sellerStatus == SellerStatus.approved) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.red.shade800,
                  ),
                  icon: const Icon(Icons.block, size: 13),
                  label: const Text('Revoke Status',
                      style: TextStyle(fontSize: 11)),
                  onPressed: () => _run(
                      context, widget.store.setSellerStatus(s.id, 'rejected')),
                ),
              ] else if (s.sellerStatus == SellerStatus.rejected) ...[
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Re-approve',
                      style: TextStyle(fontSize: 11)),
                  onPressed: () => _run(
                      context, widget.store.setSellerStatus(s.id, 'approved')),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _sellerStatusChip(SellerStatus status) {
    final (label, color, bg) = switch (status) {
      SellerStatus.approved => (
          'Approved',
          Colors.green.shade800,
          Colors.green.shade50
        ),
      SellerStatus.rejected => (
          'Rejected',
          Colors.red.shade800,
          Colors.red.shade50
        ),
      SellerStatus.pending => (
          'Pending',
          Colors.amber.shade900,
          Colors.amber.shade50
        ),
      SellerStatus.none => (
          'None',
          Colors.grey.shade800,
          Colors.grey.shade100
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
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

/// Admin Product Moderation Page
class AdminModerationPage extends StatelessWidget {
  final Store store;

  const AdminModerationPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final pendingCount = store.pendingProducts.length;
    final allCount = store.allProducts.length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cosmetics Moderation'),
              Text('Review cosmetic safety claims, ingredients & labels',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: 'New product',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductFormPage(store: store)),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pending Safety Review'),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade800,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(text: 'All Catalog ($allCount)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PendingProductsList(store: store),
            _AllProductsList(store: store),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined,
                size: 56, color: scheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('No products awaiting review!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text('All cosmetics listings are compliant with safety rules.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
      itemCount: pending.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = pending[i];
        return AdvancedCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: ProductImage(product: p, height: 64),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('${p.brand} · ${p.shopName}',
                            style: TextStyle(
                                fontSize: 11.5, color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 3),
                        Text(formatTZS(p.priceTZS),
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: scheme.primary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Ingredients box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ingredients: ${p.ingredients.join(', ')}',
                        style: const TextStyle(fontSize: 11.5)),
                    if (p.usageInstructions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Usage: ${p.usageInstructions}',
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant)),
                    ],
                    if (p.warnings.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('⚠️ Warnings: ${p.warnings.join(' ')}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.amber.shade900)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green.shade900,
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Approve & Publish',
                        style: TextStyle(fontSize: 11.5)),
                    onPressed: () =>
                        _run(context, store.reviewProduct(p.id, 'approved')),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: Colors.red.shade800,
                    ),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Reject', style: TextStyle(fontSize: 11.5)),
                    onPressed: () =>
                        _run(context, store.reviewProduct(p.id, 'rejected')),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit details',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              ProductFormPage(store: store, existing: p)),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete product',
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
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
        );
      },
    );
  }
}

class _AllProductsList extends StatelessWidget {
  final Store store;

  const _AllProductsList({required this.store});

  @override
  Widget build(BuildContext context) {
    final products = store.allProducts;
    final scheme = Theme.of(context).colorScheme;

    if (products.isEmpty) {
      return const Center(child: Text('No products in catalog yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = products[i];
        return AdvancedCard(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ProductImage(product: p, height: 48),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('${p.shopName} · ${formatTZS(p.priceTZS)} · stock ${p.stock}',
                        style: TextStyle(
                            fontSize: 11, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              _approvalChip(context, p.approval),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (v) async {
                  if (v == 'edit') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              ProductFormPage(store: store, existing: p)),
                    );
                  } else if (v == 'delete') {
                    final yes = await _confirm(context, 'Delete product',
                        'Remove "${p.name}" from the marketplace?');
                    if (!yes || !context.mounted) return;
                    await _run(context, store.deleteProduct(p.id));
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                          dense: true,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'))),
                  PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                          dense: true,
                          leading: Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Delete',
                              style: TextStyle(color: Colors.red)))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _approvalChip(BuildContext context, ProductApproval approval) =>
      switch (approval) {
        ProductApproval.approved => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Text('Live',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800))),
        ProductApproval.pending => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Text('Pending',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900))),
        ProductApproval.rejected => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Text('Rejected',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade800))),
      };
}

/// Admin Platform Operations (Orders & Users) Page
class AdminPlatformOpsPage extends StatelessWidget {
  final Store store;

  const AdminPlatformOpsPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Platform Operations'),
              Text('Order fulfillment pipeline & user access management',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Orders'),
              Tab(text: 'Managed Users'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrdersTab(store: store),
            _UsersTab(store: store),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final Store store;

  const _OrdersTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final orders = store.allOrders;
    const next = {
      OrderStatus.placed: OrderStatus.confirmed,
      OrderStatus.confirmed: OrderStatus.onTheWay,
      OrderStatus.onTheWay: OrderStatus.delivered,
    };
    return RefreshIndicator(
      onRefresh: () => store.refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
        children: [
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(
                  child: Text('No orders yet — pull down to refresh.')),
            ),
          for (final o in orders)
            AdvancedCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text('Order #${o.id.substring(0, o.id.length > 8 ? 8 : o.id.length)} · ${formatTZS(o.totalTZS)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: Text(
                    '${o.recipientName} (${o.city}) · ${o.status.label} · ${o.paymentStatus.label}',
                    style: const TextStyle(fontSize: 11.5)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'Delete order',
                  onPressed: () async {
                    final yes = await _confirm(
                        context, 'Delete order', 'Remove order ${o.id}?');
                    if (!yes || !context.mounted) return;
                    await _run(context, store.adminDeleteOrder(o.id));
                  },
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Text('Customer: ${o.recipientName} (${o.recipientPhone})',
                            style: const TextStyle(fontSize: 12)),
                        Text('Address: ${o.address}, ${o.city}',
                            style: const TextStyle(fontSize: 12)),
                        if (o.deliveryNotes.isNotEmpty)
                          Text('Notes: ${o.deliveryNotes}',
                              style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                        for (final item in o.lines)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text('${item.quantity}× ${item.name}',
                                    style: const TextStyle(fontSize: 12)),
                                const Spacer(),
                                Text(formatTZS(item.unitPriceTZS * item.quantity),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (next[o.status] != null)
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _run(
                                    context,
                                    store.advanceOrder(
                                        o.id,
                                        next[o.status]!.name,
                                        'Advanced by admin')),
                                child: Text('Advance to ${next[o.status]!.label}',
                                    style: const TextStyle(fontSize: 11)),
                              ),
                            const Spacer(),
                            if (o.status != OrderStatus.cancelled &&
                                o.status != OrderStatus.delivered)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: Colors.red.shade800,
                                ),
                                onPressed: () => _run(
                                    context,
                                    store.advanceOrder(
                                        o.id,
                                        OrderStatus.cancelled.name,
                                        'Cancelled by admin')),
                                child: const Text('Cancel Order',
                                    style: TextStyle(fontSize: 11)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  final Store store;

  const _UsersTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final users = store.managedUsers;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.person_add_alt, size: 16),
                label: const Text('Add User', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _UserFormDialog(store: store),
                ),
              ),
              const Spacer(),
              Text('${users.length} registered accounts',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final u = users[i];
              return AdvancedCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: u.deactivated
                          ? Colors.red.shade50
                          : scheme.primaryContainer.withValues(alpha: 0.5),
                      child: Icon(
                        u.role == UserRole.admin
                            ? Icons.shield
                            : (u.role == UserRole.seller
                                ? Icons.storefront
                                : Icons.person),
                        size: 18,
                        color: u.deactivated
                            ? Colors.red.shade800
                            : scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(u.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  u.role.name.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 9, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          Text('${u.email} · ${u.phone}',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        u.deactivated ? Icons.lock_open : Icons.block_outlined,
                        size: 20,
                        color: u.deactivated ? Colors.green : Colors.orange.shade800,
                      ),
                      tooltip: u.deactivated ? 'Activate' : 'Block',
                      onPressed: () => _run(
                          context, store.setUserActive(u.id, u.deactivated)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit',
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) =>
                            _UserFormDialog(store: store, existing: u),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () async {
                        final yes = await _confirm(
                            context,
                            'Delete user',
                            'Delete ${u.name} (${u.email})? Products and orders will be removed.');
                        if (!yes || !context.mounted) return;
                        await _run(context, store.adminDeleteUser(u.id));
                      },
                    ),
                  ],
                ),
              );
            },
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

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    String? err;
    if (widget.existing == null) {
      if (_password.text.isEmpty) {
        setState(() {
          _busy = false;
          _error = 'Password is required for new users.';
        });
        return;
      }
      err = await widget.store.adminCreateUser(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        role: _role,
      );
    } else {
      err = await widget.store.adminUpdateUser(
        widget.existing!.id,
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        role: _role,
      );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add User' : 'Edit User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12)),
              ),
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 10),
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 10),
            if (widget.existing == null)
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            const SizedBox(height: 10),
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
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}

/// Backward compatibility container
class AdminPage extends StatelessWidget {
  final Store store;

  const AdminPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) => AdminOverviewPage(store: store);
}
