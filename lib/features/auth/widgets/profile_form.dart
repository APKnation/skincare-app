import 'package:flutter/material.dart';

import '../../../data/store.dart';

class ProfileFormDialog extends StatefulWidget {
  final Store store;

  const ProfileFormDialog({super.key, required this.store});

  @override
  State<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<ProfileFormDialog> {
  late final _name = TextEditingController(text: widget.store.currentUser?.name);
  late final _email = TextEditingController(text: widget.store.currentUser?.email);
  late final _phone = TextEditingController(text: widget.store.currentUser?.phone);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 8),
          TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone')),
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
            final error = await widget.store.updateProfile(
                name: _name.text, email: _email.text, phone: _phone.text);
            if (!mounted) return;
            if (error == null) {
              Navigator.of(this.context).pop();
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
