import 'package:flutter/material.dart';

import '../../data/store.dart';

class AdminPage extends StatelessWidget {
  final Store store;

  const AdminPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: const Center(child: Text('Admin tools coming in next step')),
    );
  }
}
