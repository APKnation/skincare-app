import 'package:flutter/material.dart';

import '../../data/store.dart';

class SellerDashboardPage extends StatelessWidget {
  final Store store;

  const SellerDashboardPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My shop')),
      body: const Center(child: Text('Seller tools coming in next step')),
    );
  }
}
