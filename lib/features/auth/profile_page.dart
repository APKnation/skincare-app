import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/user.dart';
import '../../widgets/advanced_card.dart';
import '../admin/admin_page.dart';
import '../seller/seller_dashboard_page.dart';
import 'widgets/profile_form.dart';

class ProfilePage extends StatelessWidget {
  final Store store;

  const ProfilePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _view(context),
    );
  }

  Widget _view(BuildContext context) {
    final me = store.currentUser!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Profile'),
            Text('Account, shop access and security',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
        children: [
          // User Card
          AdvancedCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        me.name.isNotEmpty ? me.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  me.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _roleChip(me),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(me.email,
                              style: TextStyle(
                                  fontSize: 12, color: scheme.onSurfaceVariant)),
                          Text(me.phone,
                              style: TextStyle(
                                  fontSize: 12, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit profile',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => ProfileFormDialog(store: store),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('Change password',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _PasswordDialog(store: store),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Portal navigation items
          if (me.role == UserRole.seller ||
              me.sellerStatus != SellerStatus.none)
            AdvancedCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => SellerDashboardPage(store: store)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.storefront_outlined,
                      color: Colors.green.shade800),
                ),
                title: Text(me.shopName ?? 'My shop',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_sellerStatusLabel(me.sellerStatus)),
                trailing: const Icon(Icons.chevron_right),
              ),
            )
          else
            AdvancedCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => SellerDashboardPage(store: store)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sell_outlined, color: scheme.primary),
                ),
                title: const Text('Become a seller',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Apply to sell your products on Sura Yangu'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),

          if (me.role == UserRole.admin)
            AdvancedCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AdminPage(store: store)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shield_outlined,
                      color: Colors.indigo.shade800),
                ),
                title: const Text('Administration Console',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text(
                    'Approve sellers, review products, manage platform'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),

          // Logout
          AdvancedCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onTap: store.logout,
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout),
              title: Text('Log out', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.chevron_right),
            ),
          ),

          if (me.role != UserRole.admin)
            AdvancedCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete account?'),
                    content: const Text(
                        'This cannot be undone. All of your data will be '
                        'removed from the marketplace.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor:
                                  Theme.of(ctx).colorScheme.error),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete forever')),
                    ],
                  ),
                );
                if (yes != true) return;
                final error = await store.deleteMyAccount();
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)));
                }
              },
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.person_off_outlined,
                    color: Theme.of(context).colorScheme.error),
                title: Text('Delete account',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                subtitle: const Text(
                    'Permanently removes your profile, products, cart and orders'),
              ),
            ),
        ],
      ),
    );
  }

  static String _sellerStatusLabel(SellerStatus s) => switch (s) {
        SellerStatus.none => '',
        SellerStatus.pending => 'Application under review',
        SellerStatus.approved => 'Approved seller',
        SellerStatus.rejected => 'Application rejected',
      };

  Widget _roleChip(User me) {
    final (label, color, bg) = switch (me.role) {
      UserRole.admin => (
          'Admin',
          Colors.indigo.shade800,
          Colors.indigo.shade50
        ),
      UserRole.seller => (
          'Seller',
          Colors.green.shade800,
          Colors.green.shade50
        ),
      UserRole.customer => (
          'Customer',
          Colors.teal.shade800,
          Colors.teal.shade50
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
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

class _PasswordDialog extends StatefulWidget {
  final Store store;

  const _PasswordDialog({required this.store});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _current,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _next,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final error = await widget.store
                .changePassword(_current.text, _next.text);
            if (!context.mounted) return;
            if (error == null) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed.')));
            } else {
              setState(() => _error = error);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
