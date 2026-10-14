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
import 'widgets/app_logo.dart';

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
            return const _SplashScreen();
          }
          return store.isLoggedIn
              ? RootShell(key: ValueKey(store.currentUser!.id), store: store)
              : LoginScreen(store: store);
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surfaceContainerLowest,
              scheme.primaryContainer.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 88),
              const SizedBox(height: 20),
              Text('Sura Yangu',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary)),
              const SizedBox(height: 6),
              Text('Tanzania\'s trusted beauty market',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
              const SizedBox(height: 28),
              const SizedBox(
                  width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ],
          ),
        ),
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
  late final int _initialIndex;
  int? _currentIndex;

  int get _index => _currentIndex ?? _initialIndex;

  @override
  void initState() {
    super.initState();
    final me = widget.store.currentUser!;
    _pages = [
      CatalogPage(store: widget.store),
      ForYouPage(store: widget.store),
      CartPage(store: widget.store),
      OrdersPage(store: widget.store),
    ];
    if (me.role == UserRole.admin) {
      _pages.add(AdminPage(store: widget.store));
    }
    if (me.role == UserRole.seller || me.sellerStatus != SellerStatus.none) {
      _pages.add(SellerDashboardPage(store: widget.store));
    }
    // Role-based landing: admins open on Admin, sellers on their shop,
    // customers on Browse. Computed before Profile is appended last.
    _initialIndex = switch (me.role) {
      UserRole.admin || UserRole.seller => _pages.length - 1,
      UserRole.customer => 0,
    };
    _pages.add(ProfilePage(store: widget.store));
  }

  List<NavigationDestination> _destinationsFor(User me) {
    final cartCount = widget.store.cartCount;
    Widget bag(bool filled) => Badge(
          isLabelVisible: cartCount > 0,
          backgroundColor: Theme.of(context).colorScheme.error,
          label: Text('$cartCount',
              style: const TextStyle(fontSize: 10, color: Colors.white)),
          child: Icon(filled ? Icons.shopping_bag : Icons.shopping_bag_outlined),
        );
    return [
      const NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront),
        label: 'Shop',
      ),
      const NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome),
        label: 'For You',
      ),
      NavigationDestination(icon: bag(false), selectedIcon: bag(true), label: 'Cart'),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Orders',
      ),
      if (me.role == UserRole.admin)
        const NavigationDestination(
          icon: Icon(Icons.shield_outlined),
          selectedIcon: Icon(Icons.shield),
          label: 'Admin',
        ),
      if (me.role == UserRole.seller || me.sellerStatus != SellerStatus.none)
        const NavigationDestination(
          icon: Icon(Icons.store_outlined),
          selectedIcon: Icon(Icons.store),
          label: 'My Shop',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.store.currentUser!;
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: _destinationsFor(me),
        ),
      ),
    );
  }
}
