import 'package:flutter/material.dart';

import '../../data/store.dart';

class CartPage extends StatelessWidget {
  final Store store;

  const CartPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: const Center(child: Text('Cart coming in next step')),
    );
  }
}
