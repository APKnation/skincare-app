import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/user.dart';
import '../admin/admin_page.dart';
import '../seller/seller_dashboard_page.dart';
import 'widgets/profile_form.dart';

class ProfilePage extends StatelessWidget {
  final Store store;

  const ProfilePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final me = store.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          me.name.isNotEmpty ? me.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(me.name,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(me.email),
                            Text(me.phone),
                          ],
                        ),
                      ),
                      _roleChip(me),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit profile'),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => ProfileFormDialog(store: store),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Change password'),
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
          ),
          const SizedBox(height: 8),
          if (me.role == UserRole.seller ||
              me.sellerStatus != SellerStatus.none)
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: Text(me.shopName ?? 'My shop'),
              subtitle: Text(_sellerStatusLabel(me.sellerStatus)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => SellerDashboardPage(store: store)),
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: const Text('Become a seller'),
              subtitle: const Text('Apply to sell your products here'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        SellerDashboardPage(store: store)),
              ),
            ),
          if (me.role == UserRole.admin)
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Administration'),
              subtitle: const Text(
                  'Approve sellers, review products, manage users and orders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AdminPage(store: store)),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: store.logout,
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

  Widget _roleChip(User me) => Chip(
        label: Text(me.role.name),
        visualDensity: VisualDensity.compact,
      );
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
          onPressed: () {
            final error =
                widget.store.changePassword(_current.text, _next.text);
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
