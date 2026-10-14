import 'package:flutter/material.dart';

import '../../data/store.dart';

class OrdersPage extends StatelessWidget {
  final Store store;

  const OrdersPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: const Center(child: Text('Orders coming in next step')),
    );
  }
}
