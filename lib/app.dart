import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/store.dart';
import 'features/auth/login_page.dart';
import 'features/auth/profile_page.dart';
import 'features/cart/cart_page.dart';
import 'features/catalog/catalog_page.dart';
import 'features/orders/orders_page.dart';
import 'features/skin/for_you_page.dart';

class SuraYanguApp extends StatefulWidget {
  const SuraYanguApp({super.key});

  @override
  State<SuraYanguApp> createState() => _SuraYanguAppState();
}

class _SuraYanguAppState extends State<SuraYanguApp> {
  final store = Store.seeded();

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sura Yangu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: ListenableBuilder(
        listenable: store,
        builder: (context, _) =>
            store.isLoggedIn ? RootShell(store: store) : LoginScreen(store: store),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  final Store store;

  const RootShell({super.key, required this.store});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      CatalogPage(store: widget.store),
      ForYouPage(store: widget.store),
      CartPage(store: widget.store),
      OrdersPage(store: widget.store),
      ProfilePage(store: widget.store),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.storefront_outlined), label: 'Browse'),
          const NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined), label: 'For You'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: widget.store.cartCount > 0,
              label: Text('${widget.store.cartCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
