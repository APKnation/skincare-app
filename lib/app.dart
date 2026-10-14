import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/api_client.dart';
import 'data/store.dart';
import 'features/admin/admin_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/profile_page.dart';
import 'features/cart/cart_page.dart';
import 'features/catalog/catalog_page.dart';
import 'features/orders/orders_page.dart';
import 'features/seller/seller_dashboard_page.dart';
import 'features/skin/for_you_page.dart';
import 'models/user.dart';

class SuraYanguApp extends StatefulWidget {
  const SuraYanguApp({super.key});

  @override
  State<SuraYanguApp> createState() => _SuraYanguAppState();
}

class _SuraYanguAppState extends State<SuraYanguApp> {
  final store = Store(ApiClient());

  @override
  void initState() {
    super.initState();
    store.bootstrap();
  }

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
        builder: (context, _) {
          if (!store.isBootstrapped) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return store.isLoggedIn
              ? RootShell(key: ValueKey(store.currentUser!.id), store: store)
              : LoginScreen(store: store);
        },
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
  late final List<Widget> _pages;
  late final List<NavigationDestination> _destinations;
  late final int _initialIndex;

  @override
  void initState() {
    super.initState();
    final me = widget.store.currentUser!;
    _pages = [
      CatalogPage(store: widget.store),
      ForYouPage(store: widget.store),
      CartPage(store: widget.store),
      OrdersPage(store: widget.store),
      ProfilePage(store: widget.store),
    ];
    _destinations = [
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
    ];
    if (me.role == UserRole.admin) {
      _pages.add(AdminPage(store: widget.store));
      _destinations.add(const NavigationDestination(
          icon: Icon(Icons.shield_outlined), label: 'Admin'));
    }
    if (me.role == UserRole.seller || me.sellerStatus != SellerStatus.none) {
      _pages.add(SellerDashboardPage(store: widget.store));
      _destinations.add(const NavigationDestination(
          icon: Icon(Icons.store_outlined), label: 'My Shop'));
    }
    // Role-based landing: admins open on Admin, sellers on their shop,
    // customers on Browse.
    _initialIndex = switch (me.role) {
      UserRole.admin || UserRole.seller => _pages.length - 1,
      UserRole.customer => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _destinations,
      ),
    );
  }

  int get _index => _currentIndex ?? _initialIndex;
  int? _currentIndex;
}
